package com.goomar.model;

import lombok.RequiredArgsConstructor;

import java.time.ZonedDateTime;

@RequiredArgsConstructor
public class TimeSlot {
    private final ZonedDateTime start;
    private final ZonedDateTime end;
}