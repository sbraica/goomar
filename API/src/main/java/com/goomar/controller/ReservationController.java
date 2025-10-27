package com.goomar.controller;

import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import org.openapitools.api.ReservationApi;
import org.openapitools.model.ReservationRest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
public class ReservationController implements ReservationApi {
    private final IEntryService entryService;

    @Override
    public ResponseEntity<Integer> createReservation(ReservationRest reservationRest) {
        return new ResponseEntity(entryService.insertReservation(reservationRest), HttpStatus.OK);
    }
}
