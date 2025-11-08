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
    public ResponseEntity<List<FreeSlotRest>> getFreeSlots(Integer year, Integer month, Integer day, Boolean _long) {
        return new ResponseEntity(calendarService.getFreeSlots(LocalDate.of(year, month, day), _long), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<Void> createReservation(ReservationRest rr) {
        log.info("createReservation(id={})", rr.getId());
        UUID uuid = entryService.insertReservation(rr);
        emailService.sendReservation(rr, uuid);
        return new ResponseEntity(uuid, HttpStatus.OK);
    }

    @Override
    public ResponseEntity<String> confirmEmailOK(String uuid) {
        log.info("confirmEmailOK(uuid={})", uuid);
        return new ResponseEntity(entryService.confirmEmailOK(uuid), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<Void> makeAppointment(String authorization, String id) {
        log.info("makeAppointment(id={})", id);
        ReservationRest rr = entryService.makeAppointment(id);
        String event_id = calendarService.insertAppoitnment(rr);
        emailService.sendConfirmation(rr);
        entryService.setEventId(id, event_id);
        return new ResponseEntity(HttpStatus.CREATED);
    }

    @Override
    public ResponseEntity<Void> deleteAppointment(String authorization, String id) {
        log.info("deleteAppointment(id={})", id);
        ReservationRest rr = entryService.deleteAppoitnment(id);
        calendarService.deleteAppointment( rr.getEventId());
        emailService.sendDelete(rr);
        return new ResponseEntity(HttpStatus.NO_CONTENT);
    }

    @Override
    public ResponseEntity<List<ReservationRest>> getAppointments(String authorization, Integer year, Integer month, Integer day) {
        return new ResponseEntity(entryService.getAppointments(year, month, day), HttpStatus.OK);
    }
}
