###
# uiCalendar - lightweight JS calendar pop-up
# @author Jiri Hybek <jiri.hybek@cryonix.cz> / Cryonix Innovations <www.cryonix.cz>
###

uiCalendar = (initialOptions) ->

	options = {}
	options[key] = val for key, val of initialOptions

	currentDate = null
	viewDate	= null
	
	startDate   = null
	endDate     = null
	hoverDate	= null

	closed = false

	monthViews = []

	# Date normalizer
	normalizeDate = (dt) ->
		dt.setHours(0)
		dt.setMinutes(0)
		dt.setSeconds(0)
		dt.setMilliseconds(0)

	# Date parser
	parseDate = (dateStr) ->
		if dateStr.indexOf(".") >= 0
			dateParts = dateStr.split(".").reverse()
		else if dateStr.indexOf("-") >= 0
			dateParts = dateStr.split("-")
		else
			throw "uiCalendar: Unsupported date format"

		if dateParts.length isnt 3 then throw "uiCalendar: Invalid date format"

		dt = new Date()
		dt.setFullYear	parseInt(dateParts[0].trim())
		dt.setMonth 	parseInt(dateParts[1].trim()) - 1
		dt.setDate		parseInt(dateParts[2].trim())

		normalizeDate(dt)
		return dt

	# Date formatter
	formatDate = (dt) ->
		if options.format is '-'
			return dt.getFullYear() + '-' + (dt.getMonth() + 1) + '-' + dt.getDate()
		else if options.format is '.'
			return dt.getDate() + '.' + (dt.getMonth() + 1) + '.' + dt.getFullYear()
		else
			throw "Invalid date format"

	# EL function
	uiEl = (tagName, attributes, contents, parent) ->
		el = document.createElement(tagName)
		el.setAttribute(key, val) for key, val of attributes || {}
		el.innerHTML = contents if contents isnt null
		parent.appendChild(el) if parent
		return el

	# Updates calendar
	update = () ->
		stopDate = new Date(viewDate.getTime())
		stopDate.setMonth( stopDate.getMonth() + options.monthCount - 1 )

		calLabel.innerHTML = options.monthLabels[viewDate.getMonth()] + ( if stopDate.getTime() isnt viewDate.getTime() then ' - ' + options.monthLabels[stopDate.getMonth()] else '' ) + ' ' + viewDate.getFullYear()

		view.update() for view in monthViews

	# Value setter
	setValue = () ->
		if options.range
			options.inputFrom.value = formatDate(startDate)
			options.inputTo.value   = formatDate(endDate)
		else
			options.input.value = formatDate(startDate)

		close() if options.closeOnSelect

	# Click handler
	handleClick = (colEl) ->
		return false if !options.allowPast and parseInt(colEl.getAttribute('data-time')) < currentDate.getTime()
		return false if !options.allowToday and parseInt(colEl.getAttribute('data-time')) is currentDate.getTime()
		return false if !options.allowFuture and parseInt(colEl.getAttribute('data-time')) > currentDate.getTime()
		return false if options.allowFrom and parseInt(colEl.getAttribute('data-time')) < options.allowFrom.getTime()
		return false if options.allowTo and parseInt(colEl.getAttribute('data-time')) > options.allowTo.getTime()

		if options.range
			if startDate is null or (startDate isnt null and endDate isnt null)
				startDate = new Date(parseInt(colEl.getAttribute('data-time')))
				endDate = null
			else if parseInt(colEl.getAttribute('data-time')) > startDate.getTime()
				endDate = new Date(parseInt(colEl.getAttribute('data-time')))
				setValue()

		else
			startDate = new Date(parseInt(colEl.getAttribute('data-time')))
			endDate = new Date(parseInt(colEl.getAttribute('data-time')))
			setValue()

	handleHover = (colEl) ->
		hoverDate = new Date(parseInt(colEl.getAttribute('data-time')))

	#Single month view
	monthView = (container, refDate) ->
		initialMonth = refDate.getMonth()

		refDate.setDate(1)
		refDate.setDate( 1 + (options.weekStart - refDate.getDay()) )

		normalizeDate(refDate)

		# Construct HTML
		viewEl = uiEl('table', { class : 'ui-calendar-month' }, null, container)
		headEl = uiEl('thead', {}, null, viewEl)
		bodyEl = uiEl('tbody', {}, null, viewEl)
		headTr = uiEl('tr', {}, null, headEl)

		columnList = []

		rowEl = uiEl('tr', {}, null, bodyEl)

		for c in [ 0 ... 35 ]
			# Heading
			uiEl('th', {}, options.dayLabels[refDate.getDay()], headTr) if c < 7
			
			# Column
			if refDate.getMonth() is initialMonth || options.fillSpaces
				colEl = uiEl('td', {}, refDate.getDate(), rowEl)
				colEl.setAttribute('data-time', refDate.getTime())

				# Bind events
				colEl.addEventListener "click", (ev) ->
					handleClick(ev.toElement || ev.target)
					update()

				colEl.addEventListener "mouseover", (ev) ->
					handleHover(ev.toElement || ev.target)
					update()

				columnList.push(colEl)

			# Fill
			else
				colEl = uiEl('td', { class: 'fill' }, '&nbsp;', rowEl)
				colEl.setAttribute('data-time', -1)

			# Move forward
			refDate.setDate( refDate.getDate() + 1 )

			if refDate.getDay() is options.weekStart
				rowEl = uiEl('tr', {}, null, bodyEl)

		# Update function
		view =
			update: () ->
				for colEl in columnList
					classes = []
					classes.push("past")  if parseInt(colEl.getAttribute('data-time')) < currentDate.getTime()
					classes.push("today")  if parseInt(colEl.getAttribute('data-time')) is currentDate.getTime()
					classes.push("future")  if parseInt(colEl.getAttribute('data-time')) > currentDate.getTime()
					classes.push("disabled") if (!options.allowToday and parseInt(colEl.getAttribute('data-time')) is currentDate.getTime()) or (!options.allowPast and parseInt(colEl.getAttribute('data-time')) < currentDate.getTime()) or (!options.allowFuture and parseInt(colEl.getAttribute('data-time')) > currentDate.getTime()) or (options.allowFrom and parseInt(colEl.getAttribute('data-time')) < options.allowFrom.getTime()) or (options.allowTo and parseInt(colEl.getAttribute('data-time')) > options.allowTo.getTime())
					classes.push("selected") if (startDate and parseInt(colEl.getAttribute('data-time')) is startDate.getTime()) or (startDate and endDate and parseInt(colEl.getAttribute('data-time')) >= startDate.getTime() and parseInt(colEl.getAttribute('data-time')) <= endDate.getTime())
					classes.push("selection") if startDate and !endDate and hoverDate and parseInt(colEl.getAttribute('data-time')) > startDate.getTime() and parseInt(colEl.getAttribute('data-time')) < hoverDate.getTime()

					colEl.setAttribute('class', classes.join(" "))

			destroy: () -> viewEl.parentElement.removeChild(viewEl)			

	rebuildViews = (container, initialDate) ->
		view.destroy() for view in monthViews
		monthViews = []

		for i in [0 ... options.monthCount || 1]
			dt = new Date(initialDate.getTime())
			dt.setMonth( dt.getMonth() + i )

			monthViews.push monthView(calWrapper, dt)

		update()

	close = () ->
		calWrapper.parentElement.removeChild(calWrapper) if !closed
		closed = true

	### INIT ###

	# Merge options
	options.weekStart = 1 if options.weekStart is undefined
	options.monthOffset = 1 if options.monthOffset is undefined
	options.monthCount = 1 if options.monthCount is undefined
	options.format = '-' if options.format is undefined
	options.dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] if !options.dayLabels
	options.monthLabels = ["January", "February", "March", "April", "May", "Jun", "July", "August", "September", "October", "November", "December"] if !options.monthLabels

	options.closeOnSelect = false 	if options.closeOnSelect is undefined
	options.closeOnBlur   = false 	if options.closeOnBlur is undefined

	options.range 		= false 	if options.range is undefined
	options.fillSpaces 	= true 		if options.fillSpaces is undefined
	options.allowFuture = true 		if options.allowFuture is undefined
	options.allowToday  = true 		if options.allowToday is undefined
	options.allowPast 	= true 		if options.allowPast is undefined
	options.allowFrom 	= if options.allowFrom then parseDate(options.allowFrom) else null
	options.allowTo 	= if options.allowTo   then parseDate(options.allowTo)   else null

	# Setup current date
	currentDate = new Date()
	normalizeDate(currentDate)

	startDate = parseDate(options.startDate) if options.startDate
	endDate   = parseDate(options.endDate)   if options.endDate

	viewDate = if options.initidalDate then parseDate(options.initidalDate) else new Date()

	# Validate config
	if options.range
		if !options.inputFrom or !options.inputTo then throw "Input fields (from & to) are not defined!"
		if options.inputFrom.value.trim() isnt "" and options.inputTo.value.trim() isnt ""
			startDate = parseDate(options.inputFrom.value)
			endDate = parseDate(options.inputTo.value)
			viewDate = new Date(startDate)

	else
		if !options.input then throw "Input field are not defined!"
		if options.input.value.trim() isnt ""
			startDate = parseDate(options.input.value)
			endDate = new Date(startDate)
			viewDate = new Date(startDate)

	# Setup container
	calWrapper = uiEl('div', { class: 'ui-calendar' }, null, options.container)

	calHeader = uiEl('div', { class: 'ui-calendar-header' }, null, calWrapper)
	calBody   = uiEl('div', { class: 'ui-calendar-body'}, null, calWrapper)

	calPrev   = uiEl('span', { class: 'ui-calendar-prev' }, '◄', calHeader)
	calNext   = uiEl('span', { class: 'ui-calendar-next' }, '►', calHeader)
	calLabel  = uiEl('span', { class: 'ui-calendar-label' }, null, calHeader)

	# Bind events
	calPrev.addEventListener "click", () ->
		viewDate.setMonth( viewDate.getMonth() - 1 )
		rebuildViews(calBody, viewDate)

	calNext.addEventListener "click", () ->
		viewDate.setMonth( viewDate.getMonth() + 1 )
		rebuildViews(calBody, viewDate)

	calWrapper.addEventListener "click", (ev) ->
		ev.stopPropagation()
		ev.preventDefault()
		return false

	document.body.addEventListener "click", (ev) ->
		if options.closeOnBlur then close()

	# Build month views
	rebuildViews(calBody, viewDate)

	# Position if pop-up
	if options.popup
		alignmentEl = options.input || options.inputFrom

		originX = alignmentEl.offsetLeft + Math.round(alignmentEl.offsetWidth / 2)
		originY = alignmentEl.offsetTop + Math.round(alignmentEl.offsetHeight / 2)

		position = 0 # 0 = top, 1 = right, 2 = bottom, 3 = left

		if originY - calWrapper.offsetHeight < 0
			position = 1
		if position is 1 and originX + calWrapper.offsetWidth > document.body.clientWidth
			position = 2
		if position is 2 and originY + calWrapper.offsetHeight > document.body.clientHeight
			position = 3

		switch position
			when 0
				calWrapper.style.left = (originX - Math.round(calWrapper.offsetWidth / 2)) + 'px'
				calWrapper.style.top = (originY - calWrapper.offsetHeight - alignmentEl.offsetHeight - 5) + 'px'
				calWrapper.classList.add('ui-calendar-arrow-bot')
			when 1
				calWrapper.style.left = (originX + Math.round(alignmentEl.offsetWidth / 2) + 20) + 'px'
				calWrapper.style.top = (originY - Math.round(calWrapper.offsetHeight / 2)) + 'px'
				calWrapper.classList.add('ui-calendar-arrow-left')
			when 2
				calWrapper.style.left = (originX - Math.round(calWrapper.offsetWidth / 2)) + 'px'
				calWrapper.style.top = (originY + alignmentEl.offsetHeight + 5) + 'px'
				calWrapper.classList.add('ui-calendar-arrow-top')
			when 3
				calWrapper.style.left = (originX - Math.round(alignmentEl.offsetWidth / 2) - calWrapper.offsetWidth - 20) + 'px'
				calWrapper.style.top = (originY - Math.round(calWrapper.offsetHeight / 2)) + 'px'
				calWrapper.classList.add('ui-calendar-arrow-right')

		calWrapper.classList.add('ui-calendar-arrow')
		calWrapper.classList.add('ui-calendar-popup')

	# Return interface
	return {
		getStartDate: () -> return startDate
		getEndDate: () -> return endDate
		close: () -> return close()
		isClosed: () -> return closed
	}

