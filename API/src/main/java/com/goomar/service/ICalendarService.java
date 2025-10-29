package com.goomar.service;

import com.google.api.services.calendar.model.Event;
import lombok.SneakyThrows;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;

import java.time.LocalDate;
import java.util.List;

public interface ICalendarService {
    List<Event> getEventsForDay(LocalDate date);
    int insertReservation(ReservationRest reservationRest);

    @SneakyThrows
    List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService);
}
