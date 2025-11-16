package com.goomar.service;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.DateTime;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.calendar.model.*;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class CalendarService implements ICalendarService {

    @Value("${goomar.calendarId}")
    private String calendarId;

    private final GoogleAuthorizationCodeFlow flow;
    private final ZoneId zone = ZoneId.of("Europe/Zagreb");

    private Calendar calendarClient;
    private Credential credential;

    @SneakyThrows
    private synchronized void ensureCalendarReady() {
        if (this.calendarClient == null || this.credential == null) {
            log.info("Initializing Google Calendar client...");
            this.credential = flow.loadCredential("user");
            if (this.credential == null) {
                throw new IllegalStateException("User must authorize first via OAuth flow!");
            }

            this.calendarClient = new Calendar.Builder(GoogleNetHttpTransport.newTrustedTransport(),JacksonFactory.getDefaultInstance(),credential).setApplicationName("Goomar App").build();

            log.info("✅ Google Calendar client initialized successfully.");
        }

        if (credential.getExpiresInSeconds() != null && credential.getExpiresInSeconds() < 60) {
            if (credential.refreshToken()) {
                log.info("🔄 Calendar access token refreshed successfully.");
            } else {
                log.warn("⚠️ Calendar token refresh failed. User reauthorization may be required.");
            }
        }
    }

    private <T> T executeWithRetry(java.util.concurrent.Callable<T> call) throws Exception {
        try {
            return call.call();
        } catch (GoogleJsonResponseException e) {
            if (e.getStatusCode() == 401) {
                log.warn("401 from Calendar API during {}. Attempting token refresh...");
                if (credential != null && credential.refreshToken()) {
                    return call.call();
                }
                log.warn("Refresh failed. Reloading credential and rebuilding client...");
                Credential reloaded = flow.loadCredential("user");
                if (reloaded != null) {
                    this.credential = reloaded;
                    this.calendarClient = new Calendar.Builder(GoogleNetHttpTransport.newTrustedTransport(),JacksonFactory.getDefaultInstance(),credential).setApplicationName("Goomar App").build();
                    return call.call();
                }
                throw new IllegalStateException("Google authorization expired. Please re-authorize via /google/auth");
            }
            throw e;
        }
    }

    @SneakyThrows
    @Override
    public String insertAppoitnment(ReservationRest rr) {
        ensureCalendarReady();

        log.info("insertReservation(rr={})", rr);

        ZonedDateTime startZoned = rr.getDateTime().atZone(zone);
        ZonedDateTime endZoned = startZoned.plusMinutes(rr.getLong() ? 30 : 15);

        Event event = new Event().setSummary(rr.getName()).setDescription(rr.getPhone()).setColorId("5").setStart(new EventDateTime().setDateTime(new DateTime(startZoned.toInstant().toEpochMilli()))
                        .setTimeZone(zone.getId())).setEnd(new EventDateTime().setDateTime(new DateTime(endZoned.toInstant().toEpochMilli())).setTimeZone(zone.getId()));

        Event created = executeWithRetry(() -> calendarClient.events().insert(calendarId, event).execute());
        log.info("📅 Event created: {} ({} at {})", created.getId(), created.getSummary(), created.getStart());
        return created.getId();
    }

    @SneakyThrows
    @Override
    public List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService) {
        ensureCalendarReady();

        log.info("getFreeSlots(date={}, longService={})", date, longService);
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(zone);
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(zone);

        DateTime tMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime tMax = new DateTime(endOfDay.toInstant().toEpochMilli());

        List<Event> events = executeWithRetry(() -> calendarClient.events().list(calendarId).setTimeMin(tMin).setTimeMax(tMax)
                .setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute()).getItems();

        List<TimePeriod> busyPeriods = new ArrayList<>();
        for (Event event : events) {
            if (event.getStart() == null || event.getEnd() == null) continue;
            if (event.getStart().getDate() != null || event.getEnd().getDate() != null) continue;

            ZonedDateTime start = Instant.ofEpochMilli(event.getStart().getDateTime().getValue()).atZone(zone);
            ZonedDateTime end = Instant.ofEpochMilli(event.getEnd().getDateTime().getValue()).atZone(zone);

            if (!start.toLocalDate().equals(end.toLocalDate())) continue;
            busyPeriods.add(new TimePeriod().setStart(event.getStart().getDateTime()).setEnd(event.getEnd().getDateTime()));
        }

        ZonedDateTime lStart = date.atTime(LocalTime.of(12, 0)).atZone(zone);
        ZonedDateTime lEnd = date.atTime(LocalTime.of(13, 0)).atZone(zone);
        busyPeriods.add(new TimePeriod().setStart(new DateTime(lStart.toInstant().toEpochMilli())).setEnd(new DateTime(lEnd.toInstant().toEpochMilli())));
        busyPeriods.sort(Comparator.comparingLong(tp -> tp.getStart().getValue()));

        List<FreeSlotRest> freeSlots = new ArrayList<>();
        Duration slotLength = Duration.ofMinutes(longService ? 30 : 15);
        ZonedDateTime cursor = startOfDay;

        for (TimePeriod busy : busyPeriods) {
            ZonedDateTime busyStart = Instant.ofEpochMilli(busy.getStart().getValue()).atZone(zone);
            ZonedDateTime busyEnd = Instant.ofEpochMilli(busy.getEnd().getValue()).atZone(zone);

            while (cursor.plus(slotLength).isBefore(busyStart)) {
                freeSlots.add(new FreeSlotRest().start(cursor.toLocalTime().toString()).end(cursor.plus(slotLength).toLocalTime().toString()));
                cursor = cursor.plus(slotLength);
            }
            if (cursor.isBefore(busyEnd)) cursor = busyEnd;
        }

        while (cursor.plus(slotLength).isBefore(endOfDay)) {
            freeSlots.add(new FreeSlotRest().start(cursor.toLocalTime().toString()).end(cursor.plus(slotLength).toLocalTime().toString()));
            cursor = cursor.plus(slotLength);
        }

        return freeSlots;
    }

    @SneakyThrows
    @Override
    public void confirmAppointment(String eventId) {
        ensureCalendarReady();
        log.info("confirmAppointment(eventId={})", eventId);
        Event event = executeWithRetry(() -> calendarClient.events().get(calendarId, eventId).execute());
        event.setStatus("confirmed").setColorId("10");
        executeWithRetry(() -> calendarClient.events().update(calendarId, event.getId(), event).execute());
    }

    @SneakyThrows
    @Override
    public void deleteAppointment(String eventId) {
        ensureCalendarReady();
        log.info("deleteAppointment(eventId={})", eventId);
        executeWithRetry(() -> calendarClient.events().delete(calendarId, eventId).execute());
    }
}
