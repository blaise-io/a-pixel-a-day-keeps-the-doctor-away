fs = require('fs')
sys = require('sys')
child_process = require('child_process')

try
    config = require('./config.js')
    config.startDate = config.startDate or new Date()
catch
    console.log('Copy config.example.coffee to config.coffee and'
                'adjust to match your environment.')
    process.exit(1)


class Main

    FONT: JSON.parse(fs.readFileSync(__dirname + '/font.json'))
    NOW: new Date()
    LETTER_SPACING: 1
    DAY_DURATION_MS: 3600 * 24 * 1000
    DAYS_IN_WEEK: 7
    WEEKS_IN_YEAR: 51
    TEXT_CHARS: [' ', '#']

    constructor: () ->
        @validateConfig()

        @duration = @getDurationInDays()
        @progress = @getDayProgress()

        @reportPotentialOverflow()
        @checkOutputDir()
        @checkRepository()
        @checkStarted()
        @checkDone()

        @collectPixels()
        if @paintToday
            @writePixelsToFile()
            @commitPixelFile()

        @reportProgress()

    validateConfig: ->
        @detectMissingInput()
        @detectInvalidDate()
        @forceStartOnSunday()
        @detectMissingChars()

    detectMissingInput: ->
        if not config.graphText
            console.log("Usage: node pixel.js <text> [<start>]")
            console.log("Example: node pixel.js 'Ni Hao' '2014-06-29 00:00:00'")
            process.exit(1)

    detectInvalidDate: ->
        # Node will exit when it cannot parse a date.
        @startDate = new Date(config.startDate)

    detectMissingChars: ->
        missingChars = ''
        for i in [0..config.graphText.length - 1]
            if not @FONT[config.graphText.charAt(i)]
                missingChars += charAt(i)
        if missingChars
            console.log("These characters are not in font.json: #{missingChars}")
            process.exit(1)

    forceStartOnSunday: ->
        startDayInt = @startDate.getDay()
        if 0 isnt startDayInt
            shiftDays = @DAYS_IN_WEEK - startDayInt
            console.log("Shifted start day #{shiftDays} days to start on a Sunday.")
            @startDate = new Date(+@startDate + (shiftDays * @DAY_DURATION_MS))

    checkOutputDir: ->
        if not fs.existsSync(config.outputDir)
            fs.mkdirSync(config.outputDir)
        config.outputDir = fs.realpathSync(config.outputDir) + '/'

    checkRepository: ->
        if not fs.existsSync(config.outputDir + config.outputFile)
            cmd = [
                "#{__dirname}/setup.sh",
                JSON.stringify(config.outputDir),
                JSON.stringify(config.repository),
                JSON.stringify(config.userName),
                JSON.stringify(config.userEmail),
            ]
            child_process.exec(cmd.join(' '), @captureLog);

    checkStarted: ->
        if @NOW < @startDate
            console.log("Not starting yet, will start #{@startDate}.")
            process.exit(0)

    checkDone: ->
        @done = @progress > @duration
        if @done
            console.log("Done for #{@progress - @duration} days.")
            process.exit(0)

    getDurationInDays: ->
        days = 0
        for i in [0..config.graphText.length - 1]
            letter = config.graphText.charAt(i)
            days += @FONT[letter].width * @DAYS_IN_WEEK
        days += @DAYS_IN_WEEK * @LETTER_SPACING * (config.graphText.length - 1)
        return days

    getDayProgress: ->
        return Math.floor((+@NOW - @startDate) / @DAY_DURATION_MS)

    reportPotentialOverflow: ->
        durationWeeks = Math.ceil(@duration / @DAYS_IN_WEEK)
        if @WEEKS_IN_YEAR < durationWeeks
            console.log("Complete text takes #{durationWeeks} weeks,"
                        "history chart shows #{@WEEKS_IN_YEAR} full weeks.")

    collectPixels: ->
        @pointer = 0
        @daysInLetter = 0
        @indexPrev = 0
        @paintToday = false
        @pixels = []

        while @pointer <= @progress
            @collectPixel()
            @pointer++
            @daysInLetter++

    collectPixel: ->
        index = @getLetterIndexForDay(@pointer)

        if index isnt @indexPrev
            @daysInLetter = 0
        @indexPrev = index

        @letter = config.graphText.charAt(index)

        x = Math.floor(@daysInLetter / @DAYS_IN_WEEK)
        y = @daysInLetter % @DAYS_IN_WEEK

        @pixels[y] = @pixels[y] || ''

        @paintToday = @isLetterPixel(@letter, x, y)
        @pixels[y] += @TEXT_CHARS[+@paintToday]

    getLetterIndexForDay: (day) ->
        letterPointer = 0
        for i in [0..config.graphText.length - 1]
            letter = config.graphText.charAt(i)
            letterPointer += @FONT[letter].width
            if i isnt config.graphText.length - 1
                letterPointer += @LETTER_SPACING
            if letterPointer * @DAYS_IN_WEEK >= day
                return i
            i++

    isLetterPixel: (letter, x, y) ->
        pixels = @FONT[letter].pixels
        if pixels[y] and -1 isnt pixels[y].indexOf(x)
            return true
        return false

    reportProgress: ->
        console.log("Writing string: #{config.graphText}")
        console.log("Day #{@progress} of #{@duration}.")
        console.log("Currently painting letter: #{@letter}")
        if @paintToday
            console.log("Today we paint!")

    writePixelsToFile: ->
        str = ''
        for line in @pixels
            str += "#{line}\n"
        console.log('---')
        console.log(str)
        console.log('---')
        fs.writeFileSync(config.outputDir + config.outputFile, str + new Date())

    captureLog: () ->
        (console.log("shell: #{arg}") if arg) for arg in arguments

    commitPixelFile: ->
        cmd = [
            "#{__dirname}/commit.sh",
            JSON.stringify(config.outputDir),
            JSON.stringify(config.outputFile),
            JSON.stringify(config.commitMessage)
        ]

        child_process.exec(cmd.join(' '), @captureLog);

new Main()
