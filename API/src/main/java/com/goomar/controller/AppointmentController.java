package com.goomar.controller;

import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import org.openapitools.api.AppointmentsApi;
import org.openapitools.api.ReservationApi;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequiredArgsConstructor
@RestController
public class AppointmentController implements AppointmentsApi {
    private final IEntryService entryService;

    @Override
    public ResponseEntity<Void> createAppointment(Integer appId, String authorization) {
        entryService.createAppointment(appId);
        return new ResponseEntity(HttpStatus.OK);
    }

    @Override
    public ResponseEntity<List<ReservationRest>> getAppointments(String authorization, Integer year, Integer month, Integer day) {
        return new ResponseEntity(entryService.getAppointments(authorization, year, month, day), HttpStatus.OK);
    }

}
