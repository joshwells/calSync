set theStartDate to (current date) - (1 * days)
set hours of theStartDate to 0
set minutes of theStartDate to 0
set seconds of theStartDate to 0
set theEndDate to theStartDate + (1 * days)

set sourceCalendarTitle to "Source Calendar"
set destinationCalendarTitle to "Destination Calendar"
set ignoreTitles to {"Busy", "busy", "Reservation"}

tell application "Calendar"
	set destinationCalendar to (first calendar where its title = destinationCalendarTitle)
	set sourceCalendar to (first calendar where its title = sourceCalendarTitle)
	
	-- Get lists of source items
	log "Getting source events..."
	set sourceEvents to (every event of sourceCalendar)
	set sourceUids to uid of (every event of sourceCalendar)
	set sourceStamps to stamp date of (every event of sourceCalendar)
	set sourceTitles to summary of (every event of sourceCalendar)
	
	-- Get lists of destination items
	log "Getting destination events..."
	set destEvents to (every event of destinationCalendar)
	set destUids to description of (every event of destinationCalendar)
	set destStamps to stamp date of (every event of destinationCalendar)
	set destTitles to summary of (every event of destinationCalendar)
	
	log "Comparing source and destination events..."
	repeat with iSrc from 1 to count sourceUids
		log {"Processing event ", iSrc}
		if ignoreTitles contains item iSrc of sourceTitles then
			log {"Ignoring event", item iSrc of sourceTitles}
			set matchFound to true
		else
			set matchFound to false
			repeat with iDest from 1 to count of destUids
				if item iDest of destUids is equal to item iSrc of sourceUids then
					log {"found UID", iDest}
					if item iSrc in sourceStamps is less than item iDest in destStamps then
						log {"in sync", (item iSrc in sourceTitles)}
						set matchFound to true
					else
						log {"Deleting old event", (item iSrc in sourceTitles)}
						-- Delete destination event
						log {"before", item iDest in destEvents}
						delete item iDest in destEvents
						log {"after", item iDest in destEvents}
					end if
					exit repeat
				end if
			end repeat
		end if
		
		-- Create new event
		if not matchFound then
			log {"Creating new event", item iSrc in sourceTitles}
			if summary of (item iSrc in sourceEvents) = missing value then
				set srcSummary to ""
			else
				set srcSummary to summary of (item iSrc in sourceEvents)
			end if
			make new event at destinationCalendar with properties {summary:srcSummary, start date:start date of (item iSrc in sourceEvents), end date:end date of (item iSrc in sourceEvents), description:uid of (item iSrc in sourceEvents), allday event:allday event of (item iSrc in sourceEvents), excluded dates:excluded dates of (item iSrc in sourceEvents)}
			set newEvent to (first event of destinationCalendar where its description = uid of (item iSrc in sourceEvents))
			if location of (item iSrc in sourceEvents) is not equal to missing value then
				set location of newEvent to location of (item iSrc in sourceEvents)
			end if
			if url of (item iSrc in sourceEvents) is not equal to missing value then
				set url of newEvent to url of (item iSrc in sourceEvents)
			end if
			if recurrence of (item iSrc in sourceEvents) is not equal to missing value then
				set recurrence of newEvent to recurrence of (item iSrc in sourceEvents)
			end if
		end if
	end repeat
	
	-- Remove events that do not exist in source calendar
	repeat with iDest from 1 to count destUids
		if not (sourceUids contains (item iDest in destUids)) then
			-- Delete destination event
			log {"Deleting destination event", (item iDest in destTitles)}
			delete item iDest in destEvents
		end if
	end repeat
end tell