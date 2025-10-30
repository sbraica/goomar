package com.goomar.controller;

import com.goomar.service.ICalendarService;
import com.goomar.service.IGmailService;
import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
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
public class ReservationController implements ReservationsApi {
    private final IEntryService entryService;
    private final ICalendarService calendarService;
    private final IGmailService emailService;

    @Override
    public ResponseEntity<Integer> createReservation(ReservationRest rr) {
        UUID uuid = UUID.randomUUID();
        String calendarId = calendarService.insertReservation(rr);
        emailService.send(rr, uuid);
        return new ResponseEntity(entryService.insertReservation(rr, uuid, calendarId), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<String> getConfirmation(String token) {
        return new ResponseEntity(entryService.getConfirmation(token), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<List<FreeSlotRest>> getFreeSlots(Integer year, Integer month, Integer day, Boolean _long) {
        return new ResponseEntity(calendarService.getFreeSlots(LocalDate.of(year, month, day), _long), HttpStatus.OK);
    }
}
