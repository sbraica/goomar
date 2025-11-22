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
    public String insertAppointment(ReservationRest rr) {
        ensureCalendarReady();

        log.info("insertAppointment(rr={})", rr);

        ZonedDateTime startZoned = rr.getDateTime().atZone(zone);
        ZonedDateTime endZoned = startZoned.plusMinutes(rr.getLong() ? 30 : 15);

        Event event = new Event().setSummary(rr.getName() + " " + rr.getPhone()).setColorId("5").setStart(new EventDateTime().setDateTime(new DateTime(startZoned.toInstant().toEpochMilli()))
                        .setTimeZone(zone.getId())).setEnd(new EventDateTime().setDateTime(new DateTime(endZoned.toInstant().toEpochMilli())).setTimeZone(zone.getId()));

        Event created = executeWithRetry(() -> calendarClient.events().insert(calendarId, event).execute());
        log.info("📅 Event created: {} ({} at {})", created.getId(), created.getSummary(), created.getStart());
        return created.getId();
    }

    @SneakyThrows
    @Override
    public boolean slotFree(LocalDateTime dateTime, boolean _long) {
        return getEvents(dateTime, dateTime.plus(Duration.ofMinutes(_long?30:15))).isEmpty();
    }

    @SneakyThrows
    @Override
    public List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService) {
        ensureCalendarReady();
        log.info("getFreeSlots(date={}, longService={})", date, longService);

        LocalDateTime startOfDay = date.atTime(8, 0);
        LocalDateTime endOfDay = date.atTime(16, 0);
        List<Event> events = getEvents(startOfDay, endOfDay);

        List<TimePeriod> busyPeriods = new ArrayList<>();
        for (Event event : events) {
            if (event.getStart() == null || event.getEnd() == null) continue;
            if (event.getStart().getDate() != null || event.getEnd().getDate() != null) continue;

            DateTime startDt = event.getStart().getDateTime();
            DateTime endDt = event.getEnd().getDateTime();
            if (startDt == null || endDt == null) continue;

            busyPeriods.add(new TimePeriod().setStart(startDt).setEnd(endDt));
        }

        ZonedDateTime lunchStart = date.atTime(12, 0).atZone(zone);
        ZonedDateTime lunchEnd = date.atTime(13, 0).atZone(zone);
        busyPeriods.add(new TimePeriod().setStart(new DateTime(lunchStart.toInstant().toEpochMilli())).setEnd(new DateTime(lunchEnd.toInstant().toEpochMilli())));

        busyPeriods.sort(Comparator.comparingLong(tp -> tp.getStart().getValue()));

        List<FreeSlotRest> freeSlots = new ArrayList<>();
        ZonedDateTime cursor = startOfDay.atZone(zone);
        Duration slotLength = Duration.ofMinutes(longService ? 30 : 15);
        ZonedDateTime zonedEndOfDay = endOfDay.atZone(zone);
        while (!cursor.plus(slotLength).isAfter(zonedEndOfDay)) {
            boolean result = true;
            ZonedDateTime slotEnd = cursor.plus(slotLength);

            for (TimePeriod busy : busyPeriods) {
                ZonedDateTime busyStart = Instant.ofEpochMilli(busy.getStart().getValue()).atZone(cursor.getZone());
                ZonedDateTime busyEnd = Instant.ofEpochMilli(busy.getEnd().getValue()).atZone(cursor.getZone());

                if (!slotEnd.isBefore(busyStart) && !cursor.isAfter(busyEnd)) {
                    result = false;
                    break;
                }
            }
            if (result) {
                freeSlots.add(new FreeSlotRest().start(cursor.toLocalTime().toString()).end(cursor.plus(slotLength).toLocalTime().toString()));
            }
            cursor = cursor.plus(slotLength);
        }
        return freeSlots;
    }

    private List<Event> getEvents(LocalDateTime startOfDay, LocalDateTime endOfDay) throws Exception {
        DateTime tMin = new DateTime(startOfDay.atZone(zone).toInstant().toEpochMilli());
        DateTime tMax = new DateTime(endOfDay.atZone(zone).toInstant().toEpochMilli());

        List<Event> events = executeWithRetry(() ->calendarClient.events().list(calendarId).setTimeMin(tMin).setTimeMax(tMax)
                .setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute()).getItems();
        return events;
    }

    @SneakyThrows
    @Override
    public void confirmAppointment(String eventId) {
        ensureCalendarReady();
        log.info("confirmAppointment(eventId={})", eventId);
        Event event = executeWithRetry(() -> calendarClient.events().get(calendarId, eventId).execute());
        log.info("Event: {}", event);
        event.setColorId("10");
        executeWithRetry(() -> calendarClient.events().update(calendarId, event.getId(), event).execute());
    }

    @Override
    public void deleteAppointment(String eventId) {
        ensureCalendarReady();
        log.info("deleteAppointment(eventId={})", eventId);
        try {
            executeWithRetry(() -> calendarClient.events().delete(calendarId, eventId).execute());
        } catch (Exception e) {
            log.warn("Failed to delete event {}: {}", eventId, e.getMessage());
        }
    }
}
