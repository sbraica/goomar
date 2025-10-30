package com.goomar.service;

import com.google.api.services.calendar.model.Event;
import lombok.SneakyThrows;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.List;

public interface ICalendarService {
    List<Event> getEventsForDay(LocalDate date);
    String insertReservation(ReservationRest reservationRest);

    @SneakyThrows
    List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService);

    void confirmAppointment(String eventId);
}
