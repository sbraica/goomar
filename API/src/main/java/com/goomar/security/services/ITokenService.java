package com.goomar.security.services;

import org.openapitools.model.GetTokenReq;
import org.openapitools.model.TokenRsp;

public interface ITokenService {
    TokenRsp getToken(GetTokenReq getTokenRequest);
}
