package com.goomar.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jooq.DSLContext;
import org.openapitools.model.ReservationRest;
import org.springframework.stereotype.Service;

import static org.jooq.generated.tables.Entries.ENTRIES;

@Service
@RequiredArgsConstructor
@Slf4j
public class EntryService implements IEntryService {
    final DSLContext ctx;

    @Override
    public int insertReservation(ReservationRest rr) {
        log.info(">>cuVehicle({})", rr);
        if (rr.getId() == 0) {
            return ctx.insertInto(ENTRIES, ENTRIES.DATE_TIME, ENTRIES.USERNAME, ENTRIES.PHONE, ENTRIES.EMAIL, ENTRIES.REGISTRATION, ENTRIES.LONG_SERVICE, ENTRIES.CONFIRMED)
                    .values(rr.getDate(), rr.getUsername(), rr.getPhone(), rr.getEmail(), rr.getRegistration(), rr.getLongService(), false).returningResult(ENTRIES.ID).fetchOne().value1();
        } else {
            ctx.update(ENTRIES).set(ENTRIES.CONFIRMED, true).where(ENTRIES.ID.eq(rr.getId())).execute();
            return rr.getId();
        }
    }
}
