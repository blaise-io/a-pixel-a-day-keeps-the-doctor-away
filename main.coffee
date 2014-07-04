fs = require('fs')
sys = require('sys')
child_process = require('child_process')

try
    config = require('./config.js')
catch
    console.log("Copy config.example.coffee to config.coffee and" +
                "adjust to match your environment.")
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
        @detectMissingChars()

        @progress = 0
        @duration = @getDurationInDays()
        @startDate = @getStartDate()

        @reportPotentialOverflow()
        @setupOutputDir()
        @repoInit(( ->
            @captureLog.apply(this, arguments)
            @paintDay()
        ).bind(this))

    getStartDate: ->
        today = new Date()
        weekDayInt = today.getDay()
        daysBack = @duration + weekDayInt
        return new Date(+today - (daysBack * @DAY_DURATION_MS))

    detectMissingChars: ->
        missingChars = ''
        for i in [0..config.graphText.length - 1]
            if not @FONT[config.graphText.charAt(i)]
                missingChars += charAt(i)
        if missingChars
            console.log("These characters are not in font.json: #{missingChars}")
            process.exit(1)

    setupOutputDir: ->
        if not fs.existsSync(config.outputDir)
            fs.mkdirSync(config.outputDir)
        config.outputDir = fs.realpathSync(config.outputDir) + '/'

    getDurationInDays: ->
        days = 0
        for i in [0..config.graphText.length - 1]
            letter = config.graphText.charAt(i)
            days += @FONT[letter].width * @DAYS_IN_WEEK
        days += @DAYS_IN_WEEK * @LETTER_SPACING * (config.graphText.length - 1)
        return days

    reportPotentialOverflow: ->
        durationWeeks = Math.ceil(@duration / @DAYS_IN_WEEK)
        if @WEEKS_IN_YEAR < durationWeeks
            console.log("Complete text takes #{durationWeeks} weeks, " +
                        "history chart shows #{@WEEKS_IN_YEAR} full weeks.")
            process.exit(1)

    paintDay: ->
        if (@progress <= @duration)
            @collectPixels()
            if @paintToday
                @writePixelsToFile()
                @repoCommit((() ->
                    @captureLog.apply(this, arguments)
                    @progress++
                    @paintDay()
                ).bind(this))
            else
                @progress++
                @paintDay()
        else
            @repoPush(@done.bind(this))

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
        if @paintToday
            @x = Math.floor(@pointer / @DAYS_IN_WEEK)
            @y = y

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

    getDateForLastPixel: () ->
        xyInDays = @x * @DAYS_IN_WEEK + @y
        return new Date(+@startDate + (xyInDays * @DAY_DURATION_MS))

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
        fs.writeFileSync(config.outputDir + config.outputFile, str)

    captureLog: () ->
        (console.log("shell: #{arg}") if arg) for arg in arguments

    repoInit: (callbackFn) ->
        cmd = [
            "#{__dirname}/shell/init.sh",
            JSON.stringify(config.outputDir),
            JSON.stringify(config.repository),
            JSON.stringify(config.userEmail),
            JSON.stringify(config.userName)
        ]
        child_process.exec(cmd.join(' '), callbackFn);

    repoCommit: (callbackFn) ->
        date = @getDateForLastPixel()
        date.setHours(11, 0, 0, 0);
        console.log(date)
        cmd = [
            "#{__dirname}/shell/commit.sh",
            JSON.stringify(config.outputDir),
            JSON.stringify(config.outputFile),
            JSON.stringify(config.commitMessage),
            JSON.stringify(String(date))
        ]
        child_process.exec(cmd.join(' '), callbackFn);

    repoPush: (callbackFn) ->
        cmd = [
            "#{__dirname}/shell/push.sh",
            JSON.stringify(config.outputDir)
        ]
        child_process.exec(cmd.join(' '), callbackFn);

    done: () ->
        @captureLog.apply(this, arguments)
        console.log('Done!')

new Main()
