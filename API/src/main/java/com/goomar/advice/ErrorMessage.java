package com.goomar.advice;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.Date;

@AllArgsConstructor
@Getter
public class ErrorMessage {
  private int status;
  private Date timestamp;
  private String message;
  private String error;
}