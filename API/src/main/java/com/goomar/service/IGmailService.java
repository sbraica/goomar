package com.goomar.service;

import org.openapitools.model.ReservationRest;

import java.util.UUID;

public interface IGmailService {
    void sendText(String to, String subject, String body);
    void sendHtml(String to, String subject, String htmlBody);
    void send(ReservationRest rr, UUID uuid);
}
