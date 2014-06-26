fs = require('fs')

DAY_MS = 3600 * 24 * 1000;
DAYS_IN_WEEK = 7

WRITE = process.env.ONE_PIXEL_WRITE
WEEKS_YEAR = 51

FONT = JSON.parse(fs.readFileSync(__dirname + '/font.json'))
SPACE_WIDTH = 1


getNumPaintDays = () ->
    days = 0
    for i in [0..WRITE.length - 1]
        letter = WRITE.charAt(i)
        days += (FONT[letter].width + SPACE_WIDTH) * DAYS_IN_WEEK
    return days


getLetterForDay = (day) ->
    letterPointer = 0
    for i in [0..WRITE.length - 1]
        letter = WRITE.charAt(i)
        letterPointer += FONT[letter].width
        letterPointer += SPACE_WIDTH
        if letterPointer * DAYS_IN_WEEK >= day
            return letter
        i++

isLetterPixel = (letter, x, y) ->
    pixels = FONT[letter].pixels
    if pixels[y] and -1 isnt pixels[y].indexOf(x)
        return true
    return false


main = ->
    start = new Date(String(fs.readFileSync(__dirname + '/start.txt')).trim())
    now = +new Date()

    numPaintDays = getNumPaintDays()

    day = Math.floor((now - start) / DAY_MS) + 1;

    console.log("Writing str     : #{WRITE}")
    console.log("Columns         : #{numPaintDays / DAYS_IN_WEEK}")
    console.log("Fits            : #{numPaintDays / DAYS_IN_WEEK <= WEEKS_YEAR}")
    console.log("Started on      : #{start}")
    console.log("Starts on Sunday: #{start.getDay() is 0}")
    console.log("Progress        : #{day} of #{numPaintDays}")

    daysInLetter = 0

    TMP = []

    while day <= numPaintDays
        letter = getLetterForDay(day)

        x = Math.floor(daysInLetter / DAYS_IN_WEEK)
        y = day % DAYS_IN_WEEK

        if x > FONT[letter].width
            console.log(letter)
            daysInLetter = 0
            x = 0

        console.log(x, letter, FONT[letter].width)

        TMP[y] = TMP[y] || ''

        if isLetterPixel(letter, x, y)
            TMP[y] += 'X'
        else
            TMP[y] += ' '

        day++
        daysInLetter++

    console.log(TMP)

main()
