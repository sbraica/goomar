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

    //TODO: use env variable
    private final String url = "http://keycloak:8080/realms/bosnic/protocol/openid-connect/token";
    @Override
    public TokenRsp getToken(GetTokenReq getTokenRequest) {
        log.info("getToken()");

        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("client_id", "goomar");
        formData.add("scope", "openid");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        if (getTokenRequest.getRefreshToken() != null) {
            return getTokenRefresh(getTokenRequest, formData, headers);
        } else {
            return getTokenUserNamePassword(getTokenRequest, formData, headers);
        }
    }
    private TokenRsp getTokenRefresh(GetTokenReq getTokenRequest, MultiValueMap<String, String> formData, HttpHeaders headers) {

        RestTemplate restTemplate = new RestTemplate();
        formData.add("grant_type", "refresh_token");
        formData.add("refresh_token", getTokenRequest.getRefreshToken());

        return getTokenRsp(formData, headers, restTemplate);
    }
    private TokenRsp getTokenUserNamePassword(GetTokenReq getTokenRequest, MultiValueMap<String, String> formData, HttpHeaders headers) {

        RestTemplate restTemplate = new RestTemplate();

        formData.add("grant_type", "password");
        formData.add("username", getTokenRequest.getUsername());
        formData.add("password", getTokenRequest.getPassword());

        return getTokenRsp(formData, headers, restTemplate);
    }

    private TokenRsp getTokenRsp(MultiValueMap<String, String> formData, HttpHeaders headers, RestTemplate restTemplate) {
        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(formData, headers);
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(url, HttpMethod.POST, request, new ParameterizedTypeReference<>() {});

        if (response.getBody() != null) {
            Map<String, Object> sr = response.getBody();
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