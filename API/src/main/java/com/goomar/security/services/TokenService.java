package com.goomar.security.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService implements ITokenService {

    @Override
    public TokenRsp getToken(GetTokenReq getTokenRequest) {
        log.info("User {} tried log in.", getTokenRequest.getUsername());

        RestTemplate restTemplate = new RestTemplate();
        //TODO: use env variable
        String url = "http://keycloak:8080/realms/bosnic/protocol/openid-connect/token";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("grant_type", "password");
        formData.add("client_id", "goomar");
        formData.add("username", getTokenRequest.getUsername());
        formData.add("password", getTokenRequest.getPassword());
        formData.add("scope", "openid");

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(formData, headers);
        ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
        if (response.getBody() != null) {
            Map<String, String> sr = response.getBody();
            return new TokenRsp().accessToken(sr.get("access_token")).idToken(sr.get("id_token")).refreshToken(sr.get("refresh_token"))
                    .refreshExpiresIn(Integer.valueOf(sr.get("refresh_expires_in"))).tokenType(sr.get("token_type"))
                    .idToken(sr.get("id_token")).expiresIn(Integer.valueOf(sr.get("expires_in")))
                    .refreshExpiresIn(Integer.valueOf(sr.get("refresh_expires_in")))
                    .notBeforePolicy(Integer.valueOf(sr.get("not-before-policy"))).scope(sr.get("scope")).sessionState(sr.get("session_state"));
        } return null;
    }
}