uiCalendarAuto = (selector, options = {}) ->
	
	bindCalendar = (el) ->
		localOptions = {}
		localOptions[key] = value for key, value of options

		localOptions.closeOnSelect = true
		localOptions.closeOnBlur = true
		localOptions.container = document.body
		localOptions.popup = true

		if options.range
			localOptions.inputFrom = el.querySelector(localOptions.fromSelector || ".start")
			localOptions.inputTo   = el.querySelector(localOptions.toSelector || ".end")
		else
			localOptions.input = el

		cal = null

		for subEl in [localOptions.input, localOptions.inputFrom, localOptions.inputTo]
			continue if !subEl

			subEl.addEventListener "focus", () ->
				cal = uiCalendar(localOptions) if !cal or (cal and cal.isClosed())

			subEl.addEventListener "click", (ev) ->
				ev.stopPropagation()
				ev.preventDefault()
				return false

			subEl.addEventListener "keydown", (ev) ->
				if ev.keyCode is 27 and cal then cal.close()

			subEl.classList.add('ui-calendar-input')
			subEl.setAttribute('pattern', '^([0-9]{1,2}\.(\ )?[0-9]{1,2}\.(\ )?[0-9]{4}|[0-9]{4}-[0-9]{1,2}-[0-9]{1,2})$')

	elements = (options.parent || document).querySelectorAll(selector)
	bindCalendar(el) for el in elements