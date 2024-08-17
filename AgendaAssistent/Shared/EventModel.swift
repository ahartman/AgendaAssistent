//
//  EventModel.swift
//  AgendaAssistent
//
//  Created by André Hartman on 04/01/2024.
//  Copyright © 2024 André Hartman. All rights reserved.
import EventKit

class EventModel {
    func getCalendarEvents(dates: Period.PeriodStartEnd, eventStore: EKEventStore) -> [EKEvent] {
        var calendarEvents = [EKEvent]()
        let selectedCalendars: [EKCalendar] = eventStore.calendars(for: .event).filter { $0.title.contains("Marieke") && !$0.title.contains("blokkeren")}
        let predicate = eventStore.predicateForEvents(withStart: dates.start, end: dates.end, calendars: selectedCalendars)
        calendarEvents = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
        if debugPrint { print("calendarEvents: \(calendarEvents.count)") }
        return calendarEvents
    }
}
