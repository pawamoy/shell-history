# -*- coding: utf-8 -*-

from flask import Flask, render_template, jsonify

import db

app = Flask(__name__)
db.create_tables()
    

@app.route('/')
def home_view():
    return render_template('home.html')


# Simple views rendering templates ---------------------------------------------
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
    data = [49, 71, 106, 129, 144, 176, 135, 148, 216, 194, 95, 54, 49, 71, 106, 129, 144, 176, 135, 148, 216, 194, 95, 54]
    return jsonify(data)


@app.route('/hourly_number_json')
def hourly_number_json():
    data = None
    return jsonify(data)


@app.route('/length_json')
def length_json():
    data = None
    return jsonify(data)


@app.route('/markov_json')
def markov_json():
    data = None
    return jsonify(data)


@app.route('/monthly_json')
def monthly_json():
    data = [49, 71, 106, 129, 144, 176, 135, 148, 216, 194, 95, 54]
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
