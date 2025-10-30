package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.UUID;

public interface IEmailService {
    void sendText(String to, String subject, String body);
    void sendHtml(String to, String subject, String htmlBody);
    void send(ReservationRest rr, UUID uuid);
}
