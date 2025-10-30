package com.goomar.controller;

import com.goomar.service.ICalendarService;
import com.goomar.service.IEmailService;
import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import org.openapitools.api.ReservationsApi;
import org.openapitools.model.FreeSlotRest;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@RequiredArgsConstructor
@RestController
public class ReservationController implements ReservationsApi {
    private final IEntryService entryService;
    private final ICalendarService calendarService;
    private final IEmailService emailService;

    @Override
    public ResponseEntity<Integer> createReservation(ReservationRest reservationRest) {
        calendarService.insertReservation(reservationRest);
        emailService.sendText("stipe.braica@gmail.com", "subject", "body");

        return new ResponseEntity(entryService.insertReservation(reservationRest), HttpStatus.OK);
    }

    @Override
    public ResponseEntity<List<FreeSlotRest>> getFreeSlots(Integer year, Integer month, Integer day, Boolean _long) {
        return new ResponseEntity(calendarService.getFreeSlots(LocalDate.of(year, month, day), _long), HttpStatus.OK);
    }
}
