log (current date)

set sourceCalendarTitle to "Source Calendar"
set destinationCalendarTitle to "Destination Calendar"
set ignoreTitles to {"Busy", "busy", "Reservation", "WFH", "Working from Home", "Vacation"}

tell application "Calendar"
	set destinationCalendar to (first calendar where its title = destinationCalendarTitle)
	set sourceCalendar to (first calendar where its title = sourceCalendarTitle)
	
	-- Get lists of source items
	log "Getting source events..."
	set {sourceStamps, sourceTitles, sourceUids, sourceEndDates} to {stamp date, summary, uid, end date} of (events of sourceCalendar)
	
	-- Get lists of destination items
	log "Getting destination events..."
	set {destUids, destStamps, destTitles, destLocalUids} to {description, stamp date, summary, uid} of events of destinationCalendar
	
	log "Comparing source and destination events..."
	repeat with iSrc from 1 to count sourceUids
		-- log {"Processing event ", iSrc}
		if (ignoreTitles contains item iSrc of sourceTitles) or (item iSrc in sourceEndDates is less than ((current date) - 2629743)) then
			-- log {"Ignoring event", item iSrc of sourceTitles}
			set matchFound to true
		else
			set matchFound to false
			set srcModDate to item iSrc in sourceStamps
			if srcModDate = missing value then
				set srcModDate to ((current date) - 2629743)
			end if
			repeat with iDest from 1 to count of destUids
				if item iDest of destUids is equal to item iSrc of sourceUids then
					-- log {"found UID", iDest}
					set destModDate to item iDest in destStamps
					if srcModDate is less than destModDate then
						-- log {"in sync", (item iSrc in sourceTitles)}
						set matchFound to true
					else
						log {"Deleting old event", (item iSrc in sourceTitles)}
						-- Delete destination event
						-- delete event id (item iDest of destLocalUids) of destinationCalendar
						delete (events of destinationCalendar whose description = (item iDest of destUids))
					end if
					exit repeat
				end if
			end repeat
		end if
		
		-- Create new event
		if not matchFound then
			log {"Creating new event", item iSrc in sourceTitles}
			set srcEvent to (first event of sourceCalendar where its uid = item iSrc of sourceUids)
			if summary of srcEvent = missing value then
				set srcSummary to ""
			else
				set srcSummary to summary of srcEvent
			end if
			make new event at destinationCalendar with properties {summary:item iSrc in sourceTitles, start date:start date of srcEvent, end date:end date of srcEvent, description:item iSrc in sourceUids, allday event:allday event of srcEvent, excluded dates:excluded dates of srcEvent}
			set newEvent to (first event of destinationCalendar where its description = uid of srcEvent)
			if location of srcEvent is not equal to missing value then
				set location of newEvent to location of srcEvent
			end if
			if url of srcEvent is not equal to missing value then
				set url of newEvent to url of srcEvent
			end if
			if recurrence of srcEvent is not equal to missing value then
				set recurrence of newEvent to recurrence of srcEvent
			end if
		end if
	end repeat
	
	-- Remove events that do not exist in source calendar
	repeat with iDest from 1 to count destUids
		if not (sourceUids contains (item iDest in destUids)) then
			-- Delete destination event
			log {"Deleting destination event", (item iDest in destTitles)}
			delete (events of destinationCalendar whose description = item iDest of destUids)
		end if
	end repeat
	
	log "Processing complete."
end tell