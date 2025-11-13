package com.goomar.security.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
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
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(url, HttpMethod.POST, request, new ParameterizedTypeReference<Map<String, Object>>() {
        });

        if (response.getBody() != null) {
            Map<String, Object> sr = response.getBody();

            sr.forEach((key, value) -> log.info("{} => {}", key, value));

            return new TokenRsp()
                    .accessToken((String) sr.get("access_token"))
                    .idToken((String) sr.get("id_token"))
                    .refreshToken((String) sr.get("refresh_token"))
                    .refreshExpiresIn(Integer.parseInt(sr.get("refresh_expires_in").toString()))
                    .tokenType((String) sr.get("token_type"))
                    .expiresIn(Integer.parseInt(sr.get("expires_in").toString()))
                    .notBeforePolicy(Integer.parseInt(sr.get("not-before-policy").toString()))
                    .scope((String) sr.get("scope"))
                    .sessionState((String) sr.get("session_state"));
        }
        return null;
    }
}