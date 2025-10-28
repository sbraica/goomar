package com.goomar.security.services;

import com.goomar.security.jwt.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jooq.DSLContext;
import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

import static com.fasterxml.jackson.databind.type.LogicalType.DateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService implements ITokenService {
    final AuthenticationManager authenticationManager;
    final JwtUtils jwtUtils;

    @Override
    public TokenRsp getToken(GetTokenReq getTokenRequest) {
        log.info("Handled by thread: {}", Thread.currentThread());
        log.info("User {} tried log in.", getTokenRequest.getUsername());
        Authentication authentication = authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(getTokenRequest.getUsername(), getTokenRequest.getPassword()));
        SecurityContextHolder.getContext().setAuthentication(authentication);
        log.info("User {} logged in.", authentication.getName());
        return new TokenRsp().token(jwtUtils.generateJwtToken((FlexiUserDetails) authentication.getPrincipal()).getValue());
    }
}
