/*
In reality just need to get one entry per player where we talk the whole current season and the whole of last season
Could make both of these as inputs, so if not provided, we just take current and avoid logic of converting for last season

I guess what makes most sense is to look for the first match that hasn't happened yet - and then define the probabilities for that
*/
-- First find the next match for each team
with current_match as (
select home_team_uid as team_uid, 1 is_home from data_fixtures where gameweek = {input_gameweek} and year = {input_current_season}
union all
select away_team_uid as team_uid, 0 is_home from data_fixtures where gameweek = {input_gameweek} and year = {input_current_season}
),

-- Now get the relevant games - the home or away games before this gameweek and aggregate for each player
this_season_scorers as (
select 
c.uid player_uid, c.team_uid, c.position, 
count(distinct d.fixture_uid) num_matches_scored, count(distinct b.uid)  as num_matches
from current_match a

-- Get the past fixtures
join data_fixtures b 
on a.team_uid = case when a.is_home = 1 then b.home_team_uid else b.away_team_uid end

-- And then get all the players
join data_players c on a.team_uid = c.team_uid

-- And check who scored
left join (select distinct fixture_uid, player_uid from data_goals) d on b.uid = d.fixture_uid and c.uid = d.player_uid

-- Only consider matches before gameweek this season
where b.gameweek < {input_gameweek} and b.year = {input_current_season}
group by 1, 2, 3
),

-- Now we need to get the past season's games in a similar way, but we will group on position
past_season_scorers as (
select 
coalesce(e.team_uid, 'RELEGATED') team_uid, c.position, 
count(distinct d.fixture_uid) num_matches_scored, count(distinct b.uid)  as num_matches
from current_match a

-- Get the past fixtures
join data_fixtures b 
on a.team_uid = case when a.is_home = 1 then b.home_team_uid else b.away_team_uid end

-- And then get all the players
join data_players c on a.team_uid = c.team_uid

-- And check who scored
left join (select distinct fixture_uid, player_uid from data_goals) d on b.uid = d.fixture_uid and c.uid = d.player_uid

-- And finally check which teams were relegated
left join (select distinct team_uid from this_season_scorers) e on c.team_uid = e.team_uid

-- Only consider previous season
where b.year = {input_previous_season}
group by 1, 2
),

-- Quick stopgap for relegated / promoted teams
join_table as (
select
a.team_uid, coalesce(b.team_uid, 'RELEGATED') corresponding_old_team_uid
from 
(select distinct team_uid from this_season_scorers) a 
left join 
(select distinct team_uid from past_season_scorers) b
on a.team_uid = b.team_uid
),

-- And now calculate the probability
final_probability as (
select
a.player_uid, (a.num_matches_scored + c.num_matches_scored) / (1.0 * (a.num_matches + c.num_matches)) probability
-- First get the team we have to look for in last season
from this_season_scorers a join join_table b on a.team_uid = b.team_uid 

-- Then pull last season data
join past_season_scorers c on b.corresponding_old_team_uid = c.team_uid and a.position = c.position

)

select * from final_probability