package com.goomar.controller;

import com.goomar.service.ICalendarService;
import com.goomar.service.IGmailService;
import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.api.ReservationsApi;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;
import org.openapitools.model.UpdateReservationRest;
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
        log.info("createReservation(rr={})", rr);
        UUID uuid = entryService.insertReservation(rr);
        emailService.sendReservation(rr, uuid);
        return new ResponseEntity(uuid, HttpStatus.OK);
    }

    @Override
    public ResponseEntity<String> confirmEmailOK(String id) {
        log.info("confirmEmailOK(uuid={})", id);
        if (!entryService.get(id).getEmailOk()) {
            String event_id = calendarService.insertAppointment(entryService.get(id));
            entryService.setEventId(id, event_id);
            return new ResponseEntity(entryService.confirmEmailOK(id), HttpStatus.OK);
        } else {
            log.info("Email already confirmed, id = {}", id);
            return new ResponseEntity("<html><body><h2>Rezervacija prethodno potvrđena!</h2></body></html>", HttpStatus.OK);
        }
    }

    @Override
    public ResponseEntity<Void> updateReservation(String authorization, UpdateReservationRest urr) {
        log.info("updateAppointment(urr={})", urr);
        if (urr.getApproved()) {
            log.info("Regular approvement, id = {}", urr.getId());
            ReservationRest rr = entryService.confirmReservation(urr.getId());
            calendarService.confirmAppointment(rr.getEventId());
            emailService.sendConfirmation(rr);
        } else {
            ReservationRest rr = entryService.setEmail(urr);
            if (urr.getSendMail()) {
                log.info("Invalid e-mail, send new one, id = {}", urr.getId());
                emailService.sendReservation(rr, rr.getId());
            } else {
                log.info("Invalid e-mail, ignore, approve, id = {}", urr.getId());
                String event_id = calendarService.insertAppointment(entryService.get(urr.getId()));
                entryService.setEventId(urr.getId(), event_id);
            }
        }
        return new ResponseEntity(HttpStatus.CREATED);
    }

    @Override
    public ResponseEntity<Void> deleteAppointment(String authorization, String id) {
        log.info("deleteAppointment(id={})", id);
        ReservationRest rr = entryService.deleteReservation(id);
        if (rr.getEventId()!=null){
            calendarService.deleteAppointment(rr.getEventId());
        }
        emailService.sendDelete(rr);
        return new ResponseEntity(HttpStatus.NO_CONTENT);
    }

    @Override
    public ResponseEntity<List<ReservationRest>> getWeekAppointments(String authorization, Integer year, Integer month, Integer day) {
        return new ResponseEntity(entryService.getAppointments(year, month, day), HttpStatus.OK);
    }
}
