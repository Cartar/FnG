USE [fng]
GO

/****** Object:  StoredProcedure [dbo].[showLeagueRankingAnalysis]    Script Date: 1/1/2024 10:40:12 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE
procedure [dbo].[showLeagueRankingAnalysis]
(
	@leagueID int,
	@max_diff float = 0.200
)
as
begin

--SELECT racer_id, discipline, coalesce(adjusted_percentile, calculated_percentile) as percentile, rank() OVER(PARTITION BY discipline ORDER BY coalesce(adjusted_percentile, calculated_percentile) desc, racer_id) as rank
SELECT racer_id, discipline, coalesce(adjusted_x_avg, calculated_x_avg) as percentile, rank() OVER(PARTITION BY discipline ORDER BY coalesce(adjusted_x_avg, calculated_x_avg), racer_id) as rank
into #tmp_ranked_racers
from league_racer
where league_id = @leagueId


select trr1.discipline, trr1.racer_id, trr1.rank, floor(trr1.percentile*100000000)/100000000 as effective_x_avg
, (SELECT FLOOR(1000 *AVG(CASE WHEN time_diff > @max_diff THEN @max_diff ELSE (CASE WHEN time_diff < -@max_diff THEN -@max_diff ELSE time_diff END) END)) / 1000
	FROM (SELECT top 5 rrComp._time - rr1._time as time_diff
		FROM result rr1 INNER JOIN result rrComp ON rrComp.race_id = rr1.race_id
			AND rrComp.discipline = rr1.discipline
			AND rrComp.racer_id = trr2.racer_id
			and rrComp.dnf = 0 and rrComp.dns = 0 and rrComp.dq = 0
		WHERE rr1.discipline = trr1.discipline and rr1.racer_id = trr1.racer_id
			and rr1.dnf = 0 and rr1.dns = 0 and rr1.dq = 0
		ORDER BY rr1.race_id desc) as last_5_mutual_finishes) as avg_mov_1
, 'vs. '+trr2.racer_id as rank_plus_1
, (SELECT FLOOR(1000 *AVG(CASE WHEN time_diff > @max_diff THEN @max_diff ELSE (CASE WHEN time_diff < -@max_diff THEN -@max_diff ELSE time_diff END) END)) / 1000
	FROM (SELECT top 5 rrComp._time - rr1._time as time_diff
		FROM result rr1 INNER JOIN result rrComp ON rrComp.race_id = rr1.race_id
			AND rrComp.discipline = rr1.discipline
			AND rrComp.racer_id = trr3.racer_id
			and rrComp.dnf = 0 and rrComp.dns = 0 and rrComp.dq = 0
		WHERE rr1.discipline = trr1.discipline and rr1.racer_id = trr1.racer_id
			and rr1.dnf = 0 and rr1.dns = 0 and rr1.dq = 0
		ORDER BY rr1.race_id desc) as last_5_mutual_finishes) as avg_mov_2
, 'vs. '+trr3.racer_id as rank_plus_2
, (SELECT FLOOR(1000 *AVG(CASE WHEN time_diff > @max_diff THEN @max_diff ELSE (CASE WHEN time_diff < -@max_diff THEN -@max_diff ELSE time_diff END) END)) / 1000
	FROM (SELECT top 5 rrComp._time - rr1._time as time_diff
		FROM result rr1 INNER JOIN result rrComp ON rrComp.race_id = rr1.race_id
			AND rrComp.discipline = rr1.discipline
			AND rrComp.racer_id = trr4.racer_id
			and rrComp.dnf = 0 and rrComp.dns = 0 and rrComp.dq = 0
		WHERE rr1.discipline = trr1.discipline and rr1.racer_id = trr1.racer_id
			and rr1.dnf = 0 and rr1.dns = 0 and rr1.dq = 0
		ORDER BY rr1.race_id desc) as last_5_mutual_finishes) as avg_mov_3
, 'vs. '+trr4.racer_id as rank_plus_3
, (SELECT FLOOR(1000 *AVG(CASE WHEN time_diff > @max_diff THEN @max_diff ELSE (CASE WHEN time_diff < -@max_diff THEN -@max_diff ELSE time_diff END) END)) / 1000
	FROM (SELECT top 5 rrComp._time - rr1._time as time_diff
		FROM result rr1 INNER JOIN result rrComp ON rrComp.race_id = rr1.race_id
			AND rrComp.discipline = rr1.discipline
			AND rrComp.racer_id = trr5.racer_id
			and rrComp.dnf = 0 and rrComp.dns = 0 and rrComp.dq = 0
		WHERE rr1.discipline = trr1.discipline and rr1.racer_id = trr1.racer_id
			and rr1.dnf = 0 and rr1.dns = 0 and rr1.dq = 0
		ORDER BY rr1.race_id desc) as last_5_mutual_finishes) as avg_mov_4
, 'vs. '+trr5.racer_id as rank_plus_4
from #tmp_ranked_racers trr1
left join #tmp_ranked_racers trr2 on trr2.discipline = trr1.discipline and trr2.rank = trr1.rank+1
left join #tmp_ranked_racers trr3 on trr3.discipline = trr1.discipline and trr3.rank = trr1.rank+2
left join #tmp_ranked_racers trr4 on trr4.discipline = trr1.discipline and trr4.rank = trr1.rank+3
left join #tmp_ranked_racers trr5 on trr5.discipline = trr1.discipline and trr5.rank = trr1.rank+4


drop table #tmp_ranked_racers


end
GO


