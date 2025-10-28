package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.List;

public interface IEntryService {
    int insertReservation(ReservationRest reservationRest);
    List<ReservationRest> getReservations(String authorization);

    void createAppointment(int appId);

    //TODO duplicate?
    List<ReservationRest> getAppointments(String authorization);
}
