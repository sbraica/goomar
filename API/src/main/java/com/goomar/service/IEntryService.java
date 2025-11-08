package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.List;
import java.util.UUID;

public interface IEntryService {
    UUID insertReservation(ReservationRest reservationRest);
    List<ReservationRest> getAppointments(int year, int month, int day);
    String confirmEmailOK(String token);
    ReservationRest makeAppointment(String id);
    ReservationRest deleteAppoitnment(String eventId);
    void setEventId(String id, String eventId);
}
