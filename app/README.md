# Scoring app
This is a small app that will return the probability each player has to score in a given gameweek. The default is to look at the current and last season (for the prior probability), but these can be specified. If only one season of data is available, then have to use the current season for the prior (pretty crappy but whatever).

This was built into an API for future ease of deployment if there are any improvements, but in reality the current solution is just an SQL query that calculates beta probabilities.
