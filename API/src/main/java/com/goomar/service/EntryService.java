package com.goomar.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jooq.DSLContext;
import org.openapitools.model.ReservationRest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.jooq.generated.tables.Entries.ENTRIES;

@Service
@RequiredArgsConstructor
@Slf4j
public class EntryService implements IEntryService {
    final DSLContext ctx;

    @Override
    public UUID insertReservation(ReservationRest rr, String eventId) {
            return ctx.insertInto(ENTRIES, ENTRIES.DATE_TIME, ENTRIES.USERNAME, ENTRIES.PHONE, ENTRIES.EMAIL, ENTRIES.REGISTRATION, ENTRIES.LONG_SERVICE, ENTRIES.CONFIRMED, ENTRIES.EVENT_ID, ENTRIES.EMAIL_OK)
                    .values(rr.getDateTime(), rr.getUsername(), rr.getPhone(), rr.getEmail(), rr.getRegistration(), rr.getLongService(), false, eventId, false).returningResult(ENTRIES.ID).fetchOne().value1();
    }



    @Override
    public List<ReservationRest> getAppointments(String authorization, int year, int month, int day) {
        log.info(">>getAppointments(year={}, month={}, day={})", year, month, day);
        LocalDate date = LocalDate.of(year, month, day);
        LocalDateTime startOfWeek = date.atStartOfDay();
        LocalDateTime endOfWeek = date.plusDays(5).atStartOfDay();

        return ctx.select(ENTRIES.ID, ENTRIES.USERNAME, ENTRIES.DATE_TIME, ENTRIES.EMAIL, ENTRIES.PHONE, ENTRIES.REGISTRATION, ENTRIES.LONG_SERVICE, ENTRIES.EMAIL, ENTRIES.CONFIRMED, ENTRIES.EVENT_ID, ENTRIES.CONFIRMED)
                  .from(ENTRIES).where(ENTRIES.DATE_TIME.ge(startOfWeek).and(ENTRIES.DATE_TIME.lt(endOfWeek))).orderBy(ENTRIES.DATE_TIME.asc()).fetchInto(ReservationRest.class);
    }

    @Override
    public String getConfirmation(String token) {
        return "<html><body><h2>Rezervacija potvrđena!</h2></body></html>";
    }

    @Override
    public ReservationRest confirmReservation(String eventId) {
        return ctx.update(ENTRIES).set(ENTRIES.EMAIL_OK, true).where(ENTRIES.EVENT_ID.eq(eventId)).returning().fetchOneInto(ReservationRest.class);
    }

    @Override
    public ReservationRest deleteAppoitnment(String eventId) {
        return ctx.deleteFrom(ENTRIES).where(ENTRIES.EVENT_ID.eq(eventId)).returning().fetchOneInto(ReservationRest.class);
    }

}
