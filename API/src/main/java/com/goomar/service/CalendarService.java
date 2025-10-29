package com.goomar.service;

import com.google.api.client.util.DateTime;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.calendar.model.*;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.FreeSlotRest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CalendarService implements ICalendarService {
    private final Calendar calendar;
    @Value("${goomar.calendarId}")
    private String calendarId;

    @Override
    @SneakyThrows
    public List<Event> getEventsForDay(LocalDate date) {
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());


        return calendar.events().list(calendarId).setTimeMin(timeMin).setTimeMax(timeMax).setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute().getItems();
    }

    @SneakyThrows
    @Override
    public List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService) {
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());

        List<Event> allEvents = calendar.events()
                .list(calendarId)
                .setTimeMin(timeMin)
                .setTimeMax(timeMax)
                .setOrderBy("startTime")
                .setShowDeleted(false)
                .setSingleEvents(true)
                .execute()
                .getItems();

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

            busyPeriods.add(new TimePeriod()
                    .setStart(event.getStart().getDateTime())
                    .setEnd(event.getEnd().getDateTime()));
        }

        ZonedDateTime lunchStart = date.atTime(LocalTime.of(12, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime lunchEnd = date.atTime(LocalTime.of(13, 0)).atZone(ZoneId.systemDefault());
        busyPeriods.add(new TimePeriod()
                .setStart(new DateTime(lunchStart.toInstant().toEpochMilli()))
                .setEnd(new DateTime(lunchEnd.toInstant().toEpochMilli())));

        // Ensure busy periods are processed in chronological order
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

}

