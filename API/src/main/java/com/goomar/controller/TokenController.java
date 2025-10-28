package com.goomar.controller;

import com.goomar.security.services.ITokenService;
import lombok.RequiredArgsConstructor;
import org.openapitools.api.TokensApi;
import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RestController;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequiredArgsConstructor
public class TokenController implements TokensApi {
    private final ITokenService tokenService;

    @Override
    public ResponseEntity<TokenRsp> getToken(GetTokenReq req) {
        return new ResponseEntity<>(tokenService.getToken(req), HttpStatus.CREATED);
    }
}
