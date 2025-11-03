package com.goomar.config;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.auth.oauth2.TokenResponse;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.FileDataStoreFactory;
import com.google.api.services.calendar.Calendar;
import com.google.api.services.gmail.Gmail;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.io.InputStreamReader;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;

@Configuration
public class GoogleApiConfig {

    private static final String APPLICATION_NAME = "Goomar App";
    private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();
    private static final String TOKENS_DIRECTORY_PATH = "tokens";
    private static final List<String> SCOPES = Arrays.asList(
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/calendar"
    );

    @Bean
    public GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow() throws GeneralSecurityException, IOException {
        final NetHttpTransport httpTransport = GoogleNetHttpTransport.newTrustedTransport();
        GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(
                JSON_FACTORY,
                new InputStreamReader(new ClassPathResource("credentials.json").getInputStream())
        );

        return new GoogleAuthorizationCodeFlow.Builder(
                httpTransport,
                JSON_FACTORY,
                clientSecrets,
                SCOPES
        )
                .setAccessType("offline")
                .setDataStoreFactory(new FileDataStoreFactory(new File(TOKENS_DIRECTORY_PATH)))
                .build();
    }

    @Bean
    public Gmail googleGmailService(GoogleAuthorizationCodeFlow flow) throws Exception {
        Credential credential = flow.loadCredential("user");
        if (credential == null) {
            throw new IllegalStateException("No credentials found. User must authorize first!");
        }
        return new Gmail.Builder(
                GoogleNetHttpTransport.newTrustedTransport(),
                JSON_FACTORY,
                credential
        ).setApplicationName(APPLICATION_NAME).build();
    }

    @Bean
    public Calendar googleCalendarService(GoogleAuthorizationCodeFlow flow) throws Exception {
        Credential credential = flow.loadCredential("user");
        if (credential == null) {
            throw new IllegalStateException("No credentials found. User must authorize first!");
        }
        return new Calendar.Builder(
                GoogleNetHttpTransport.newTrustedTransport(),
                JSON_FACTORY,
                credential
        ).setApplicationName(APPLICATION_NAME).build();
    }

    @RestController
    public static class GoogleOAuthController {

        private final GoogleAuthorizationCodeFlow flow;

        public GoogleOAuthController(GoogleAuthorizationCodeFlow flow) {
            this.flow = flow;
        }

        /**
         * Start OAuth flow manually in production
         */
        @GetMapping("/google/auth")
        public String authorize() throws IOException {
            String authUrl = flow.newAuthorizationUrl()
                    .setRedirectUri("https://terminapi.bosnic.hr/oauth2/callback")
                    .build();
            return "<a href=\"" + authUrl + "\" target=\"_blank\">Authorize Google Access</a>";
        }

        /**
         * Callback endpoint to receive authorization code from Google
         */
        @GetMapping("/oauth2/callback")
        public String callback(@RequestParam String code) throws IOException {
            TokenResponse tokenResponse = flow.newTokenRequest(code)
                    .setRedirectUri("https://terminapi.bosnic.hr/oauth2/callback")
                    .execute();
            flow.createAndStoreCredential(tokenResponse, "user");
            return "Authorization successful!";
        }
    }
}
