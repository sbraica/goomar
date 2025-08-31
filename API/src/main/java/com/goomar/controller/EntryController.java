package com.goomar.controller;

import com.goomar.service.IEntryService;
import lombok.RequiredArgsConstructor;
import org.openapitools.api.EntriesApi;
import org.openapitools.model.EntriesPostRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
public class EntryController implements EntriesApi {
    private final IEntryService entryService;
    @Override
    public ResponseEntity<Void> entriesPost(EntriesPostRequest entriesPostRequest) {
        entryService.entriesPost(entriesPostRequest);
        return new ResponseEntity(HttpStatus.CREATED);
    }
}
