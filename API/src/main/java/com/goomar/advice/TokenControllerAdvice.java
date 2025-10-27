package com.goomar.advice;

import lombok.extern.slf4j.Slf4j;
import org.postgresql.util.PSQLException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
@RestControllerAdvice
public class TokenControllerAdvice {

    public static final int APP_ERR_CODE_SQL_UNKNOWN = 1000;
    public static final int APP_ERR_CODE_SQL_DUPLICATE = 1001;
    public static final int APP_ERR_CODE_SQL_HAS_RELATED = 1002;
    public static final int APP_ERR_CODE_SQL_CANNOT_DELETE = 1003;
    public static final int APP_ERR_CODE_MAIL_ERROR = 1004;

    public static final int APP_ERR_CODE_INVALID_CREDENTIALS = 2001;


/*
    @ExceptionHandler(value = TokenRefreshException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public ErrorMessage handleTokenRefreshException(TokenRefreshException ex, WebRequest request) {
        return new ErrorMessage(HttpStatus.FORBIDDEN.value(), new Date(), ex.getMessage(), request.getDescription(false), "path");
    }

    @ExceptionHandler(value = MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorMessage handleMethodArgumentNotValidException(MethodArgumentNotValidException ex) {
        final Matcher matcher = Pattern.compile("\\[Field.*?\\;").matcher(ex.getMessage());
        String parsedMessage = "";
        if (matcher.find()) {
            parsedMessage = matcher.group(0);
        }
        return new ErrorMessage(HttpStatus.BAD_REQUEST.value(), new Date(), parsedMessage, ex.getMessage(), "path");
    }
*/

    @ExceptionHandler(value = BadCredentialsException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public ErrorMessage handleUnathorized(BadCredentialsException ex) {
        final Matcher matcher = Pattern.compile("\\[Field.*?\\;").matcher(ex.getMessage());
        String parsedMessage = "";
        if (matcher.find()) {
            parsedMessage = matcher.group(0);
        }
        return new ErrorMessage(HttpStatus.UNAUTHORIZED.value(), new Date(), parsedMessage, ex.getMessage(), "path");
    }

    @ExceptionHandler(RuntimeException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorMessage runtimeException(RuntimeException e) {
        if (e.getCause() instanceof PSQLException) {
            String parsedMessage = e.getMessage();
            int appErrCode = APP_ERR_CODE_SQL_UNKNOWN;
            if (e instanceof DuplicateKeyException) {
                appErrCode = APP_ERR_CODE_SQL_DUPLICATE;
                final Matcher matcher = Pattern.compile("\\((.*)\\)=\\((.*)\\)").matcher(e.getMessage());
                if (matcher.find() && matcher.groupCount() == 2) {
                    parsedMessage = matcher.group(1) + " = \"" + matcher.group(2) + "\"";
                }
            } else {
                if (e instanceof DataIntegrityViolationException) {
                    appErrCode = APP_ERR_CODE_SQL_HAS_RELATED;
                }
            }
            List<StackTraceElement> ste = Arrays.stream(e.getStackTrace()).filter((e1) -> e1.getClassName().contains("hr.flexi")).toList();
            String message;
            String param;
            if (!ste.isEmpty()) {
                StackTraceElement appEx = ste.get(0);
                message = parsedMessage + ">>" + e.getCause().getMessage();
                param = appEx.getFileName() + ":" + appEx.getLineNumber();
            } else {
                message = "Unknown runtime exception: " + e.getClass().getSimpleName();
                param = e.getMessage();
            }
            log.error("{}@{}::{}", e.getClass().getSimpleName(), param, e.getCause().getMessage());
            return new ErrorMessage(appErrCode, new Date(), message, e.getMessage(), "path");
        } else {
            return new ErrorMessage(HttpStatus.INTERNAL_SERVER_ERROR.value(), new Date(), e.getMessage(), e.getClass().getSimpleName(), "path");
        }
    }
}

