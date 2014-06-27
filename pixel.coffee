fs = require('fs')
path = require('path')



DATE_START = new Date('2014-06-29T12:00:00')

DAY_DURATION_MS = 3600 * 24 * 1000;
DAYS_IN_WEEK = 7
WEEKS_IN_YEAR = 51

OUTPUT_TEXT = process.env.ONE_PIXEL_WRITE

CHARS = JSON.parse(fs.readFileSync(__dirname + '/font.json'))
CHAR_SPACE_WIDTH = 1
OUTPUT_DIR = fs.realpathSync(__dirname + '/../push')
OUTPUT_FILE = OUTPUT_DIR + '/pixels.txt'

if 0 isnt new Date(DATE_START).getDay()
    console.error('Start date not a Sunday!')
    process.exit(1)

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
        process.exit(0)

    numPaintDays = getNumPaintDays()
    console.log("Started on     : #{DATE_START}")
    console.log("Writing str    : #{OUTPUT_TEXT}")
    console.log("Columns        : #{numPaintDays / DAYS_IN_WEEK} of #{WEEKS_IN_YEAR}")

    day = Math.floor((+now - DATE_START) / DAY_DURATION_MS);

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

        sys = require('sys')
        exec = require('child_process').exec;
        puts = (error, stdout, stderr) ->
            console.log(error, stdout, stderr)

        exec("#{__dirname}/commit.sh '#{OUTPUT_DIR}' '#{OUTPUT_FILE}'", puts);

main()
