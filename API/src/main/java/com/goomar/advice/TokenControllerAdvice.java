package com.goomar.advice;

import lombok.extern.slf4j.Slf4j;
import org.apache.logging.log4j.util.Strings;
import org.postgresql.util.PSQLException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.io.FileWriter;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class TokenControllerAdvice {

    public static final int APP_ERR_CODE_SQL_UNKNOWN = 1000;
    public static final int APP_ERR_CODE_SQL_DUPLICATE = 1001;
    public static final int APP_ERR_CODE_SQL_HAS_RELATED = 1002;
    public static final int APP_ERR_CODE_SQL_CANNOT_DELETE = 1003;
    public static final int APP_ERR_CODE_MAIL_ERROR = 1004;

    public static final int APP_ERR_CODE_INVALID_CREDENTIALS = 2001;
    private static final String APP_PACKAGE = "com.goomar";


    @ExceptionHandler(value = BadCredentialsException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public ErrorMessage handleUnathorized(BadCredentialsException ex) {
        final Matcher matcher = Pattern.compile("\\[Field.*?\\;").matcher(ex.getMessage());
        String parsedMessage = "";
        if (matcher.find()) {
            parsedMessage = matcher.group(0);
        }
        return new ErrorMessage(HttpStatus.UNAUTHORIZED.value(), new Date(), parsedMessage, ex.getMessage());
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
            return new ErrorMessage(appErrCode, new Date(), "message", e.getMessage());
        } else {
            log.error("Exception: " + saveExceptionToFile(e));
            return new ErrorMessage(HttpStatus.INTERNAL_SERVER_ERROR.value(), new Date(), e.getMessage(), e.getClass().getSimpleName());
        }
    }

    private String saveExceptionToFile(Exception ex) {
        try {
            Path logDir = Path.of("/app/logs");
            Files.createDirectories(logDir);

            Path logFile = logDir.resolve("exception-" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss")) + ".log");

            try (FileWriter fw = new FileWriter(logFile.toFile(), true);
                 PrintWriter pw = new PrintWriter(fw)) {
                pw.println("==== Exception at " + LocalDateTime.now() + " ====");
                ex.printStackTrace(pw);
                pw.println();
            }

            for (StackTraceElement element : ex.getStackTrace()) {
                if (element.getClassName().startsWith(APP_PACKAGE)) {
                    return element + " >> "+ logFile.getFileName();
                }
            }
            return "? >> "+ logFile.getFileName();
        } catch (Exception e) {
            log.error("Failed to write exception stacktrace: {}", e.getMessage());
        }
        return "? >> ?";

    }
}

