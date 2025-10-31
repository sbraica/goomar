package com.goomar.controller;

import com.goomar.service.ICalendarService;
import com.goomar.service.IEntryService;
import com.goomar.service.IGmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.api.AppointmentsApi;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequiredArgsConstructor
@RestController
@Slf4j
public class AppointmentController implements AppointmentsApi {
    private final IEntryService entryService;
    private final ICalendarService calendarService;
    private final IGmailService emailService;


    @Override
    public ResponseEntity<Void> confirmAppointment(String authorization, String eventId) {
        ReservationRest rr = entryService.confirmAppoitnment(eventId);
        calendarService.confirmAppointment( eventId);
        emailService.sendConfirmation(rr);
        return new ResponseEntity(HttpStatus.CREATED);
    }

    @Override
    public ResponseEntity<Void> deleteAppointment(String authorization, String eventId) {
        return null;
    }

    @Override
    public ResponseEntity<List<ReservationRest>> getAppointments(String authorization, Integer year, Integer month, Integer day) {
        return new ResponseEntity(entryService.getAppointments(authorization, year, month, day), HttpStatus.OK);
    }

}
