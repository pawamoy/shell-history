# -*- coding: utf-8 -*-

import time
from collections import Counter, defaultdict
from datetime import datetime
import statistics

from dateutil.relativedelta import relativedelta
from flask import Flask, jsonify, render_template
from sqlalchemy import extract, func

import db

app = Flask(__name__)
db.update()
session = db.Session()

# Utils ------------------------------------------------------------------------
def since_epoch(date): # returns seconds since epoch
    return time.mktime(date.timetuple())


def fractional_year(start, end):
    this_year = end.year
    this_year_start = datetime(year=this_year, month=1, day=1)
    next_year_start = datetime(year=this_year + 1, month=1, day=1)
    time_elapsed = since_epoch(end) - since_epoch(start)
    year_duration = since_epoch(next_year_start) - since_epoch(this_year_start)
    return time_elapsed / year_duration


# Simple views rendering templates ---------------------------------------------
@app.route('/')
def home_view():
    return render_template('home.html')


@app.route('/daily')
def daily_view():
    return render_template('daily.html')


@app.route('/daily_number')
def daily_number_view():
    return render_template('daily_number.html')


@app.route('/fuck')
def fuck_view():
    return render_template('fuck.html')


@app.route('/hourly')
def hourly_view():
    return render_template('hourly.html')


@app.route('/hourly_average')
def hourly_average_view():
    return render_template('hourly_average.html')


@app.route('/hourly_number')
def hourly_number_view():
    return render_template('hourly_number.html')


@app.route('/length')
def length_view():
    return render_template('length.html')


@app.route('/markov')
def markov_view():
    return render_template('markov.html')


@app.route('/monthly')
def monthly_view():
    return render_template('monthly.html')


@app.route('/monthly_average')
def monthly_average_view():
    return render_template('monthly_average.html')


@app.route('/top_commands_full')
def top_commands_full_view():
    return render_template('top_commands_full.html')


@app.route('/top_commands')
def top_commands_view():
    return render_template('top_commands.html')


@app.route('/trending')
def trending_view():
    return render_template('trending.html')


@app.route('/type')
def type_view():
    return render_template('type.html')


# Routes to return JSON contents -----------------------------------------------
@app.route('/daily_json')
def daily_json():
    data = None
    return jsonify(data)


@app.route('/daily_number_json')
def daily_number_json():
    data = None
    return jsonify(data)


@app.route('/fuck_json')
def fuck_json():
    data = None
    return jsonify(data)


@app.route('/hourly_json')
def hourly_json():
    results = defaultdict(
        lambda: 0,
        session.query(
            extract('hour', db.History.start).label('hour'),
            func.count('hour')
        ).group_by('hour').all())
    data = [results[hour] for hour in range(0, 24)]
    return jsonify(data)


@app.route('/hourly_average_json')
def hourly_average_json():
    mintime = session.query(func.min(db.History.start)).first()[0]
    maxtime = session.query(func.max(db.History.start)).first()[0]
    number_of_days = (maxtime - mintime).days + 1
    results = defaultdict(
        lambda: 0,
        session.query(
            extract('hour', db.History.start).label('hour'),
            func.count('hour')
        ).group_by('hour').all())
    data = [results[hour] / number_of_days for hour in range(0, 24)]
    return jsonify(data)


@app.route('/hourly_number_json')
def hourly_number_json():
    data = None
    return jsonify(data)


@app.route('/length_json')
def length_json():
    results = defaultdict(
        lambda: 0,
        session.query(
            func.char_length(db.History.cmd).label('length'),
            func.count('length')
        ).group_by('length').all())

    flat_values = []
    for length, number in results.items():
        flat_values.extend([length] * number)

    data = {
        'average': float('%.2f' % statistics.mean(flat_values)),
        'median': statistics.median(flat_values),
        'series': [results[length] for length in range(1, max(results.keys()) + 1)]
    }
    return jsonify(data)


@app.route('/markov_json')
def markov_json():
    data = None
    return jsonify(data)


@app.route('/monthly_json')
def monthly_json():
    results = defaultdict(
        lambda: 0,
        session.query(
            extract('month', db.History.start).label('month'),
            func.count('month')
        ).group_by('month').all())
    data = [results[month] for month in range(1, 13)]
    return jsonify(data)


@app.route('/monthly_average_json')
def monthly_average_json():
    mintime = session.query(func.min(db.History.start)).first()[0]
    maxtime = session.query(func.max(db.History.start)).first()[0]
    number_of_years = fractional_year(mintime, maxtime) + 1
    results = defaultdict(
        lambda: 0,
        session.query(
            extract('month', db.History.start).label('month'),
            func.count('month')
        ).group_by('month').all())
    data = [float('%.2f' % (results[month] / number_of_years)) for month in range(1, 13)]
    return jsonify(data)


@app.route('/top_commands_full_json')
def top_commands_full_json():
    data = None
    return jsonify(data)


@app.route('/top_commands_json')
def top_commands_json():
    data = None
    return jsonify(data)


@app.route('/trending_json')
def trending_json():
    data = None
    return jsonify(data)


@app.route('/type_json')
def type_json():
    data = None
    return jsonify(data)
