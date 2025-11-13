package com.goomar.service;

import lombok.SneakyThrows;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;

import java.time.LocalDate;
import java.util.List;

public interface ICalendarService {
    String insertAppoitnment(ReservationRest reservationRest);

    @SneakyThrows
    List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService);

    @SneakyThrows
    void confirmAppointment(String eventId);

    void deleteAppointment(String eventId);
}
