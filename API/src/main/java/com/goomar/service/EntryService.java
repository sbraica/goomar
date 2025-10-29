package com.goomar.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jooq.DSLContext;
import org.openapitools.model.ReservationRest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.jooq.generated.tables.Entries.ENTRIES;

@Service
@RequiredArgsConstructor
@Slf4j
public class EntryService implements IEntryService {
    final DSLContext ctx;

    @Override
    public int insertReservation(ReservationRest rr) {
        log.info(">>insertReservation({})", rr);
        if (rr.getId() == 0) {
            return ctx.insertInto(ENTRIES, ENTRIES.DATE_TIME, ENTRIES.USERNAME, ENTRIES.PHONE, ENTRIES.EMAIL, ENTRIES.REGISTRATION, ENTRIES.LONG_SERVICE, ENTRIES.CONFIRMED)
                    .values(rr.getDateTime(), rr.getUsername(), rr.getPhone(), rr.getEmail(), rr.getRegistration(), rr.getLongService(), false).returningResult(ENTRIES.ID).fetchOne().value1();
        } else {
            ctx.update(ENTRIES).set(ENTRIES.CONFIRMED, true).where(ENTRIES.ID.eq(rr.getId())).execute();
            return rr.getId();
        }
    }

    //TODO: duplicate?
    @Override
    public void createAppointment(int appId) {
        log.info(">>createAppointment({})", appId);
        ctx.update(ENTRIES).set(ENTRIES.CONFIRMED, true).where(ENTRIES.ID.eq(appId)).execute();
    }

    @Override
    public List<ReservationRest> getAppointments(String authorization, int year, int month, int day) {
        log.info(">>getAppointments(year={}, month={}, day={})", year, month, day);
        LocalDate date = LocalDate.of(year, month, day);
        LocalDateTime startOfWeek = date.atStartOfDay();
        LocalDateTime endOfWeek = date.plusDays(5).atStartOfDay();

        return ctx.select(ENTRIES.ID,
                          ENTRIES.USERNAME,
                          ENTRIES.DATE_TIME,
                          ENTRIES.EMAIL,
                          ENTRIES.PHONE,
                          ENTRIES.REGISTRATION,
                          ENTRIES.LONG_SERVICE,
                          ENTRIES.EMAIL,
                          ENTRIES.CONFIRMED)
                  .from(ENTRIES)
                  .where(ENTRIES.DATE_TIME.ge(startOfWeek).and(ENTRIES.DATE_TIME.lt(endOfWeek)))
                  .orderBy(ENTRIES.DATE_TIME.asc())
                  .fetchInto(ReservationRest.class);
    }
}
