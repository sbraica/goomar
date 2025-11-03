package com.goomar.controller;

import com.goomar.service.ICalendarService;
import com.goomar.service.IGmailService;
import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.api.ReservationsApi;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@RestController
@Slf4j
public class ReservationController implements ReservationsApi {
    private final IEntryService entryService;
    private final ICalendarService calendarService;
    private final IGmailService emailService;

    @Override
    public ResponseEntity<Void> confirmReservation(String authorization, String eventId) {
        log.info("confirmReservation(eventId={})", eventId);
        ReservationRest rr = entryService.confirmReservation(eventId);
        log.info("1", eventId);
        calendarService.confirmAppointment( eventId);
        log.info("2", eventId);
        emailService.sendConfirmation(rr);
        log.info("3", eventId);
        return new ResponseEntity(HttpStatus.CREATED);
    }

    @Override
    public ResponseEntity<Void> createReservation(ReservationRest rr) {
        String calendarId = calendarService.insertReservation(rr);
        UUID uuid = entryService.insertReservation(rr, calendarId);
        emailService.sendReservation(rr, uuid);
        return new ResponseEntity(entryService.insertReservation(rr, calendarId), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<Void> deleteReservation(String authorization, String eventId) {
        ReservationRest rr = entryService.deleteAppoitnment(eventId);
        calendarService.deleteAppointment( eventId);
        emailService.sendDelete(rr);
        return new ResponseEntity(HttpStatus.NO_CONTENT);
    }

    @Override
    public ResponseEntity<List<FreeSlotRest>> getAppointments(String authorization, Integer year, Integer month, Integer day) {
        return new ResponseEntity(entryService.getAppointments(authorization, year, month, day), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<String> getConfirmation(String uuid) {
        return new ResponseEntity(entryService.getConfirmation(uuid), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<List<FreeSlotRest>> getFreeSlots(Integer year, Integer month, Integer day, Boolean _long) {
        return new ResponseEntity(calendarService.getFreeSlots(LocalDate.of(year, month, day), _long), HttpStatus.OK);
    }
}
