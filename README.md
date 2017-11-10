# BashHist

Inspired from https://github.com/bamos/zsh-history-analysis.

Visualize your usage of Bash (and other shells?) through a web app thanks
to Flask and Highcharts.

**Alpha stage! Actual history is not used (only fixtures right now).**

## Installation

Clone the repo with `git clone https://github.com/Pawamoy/bashhist`.

## Dependencies

Only Flask: `pip install flask`. You will also need Internet connection since
assets are not bundled.

## Usage

Simply `./run.sh`, or run it manually with `FLASK_APP=app.py flask run`.
Now go to http://127.0.0.1:5000/ and enjoy!

## Charts example

![monthly chart](pictures/monthly.png)

![hourly chart](pictures/hourly.png)
