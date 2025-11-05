package com.goomar.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
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
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import java.io.IOException;

import java.time.*;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CalendarService implements ICalendarService {
    @Value("${goomar.calendarId}")
    private String calendarId;
    private final GoogleAuthorizationCodeFlow flow;

    public Calendar getCalendarClient() throws Exception {
        var credential = flow.loadCredential("user");
        if (credential == null) {
            throw new IllegalStateException("User must authorize first!");
        }
        return new Calendar.Builder(
                GoogleNetHttpTransport.newTrustedTransport(),
                JacksonFactory.getDefaultInstance(),
                credential
        ).setApplicationName("Goomar App").build();
    }
    @Override
    @SneakyThrows
    public List<Event> getEventsForDay(LocalDate date) {
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());


        return getCalendarClient().events().list(calendarId).setTimeMin(timeMin).setTimeMax(timeMax).setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute().getItems();
    }

    @SneakyThrows
    @Override
    public String insertReservation(ReservationRest rr) {
        log.info("insertReservation(rr={})", rr);
        ZoneId zone = ZoneId.of("Europe/Zagreb");

        ZonedDateTime startZoned = rr.getDateTime().atZone(zone);
        ZonedDateTime endZoned = startZoned.plusMinutes(rr.getLongService() ? 30 : 15);

        Event event = new Event().setSummary(rr.getUsername()).setDescription(rr.getPhone()).setColorId("5").setStart(new EventDateTime().setDateTime(new DateTime(startZoned.toInstant().toEpochMilli()))
                .setTimeZone(zone.getId())).setEnd(new EventDateTime().setDateTime(new DateTime(endZoned.toInstant().toEpochMilli())).setTimeZone(zone.getId()));

        Event created = getCalendarClient().events().insert(calendarId, event).execute();

        log.info("Event created: {}: {}, {}", created.getId(), created.getSummary(), created.getStart());
        return created.getId();
    }

    @SneakyThrows
    @Override
    public List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService) {
        log.info("getFreeSlots(date={}, longService={})", date, longService);
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());

        List<Event> allEvents = null;
        try {
            allEvents = getCalendarClient().events().list(calendarId).setTimeMin(timeMin).setTimeMax(timeMax).setOrderBy("startTime")
                    .setShowDeleted(false).setSingleEvents(true).execute().getItems();
        } catch (IOException e) {
            log.error("Error getting events for day: {}", date, e);
            throw e;
        }


        log.info("fetched");
        List<TimePeriod> busyPeriods = new ArrayList<>();
        for (Event event : allEvents) {
            if (event.getStart() == null || event.getEnd() == null)
                continue;

            if (event.getStart().getDate() != null || event.getEnd().getDate() != null)
                continue;

            ZonedDateTime start = Instant.ofEpochMilli(event.getStart().getDateTime().getValue()).atZone(ZoneId.systemDefault());
            ZonedDateTime end = Instant.ofEpochMilli(event.getEnd().getDateTime().getValue()).atZone(ZoneId.systemDefault());

            if (!start.toLocalDate().equals(end.toLocalDate()))
                continue;

            busyPeriods.add(new TimePeriod().setStart(event.getStart().getDateTime()).setEnd(event.getEnd().getDateTime()));
        }

        ZonedDateTime lunchStart = date.atTime(LocalTime.of(12, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime lunchEnd = date.atTime(LocalTime.of(13, 0)).atZone(ZoneId.systemDefault());
        busyPeriods.add(new TimePeriod().setStart(new DateTime(lunchStart.toInstant().toEpochMilli())).setEnd(new DateTime(lunchEnd.toInstant().toEpochMilli())));

        busyPeriods.sort(Comparator.comparingLong(tp -> tp.getStart().getValue()));

        List<FreeSlotRest> freeSlots = new ArrayList<>();
        Duration slotLength = Duration.ofMinutes(longService ? 30 : 15);
        ZonedDateTime cursor = startOfDay;

        for (TimePeriod busy : busyPeriods) {
            ZonedDateTime busyStart = Instant.ofEpochMilli(busy.getStart().getValue()).atZone(ZoneId.systemDefault());
            ZonedDateTime busyEnd = Instant.ofEpochMilli(busy.getEnd().getValue()).atZone(ZoneId.systemDefault());

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
        log.info("confirmAppointment(eventId={})", eventId);
        Event event = getCalendarClient().events().get(calendarId, eventId).execute().setStatus("confirmed").setColorId("1");
        getCalendarClient().events().update(calendarId, event.getId(), event).execute();
    }

    @SneakyThrows
    @Override
    public void deleteAppointment(String eventId) {
        log.info("deleteAppointment(eventId={})", eventId);
        getCalendarClient().events().delete(calendarId, eventId).execute();
    }
}
