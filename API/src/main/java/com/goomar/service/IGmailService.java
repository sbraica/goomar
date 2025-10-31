package com.goomar.service;

import lombok.SneakyThrows;
import org.openapitools.model.ReservationRest;

import java.util.UUID;

public interface IGmailService {
    void sendText(String to, String subject, String body);
    void sendHtml(String to, String subject, String htmlBody);
    void sendReservation(ReservationRest rr, UUID uuid);
    void sendConfirmation(ReservationRest rr);
}
