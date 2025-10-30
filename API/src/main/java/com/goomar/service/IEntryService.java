package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.List;
import java.util.UUID;

public interface IEntryService {
    int insertReservation(ReservationRest reservationRest, UUID uuid, String calendarId);
    List<ReservationRest> getAppointments(String authorization, int year, int month, int day);
    String getConfirmation(String token);
}
