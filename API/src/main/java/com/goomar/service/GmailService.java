package com.goomar.service;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.Base64;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.Message;
import jakarta.annotation.PostConstruct;
import jakarta.mail.Message.RecipientType;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.ReservationRest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class GmailService implements IGmailService {

    private final GoogleAuthorizationCodeFlow flow;

    private static final DateTimeFormatter formatter =
            DateTimeFormatter.ofPattern("dd.MM.yyyy., HH:mm");

    @Value("${goomar.appUrl}")
    private String appUrl;

    @Value("${goomar.mail.from:termin@bosnic.hr}")
    private String fromAddress;

    private Gmail gmail;
    private Credential credential; // keep a reference to it

    // Cached templates
    private String tplRegistration;
    private String tplConfirmation;
    private String tplDeletion;

    @PostConstruct
    void init() {
        // Load templates immediately
        this.tplRegistration = loadClasspath("templates/registration-confirmation.html");
        this.tplConfirmation = loadClasspath("templates/appointnment-confirmation.html");
        this.tplDeletion = loadClasspath("templates/appointnment-deletion.html");

        // Attempt to initialize Gmail client lazily
        try {
            initGmailClient();
        } catch (Exception e) {
            log.warn("⚠️ Gmail not initialized yet — user must authorize first via /google/auth");
        }

        log.info("📩 GmailService initialized (templates loaded, gmail client: {})",
                gmail != null ? "ready" : "not yet authorized");
    }

    /** Try to create Gmail client if credentials exist */
    private synchronized void initGmailClient() throws Exception {
        if (this.gmail != null && this.credential != null) return;

        this.credential = flow.loadCredential("user");
        if (this.credential == null) {
            throw new IllegalStateException("No Google credentials found. Please authorize via /google/auth");
        }

        this.gmail = new Gmail.Builder(
                GoogleNetHttpTransport.newTrustedTransport(),
                JacksonFactory.getDefaultInstance(),
                credential)
                .setApplicationName("Goomar App")
                .build();

        log.info("✅ Gmail client initialized successfully.");
    }

    /** Load a file from classpath as UTF-8 string */
    private String loadClasspath(String path) {
        try (var reader = new BufferedReader(new InputStreamReader(
                new ClassPathResource(path).getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().reduce("", (acc, line) -> acc + line + "\n");
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to load template: " + path, e);
        }
    }

    // ----------- Public mail operations -----------

    @Override
    public void sendReservation(ReservationRest rr, UUID uuid) {
        log.info("sendReservation(rr={}, uuid={})", rr, uuid);
        Map<String, String> values = Map.of(
                "name", rr.getName(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter),
                "confirmationUrl", appUrl + "/V1/confirmation?uuid=" + uuid
        );
        sendMail(rr.getEmail(), "Potvrda rezervacije",
                replacePlaceholders(tplRegistration, values));
    }

    @Override
    public void sendConfirmation(ReservationRest rr) {
        log.info("sendConfirmation(rr={})", rr);
        Map<String, String> values = Map.of(
                "name", rr.getName(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter)
        );
        sendMail(rr.getEmail(), "Potvrda termina",
                replacePlaceholders(tplConfirmation, values));
    }

    @Override
    public void sendDelete(ReservationRest rr) {
        Map<String, String> values = Map.of(
                "name", rr.getName(),
                "registration", rr.getRegistration(),
                "timeslot", rr.getDateTime().format(formatter)
        );
        sendMail(rr.getEmail(), "Poništenje termina !!!",
                replacePlaceholders(tplDeletion, values));
    }

    // ----------- Internal helpers -----------

    private String replacePlaceholders(String template, Map<String, String> values) {
        String result = template;
        for (var entry : values.entrySet()) {
            result = result.replace("{{" + entry.getKey() + "}}", entry.getValue());
        }
        return result;
    }

    @SneakyThrows
    public void sendMail(String to, String subject, String content) {
        ensureGmailReady();  // ensures initialized & valid token

        MimeMessage mimeMessage = buildMime(to, subject, content);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        mimeMessage.writeTo(buffer);

        String encodedEmail = Base64.encodeBase64URLSafeString(buffer.toByteArray());
        Message message = new Message().setRaw(encodedEmail);

        Message sent = gmail.users().messages().send("me", message).execute();
        log.info("📧 Email sent to={} subject={} id={}", to, subject, sent.getId());
    }

    /** Ensure Gmail client exists and token is valid */
    private synchronized void ensureGmailReady() throws Exception {
        if (this.gmail == null || this.credential == null) {
            log.info("⚙️ Gmail client not ready — attempting to initialize");
            initGmailClient();
        }

        // Explicit token refresh if it's about to expire
        if (credential.getExpiresInSeconds() != null && credential.getExpiresInSeconds() < 60) {
            if (credential.refreshToken()) {
                log.info("🔄 Gmail access token refreshed successfully.");
            } else {
                log.warn("⚠️ Gmail token refresh failed. User reauthorization may be required.");
            }
        }
    }

    private MimeMessage buildMime(String to, String subject, String content) throws MessagingException {
        Properties props = new Properties();
        Session session = Session.getInstance(props, null);
        MimeMessage email = new MimeMessage(session);
        email.setFrom(new InternetAddress(fromAddress));
        email.addRecipient(RecipientType.TO, new InternetAddress(to));
        email.setSubject(subject, StandardCharsets.UTF_8.name());
        email.setContent(content, "text/html; charset=UTF-8");
        return email;
    }
}
