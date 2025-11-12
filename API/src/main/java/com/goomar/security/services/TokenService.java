package com.goomar.security.services;

import com.goomar.security.jwt.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService implements ITokenService {
    final AuthenticationManager authenticationManager;
    final JwtUtils jwtUtils; //TODO remove jwt dependency

    @Override
    public TokenRsp getToken(GetTokenReq getTokenRequest) {
        log.info("User {} tried log in.", getTokenRequest.getUsername());

        RestTemplate rest = new RestTemplate();
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "password");
        form.add("client_id", "goomar");
        form.add("username", getTokenRequest.getUsername());
        form.add("password", getTokenRequest.getPassword());

        ResponseEntity<Map> response = rest.postForEntity("http://localhost:8008/realms/bosnic/protocol/openid-connect/token",form,Map.class);
log.info("Response: {}", response.getBody().get("access_token"));
        return response.getBody() != null ? new TokenRsp().token((String) response.getBody().get("access_token")): null;
    }
}
