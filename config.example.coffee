# Copy to config.coffee and adjust to match your environment.

module.exports =
    # Text displayed on graph.
    graphText: 'Hi!'

    # Date object with start date.
    # Example: new Date('2014-06-01 12:00:00')
    startDate: new Date()

    # Message used for committing to GitHub.
    commitMessage: 'Pixel day!'

    # GitHub repository that you have access to.
    repository: 'https://github.com/my-username/my-project.git'

    # This is to ensure you don't accidentally pollute the
    # history graph for your main GitHub account.
    userEmail: 'hello@example.org'
    userName: 'John Doe'

    # Directory where your GitHub repository is handled.
    outputDir: '~/my-project/'

    # Output file name.
    outputFile: 'pixels.txt'
