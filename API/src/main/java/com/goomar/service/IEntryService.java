package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.List;
import java.util.UUID;

public interface IEntryService {
    UUID insertReservation(ReservationRest reservationRest);
    List<ReservationRest> getAppointments(int year, int month, int day);
    String confirmEmailOK(String token);
    ReservationRest confirmReservation(String id);
    ReservationRest deleteReservation(String eventId);
    void setEventId(String id, String eventId);
    ReservationRest get(String uuid);
}
