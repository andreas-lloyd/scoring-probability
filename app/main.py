from flask import Flask, jsonify, request
import pandas as pd
import datetime
import os

app = Flask(__name__)

# Get query
with open('base-query.sql', 'r') as query_file:
    BASE_QUERY = query_file.read()

# Get URI
URI = os.environ.get('DB_URI')

def find_current_season():
    current_time = datetime.datetime.now()
    year = current_time.year
    month = current_time.month

    # If we are past July, then this year is the current season's start year - otherwise need previous
    if month < 7:
        year -= 1

    return str(year)[-2:] + str(year + 1)[-2:]

def find_previous_season(curr_season):
    return str(int(str(curr_season)[:2]) - 1) + str(int(str(curr_season)[-2:]) - 1)

# So going to ask for the gameweek always and then suggest the current season and last season
@app.route("/probability/", methods=['GET'])
@app.route("/probability/<gameweek>/")
def calc_probabilities(gameweek):
    # Get the current season if no season is given
    if 'curr_season' in request.args:
        curr_season = request.args.get('curr_season')
    else:
        curr_season = find_current_season()

    # Now get the previus season
    if 'prev_season' in request.args:
        prev_season = request.args.get('prev_season')
    else:
        prev_season = find_previous_season(curr_season)

    # Then format the query
    query = BASE_QUERY.format(
        input_gameweek=gameweek, 
        input_current_season=curr_season, 
        input_previous_season=prev_season
        )

    # Then read from the DB - transform into a dictionary of player_id : probability
    result = pd.read_sql(query, URI).set_index('player_uid').to_dict()['probability']

    # And return this directly as a json
    return jsonify(result)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)