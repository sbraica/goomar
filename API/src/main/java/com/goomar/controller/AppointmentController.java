package com.goomar.controller;

import com.google.api.services.calendar.model.*;
import com.goomar.service.ICalendarService;
import com.goomar.service.IEmailService;
import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.api.AppointmentsApi;
import org.openapitools.api.ReservationsApi;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.time.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

@RequiredArgsConstructor
@RestController
@Slf4j
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
