fs = require('fs')
path = require('path')



DATE_START = '2014-06-26T12:00:00'

DAY_DURATION_MS = 3600 * 24 * 1000;
DAYS_IN_WEEK = 7
WEEKS_IN_YEAR = 51

OUTPUT_TEXT = process.env.ONE_PIXEL_WRITE

CHARS = JSON.parse(fs.readFileSync(__dirname + '/font.json'))
CHAR_SPACE_WIDTH = 1
OUTPUT_FILE = __dirname + '/../push/pixels.txt'


getNumPaintDays = () ->
    days = 0
    for i in [0..OUTPUT_TEXT.length - 1]
        letter = OUTPUT_TEXT.charAt(i)
        days += (CHARS[letter].width + CHAR_SPACE_WIDTH) * DAYS_IN_WEEK
    return days - DAYS_IN_WEEK


getLetterIndexForDay = (day) ->
    letterPointer = 0
    for i in [0..OUTPUT_TEXT.length - 1]
        letter = OUTPUT_TEXT.charAt(i)
        letterPointer += CHARS[letter].width
        if i isnt OUTPUT_TEXT.length - 1
            letterPointer += CHAR_SPACE_WIDTH
        if letterPointer * DAYS_IN_WEEK >= day
            return i
        i++

isLetterPixel = (letter, x, y) ->
    pixels = CHARS[letter].pixels
    if pixels[y] and -1 isnt pixels[y].indexOf(x)
        return true
    return false


main = ->
    now = new Date()
    dayPointer = 0

    if now < DATE_START
        console.log("Not starting yet.")
        return

    numPaintDays = getNumPaintDays()
    console.log("Started on     : #{DATE_START}")
    console.log("Writing str    : #{OUTPUT_TEXT}")
    console.log("Columns        : #{numPaintDays / DAYS_IN_WEEK} of #{WEEKS_IN_YEAR}")

    day = Math.floor((+now - DATE_START) / DAY_DURATION_MS);

    if 0 isnt now.getDay()
        console.log("Starting this Sunday.")
        return

    letter = ''
    daysInLetter = 0
    indexPrev = 0
    paintToday = false

    pixels = []

    while dayPointer <= day
        index = getLetterIndexForDay(dayPointer)
        letter = OUTPUT_TEXT.charAt(index)

        if index isnt indexPrev
            daysInLetter = 0

        indexPrev = index

        x = Math.floor(daysInLetter / DAYS_IN_WEEK)
        y = daysInLetter % DAYS_IN_WEEK

        pixels[y] = pixels[y] || ''

        paintToday = isLetterPixel(letter, x, y)
        if paintToday then pixels[y] += '#' else pixels[y] += ' '

        dayPointer++
        daysInLetter++

    str = ''
    for line in pixels
        str += "#{line}\n"

    console.log("Progress       : #{day} of #{numPaintDays}")
    console.log("Current letter : #{letter}")
    console.log("Paint today    : #{paintToday}")

    if paintToday
        fs.writeFileSync(fs.realpathSync(OUTPUT_FILE), str)

main()
