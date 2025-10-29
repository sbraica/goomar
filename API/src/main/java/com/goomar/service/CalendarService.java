package com.goomar.service;

import com.google.api.client.util.DateTime;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.calendar.model.*;
import com.goomar.controller.AppointmentController;
import com.goomar.model.TimeSlot;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CalendarService implements ICalendarService {
    private final Calendar calendar;

    @Override
    @SneakyThrows
    public List<Event> getEventsForDay(LocalDate date) {
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());


        return calendar.events().list("bosnic.hr_40bdhhqhdsohai2kj57amf1k2s@group.calendar.google.com").setTimeMin(timeMin).setTimeMax(timeMax).setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute().getItems();
    }
    @SneakyThrows
    @Override
    public List<TimeSlot> getFreeSlots(LocalDate date, boolean longService) {
        ZonedDateTime startOfDay = date.atTime(LocalTime.of(8, 0)).atZone(ZoneId.systemDefault());
        ZonedDateTime endOfDay = date.atTime(LocalTime.of(16, 0)).atZone(ZoneId.systemDefault());

        DateTime timeMin = new DateTime(startOfDay.toInstant().toEpochMilli());
        DateTime timeMax = new DateTime(endOfDay.toInstant().toEpochMilli());

        List<Event> allEvents = calendar.events().list("bosnic.hr_40bdhhqhdsohai2kj57amf1k2s@group.calendar.google.com").setTimeMin(timeMin).setTimeMax(timeMax).setOrderBy("startTime").setShowDeleted(false).setSingleEvents(true).execute().getItems();

        List<TimePeriod> busyPeriods = new ArrayList<>();
        for (Event event : allEvents) {
            if (event.getStart() == null || event.getEnd() == null)
                continue;

            // Skip all-day events (these use .getDate instead of .getDateTime)
            if (event.getStart().getDate() != null || event.getEnd().getDate() != null)
                continue;

            // Extract start and end as ZonedDateTime
            ZonedDateTime start = Instant.ofEpochMilli(event.getStart().getDateTime().getValue()).atZone(ZoneId.systemDefault());
            ZonedDateTime end = Instant.ofEpochMilli(event.getEnd().getDateTime().getValue()).atZone(ZoneId.systemDefault());

            // Skip multi-day events (start and end dates differ)
            if (!start.toLocalDate().equals(end.toLocalDate()))
                continue;
            busyPeriods.add(new TimePeriod().setStart(event.getStart().getDateTime()).setEnd(event.getEnd().getDateTime()));
            log.info("Added busy period: {} - {}", event.getStart().getDateTime(), event.getEnd().getDateTime());
        }


        List<TimeSlot> freeSlots = new ArrayList<>();
        Duration slotLength = Duration.ofMinutes(longService?30:15);
        ZonedDateTime cursor = startOfDay;

        for (TimePeriod busy : busyPeriods) {
            ZonedDateTime busyStart = Instant.ofEpochMilli(busy.getStart().getValue()).atZone(ZoneId.systemDefault());
            ZonedDateTime busyEnd = Instant.ofEpochMilli(busy.getEnd().getValue()).atZone(ZoneId.systemDefault());

            while (cursor.plus(slotLength).isBefore(busyStart)) {
                freeSlots.add(new TimeSlot(cursor, cursor.plus(slotLength)));
                log.info("Added free slot: {} - {}", cursor, cursor.plus(slotLength));
                cursor = cursor.plus(slotLength);
            }
            if (cursor.isBefore(busyEnd)) cursor = busyEnd;
        }

        while (cursor.plus(slotLength).isBefore(endOfDay)) {
            freeSlots.add(new TimeSlot(cursor, cursor.plus(slotLength)));
            log.info("Added free slot: {} - {}", cursor, cursor.plus(slotLength));
            cursor = cursor.plus(slotLength);
        }
        return freeSlots;
    }
}

