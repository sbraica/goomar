package com.goomar.service;

import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;

import java.time.LocalDate;
import java.util.List;

public interface ICalendarService {
    String insertAppointment(ReservationRest reservationRest);

    List<FreeSlotRest> getFreeSlots(LocalDate date, boolean longService);

    void confirmAppointment(String eventId);

    void deleteAppointment(String id);
}
