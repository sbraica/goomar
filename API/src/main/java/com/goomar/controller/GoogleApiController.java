package com.goomar.controller;

import com.google.api.client.auth.oauth2.TokenResponse;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.api.GoogleApi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

@RequiredArgsConstructor
@RestController
@Slf4j
public class GoogleApiController implements GoogleApi {
    private final GoogleAuthorizationCodeFlow flow;

    @Value("${goomar.redirectUri}")
    private String redirectUri;

    @Override
    public ResponseEntity<String> googleAuth() {
        String authUrl = flow.newAuthorizationUrl().setRedirectUri(redirectUri).set("access_type", "offline").set("prompt", "consent").build();
        return new ResponseEntity("<a href=\"" + authUrl + "\" target=\"_blank\">Authorize Google Access</a>", HttpStatus.OK);
    }

    @Override
    public ResponseEntity<String> googleCallback(String code)  {
        try {
            TokenResponse tokenResponse = flow.newTokenRequest(code).setRedirectUri(redirectUri).execute();
            flow.createAndStoreCredential(tokenResponse, "user");
            return new ResponseEntity<>("Authorization successful! You can now use Calendar and Gmail APIs.", HttpStatus.OK);
        } catch (IOException e) {
            return new ResponseEntity<>("Authorization successful! You can now use Calendar and Gmail APIs.", HttpStatus.UNAUTHORIZED);
        }
    }
}
