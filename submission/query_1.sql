INSERT INTO saidaggupati.nba_players_tracking
--previous day CTE

WITH prior_day AS (
    SELECT 
        player_name,
        first_active_seasons,
        last_active_seasons,
        active_season,
        player_state, -- needed this for the assignment
        season
FROM saidaggupati.nba_players_tracking
WHERE season = 1995
),

-- today's CTE

current_day AS (
    SELECT 
    player_name, MAX(current_season) AS active_season, MAX(is_active) AS is_active
    FROM bootcamp.nba_players WHERE current_season = 1996
    GROUP BY player_name
),

-- combined CTE

combined_data AS (
    SELECT
        COALESCE(p.player_name, c.player_name) AS player_name, 
        COALESCE(p.first_active_seasons, c.active_season) AS first_active_seasons, 
        p.last_active_seasons AS last_active_seasons, 
        c.is_active, 
        COALESCE(c.active_season, p.last_active_seasons) AS last_active_seasons, 
        CASE
            WHEN p.active_season IS NULL THEN ARRAY[c.active_season] 
            WHEN c.active_season IS NULL THEN p.active_season 
            WHEN c.active_season IS NOT NULL AND c.is_active THEN p.active_season || ARRAY[c.active_season] 
            ELSE p.active_season 
        END AS active_season,
        COALESCE(p.season + 1, c.active_season) AS season 
    FROM
        prior_day p
        FULL OUTER JOIN current_day c ON p.player_name = c.player_name 
)

-- Final data set

SELECT 
    player_name,
    first_active_seasons,
    last_active_seasons,
    active_season,
    CASE
        WHEN is_active AND last_active_seasons IS NULL THEN 'New'
        WHEN is_active AND season - last_active_seasons = 1 THEN 'Continued Playing' 
        WHEN is_active AND season - last_active_seasons > 1 THEN 'Returned from Retirement' 
        WHEN NOT is_active AND season - last_active_seasons = 1 THEN 'Retired' 
        ELSE 'Stayed Retired' 
    END AS player_state,
    season
FROM combined_data c