package com.goomar.service;

import com.google.api.services.calendar.model.Event;
import com.goomar.model.TimeSlot;
import lombok.SneakyThrows;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

public interface ICalendarService {
    List<Event> getEventsForDay(LocalDate date);

    @SneakyThrows
    List<TimeSlot> getFreeSlots(LocalDate date, boolean longService);
}
