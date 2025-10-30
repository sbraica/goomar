package com.goomar.service;

import com.google.api.client.util.Base64;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.Message;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.mail.Message.RecipientType;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

@Service
@RequiredArgsConstructor
@Slf4j
public class GmailEmailService implements IEmailService {
    private final Gmail gmail;

    @Value("${goomar.mail.from:termin@bosnic.hr}")
    private String fromAddress;

    @Override
    public void sendText(String to, String subject, String body) {
        send(to, subject, body, false);
    }

    @Override
    public void sendHtml(String to, String subject, String htmlBody) {
        send(to, subject, htmlBody, true);
    }

    private void send(String to, String subject, String content, boolean html) {
        try {
            MimeMessage mimeMessage = buildMime(to, subject, content, html);
            Message gmailMessage = toGmailMessage(mimeMessage);
            Message sent = gmail.users().messages().send("me", gmailMessage).execute();
            log.info("📧 Email sent to={} subject={} id={}", to, subject, sent.getId());
        } catch (Exception e) {
            log.error("Failed to send email to={} subject={}", to, subject, e);
            throw new RuntimeException("Failed to send email", e);
        }
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

    private Message toGmailMessage(MimeMessage email) throws Exception {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        email.writeTo(buffer);
        String encodedEmail = Base64.encodeBase64URLSafeString(buffer.toByteArray());
        Message message = new Message();
        message.setRaw(encodedEmail);
        return message;
    }
}
