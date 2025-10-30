package com.goomar.service;

public interface IEmailService {
    void sendText(String to, String subject, String body);
    void sendHtml(String to, String subject, String htmlBody);
}
