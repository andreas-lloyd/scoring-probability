with who_scored_home as (
select 
a.uid as fixture_uid, a.home_team_uid team_uid, 1 is_home, b.uid player_uid, 
a.kick_off, a.gameweek, a.year season, b.position,
case when c.player_uid is null then 0 else 1 end played,
case when d.player_uid is null then 0 else 1 end scored
from
data_fixtures a
join data_players b on a.home_team_uid = b.team_uid
left join data_appearances c on a.uid = c.fixture_uid and b.uid = c.player_uid
left join (select distinct fixture_uid, player_uid from data_goals) d on a.uid = d.fixture_uid and b.uid = d.player_uid
),

who_scored_away as (
select 
a.uid as fixture_uid, a.away_team_uid team_uid, 0 is_home, b.uid player_uid, 
a.kick_off, a.gameweek, a.year season, b.position,
case when c.player_uid is null then 0 else 1 end played,
case when d.player_uid is null then 0 else 1 end scored
from
data_fixtures a
join data_players b on a.away_team_uid = b.team_uid
left join data_appearances c on a.uid = c.fixture_uid and b.uid = c.player_uid
left join (select distinct fixture_uid, player_uid from data_goals) d on a.uid = d.fixture_uid and b.uid = d.player_uid
),

who_scored as (
select * from who_scored_home
union all
select * from who_scored_away
),

-- This should be from the previous season but we don't have info
team_stats as (
select a.*, b.num_matches
from (
select team_uid, is_home, position, sum(team_scored) num_games_scored
from (
select team_uid, is_home, position, fixture_uid, max(scored) team_scored
from who_scored
group by 1, 2, 3, 4
) team_scored
group by 1, 2, 3
) a
join 
(
select team_uid, is_home, count(distinct fixture_uid) num_matches
from who_scored
group by 1, 2
) b on a.team_uid = b.team_uid and a.is_home = b.is_home
),

running_table as (
select *, 
sum(played) over (partition by player_uid order by kick_off) appearance_number,
sum(scored) over (partition by player_uid order by kick_off) matches_scored,
dense_rank() over (partition by team_uid order by kick_off) match_number
from who_scored
),

final_table as (
select *, 
100 * matches_scored_until_now / appearances_until_now chance_score_given_played,
100 * matches_scored_until_now / matches_until_now chance_score
from (
select a.*, 
num_games_scored + COALESCE(lag(matches_scored) over (partition by player_uid order by kick_off), 0) matches_scored_until_now, 
num_matches + COALESCE(lag(appearance_number) over (partition by player_uid order by kick_off), 0) appearances_until_now, 
num_matches + COALESCE(lag(match_number) over (partition by player_uid order by kick_off), 0) matches_until_now
from running_table a
join team_stats b
on a.team_uid = b.team_uid and a.is_home = b.is_home and a.position = b.position
) lag_part
)

select * from final_table