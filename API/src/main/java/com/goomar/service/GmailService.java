package com.goomar.service;

import com.google.api.client.util.Base64;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.Message;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.ReservationRest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import jakarta.mail.Message.RecipientType;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class GmailService implements IGmailService {
    private final Gmail gmail;

    private final static DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy., HH:mm");

    @Value("${goomar.appUrl}")
    private String appUrl;
    private String fromAddress = "termin@bosnic.hr";

    @Override
    public void sendText(String to, String subject, String body) {
        sendMail(to, subject, body, false);
    }

    @Override
    public void sendHtml(String to, String subject, String htmlBody) {
        sendMail(to, subject, htmlBody, true);
    }

    @SneakyThrows
    @Override
    public void sendReservation(ReservationRest rr, UUID uuid) {

        Map<String, String> values = Map.of(
                "customerName", rr.getUsername(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter),
                "confirmationUrl", appUrl + "/V1/confirmation?uuid="+uuid.toString()
        );
        var resource = new ClassPathResource("templates/registration-confirmation.html");
        String content = Files.readString(resource.getFile().toPath(), StandardCharsets.UTF_8);

        for (var entry : values.entrySet()) {
            content = content.replace("{{" + entry.getKey() + "}}", entry.getValue());
        }
        sendHtml(rr.getEmail(), "Potvrda rezervacije", content);
    }

    @SneakyThrows
    @Override
    public void sendConfirmation(ReservationRest rr) {

        Map<String, String> values = Map.of(
                "customerName", rr.getUsername(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter));
        var resource = new ClassPathResource("templates/appointnment-confirmation.html");
        String content = Files.readString(resource.getFile().toPath(), StandardCharsets.UTF_8);

        for (var entry : values.entrySet()) {
            content = content.replace("{{" + entry.getKey() + "}}", entry.getValue());
        }
        sendHtml(rr.getEmail(), "Potvrda termina", content);
    }

    @SneakyThrows
    @Override
    public void sendDelete(ReservationRest rr) {
        Map<String, String> values = Map.of(
                "customerName", rr.getUsername(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter));
        var resource = new ClassPathResource("templates/appointnment-deletion.html");
        String content = Files.readString(resource.getFile().toPath(), StandardCharsets.UTF_8);

        for (var entry : values.entrySet()) {
            content = content.replace("{{" + entry.getKey() + "}}", entry.getValue());
        }
        sendHtml(rr.getEmail(), "Poništenje termina !!!", content);
    }

    @SneakyThrows
    private void sendMail(String to, String subject, String content, boolean html) {
        MimeMessage mimeMessage = buildMime(to, subject, content, html);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        mimeMessage.writeTo(buffer);
        Message sent = gmail.users().messages().send("me", (new Message()).setRaw(Base64.encodeBase64URLSafeString(buffer.toByteArray()))).execute();
        log.info("📧 Email sent to={} subject={} id={}", to, subject, sent.getId());
    }

    private MimeMessage buildMime(String to, String subject, String content, boolean html) throws MessagingException {
        Properties props = new Properties();
        Session session = Session.getInstance(props, null);
        MimeMessage email = new MimeMessage(session);
        email.setFrom(new InternetAddress(fromAddress));
        email.addRecipient(RecipientType.TO, new InternetAddress(to));
        email.setSubject(subject, StandardCharsets.UTF_8.name());
        if (html) {
            email.setContent(content, "text/html; charset=UTF-8");
        } else {
            email.setText(content, StandardCharsets.UTF_8.name());
        }
        return email;
    }

}
