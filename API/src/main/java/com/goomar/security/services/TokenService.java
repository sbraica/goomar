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

        log.info("Response: {}", response.getBody().get("access_token"));
        return response.getBody() != null ? new TokenRsp().token((String) response.getBody().get("access_token")): null;
    }
}