package com.goomar.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.openapitools.model.EntriesPostRequest;
import org.springframework.stereotype.Service;
import org.jooq.DSLContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.jooq.generated.tables.Entries.ENTRIES;

@Service
@RequiredArgsConstructor
@Slf4j
public class EntryService implements IEntryService {
    final DSLContext ctx;

    @Override
    public void entriesPost(EntriesPostRequest er) {
        log.info(">>cuUser({})", er);
        LocalDate date = er.getDate();
        LocalTime time = LocalTime.parse(er.getTime());
        LocalDateTime timestamp = LocalDateTime.of(date, time);
        ctx.insertInto(ENTRIES, ENTRIES.STAMP).values(timestamp).execute();
    }
}
