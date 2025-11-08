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
    public UUID insertReservation(ReservationRest rr) {
        log.info(">>insertReservation(id={})", rr.getId());
        return ctx.insertInto(ENTRIES, ENTRIES.DATE_TIME, ENTRIES.NAME, ENTRIES.PHONE, ENTRIES.EMAIL, ENTRIES.REGISTRATION, ENTRIES.LONG, ENTRIES.CONFIRMED, ENTRIES.EMAIL_OK)
                    .values(rr.getDateTime(), rr.getName(), rr.getPhone(), rr.getEmail(), rr.getRegistration(), rr.getLong(), false, false).returningResult(ENTRIES.ID).fetchOne().value1();
    }



    @Override
    public List<ReservationRest> getAppointments(int year, int month, int day) {
        log.info(">>getAppointments(year={}, month={}, day={})", year, month, day);
        LocalDate date = LocalDate.of(year, month, day);
        LocalDateTime startOfWeek = date.atStartOfDay();
        LocalDateTime endOfWeek = date.plusDays(5).atStartOfDay();

        return ctx.select(ENTRIES.ID, ENTRIES.NAME, ENTRIES.DATE_TIME, ENTRIES.EMAIL, ENTRIES.PHONE, ENTRIES.REGISTRATION, ENTRIES.LONG, ENTRIES.EMAIL, ENTRIES.CONFIRMED, ENTRIES.EVENT_ID, ENTRIES.CONFIRMED)
                  .from(ENTRIES).where(ENTRIES.EMAIL_OK.eq(true).and(ENTRIES.DATE_TIME.ge(startOfWeek).and(ENTRIES.DATE_TIME.lt(endOfWeek)))).orderBy(ENTRIES.DATE_TIME.asc()).fetchInto(ReservationRest.class);
    }

    @Override
    public String confirmEmailOK(String token) {
        log.info(">>confirmEmailOK(token={})", token);
        ctx.update(ENTRIES).set(ENTRIES.EMAIL_OK, true).where(ENTRIES.ID.eq(UUID.fromString(token))).execute();
        return "<html><body><h2>Rezervacija potvrđena!</h2></body></html>";
    }

    @Override
    public ReservationRest makeAppointment(String id) {
        log.info(">>makeAppointment(id={})", id);
        return ctx.update(ENTRIES).set(ENTRIES.CONFIRMED, true).where(ENTRIES.ID.eq(UUID.fromString(id))).returning().fetchOneInto(ReservationRest.class);
    }

    @Override
    public ReservationRest deleteAppoitnment(String id) {
        log.info(">>deleteAppoitnment(id={})", id);
        return ctx.deleteFrom(ENTRIES).where(ENTRIES.ID.eq(UUID.fromString(id))).returning().fetchOneInto(ReservationRest.class);
    }

    @Override
    public void setEventId(String id, String eventId) {
        log.info(">>setEventId(id={}, eventId={})", id, eventId);
        ctx.update(ENTRIES).set(ENTRIES.EVENT_ID, eventId).where(ENTRIES.ID.eq(UUID.fromString(id))).execute();
    }

}
