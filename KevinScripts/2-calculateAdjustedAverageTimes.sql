USE [fng]
GO

/****** Object:  StoredProcedure [dbo].[calculateAdjustedAverageTimes]    Script Date: 1/1/2024 10:14:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE
procedure [dbo].[calculateAdjustedAverageTimes]
@raceID int
as
begin

	update rd
	set rd.adj_avg_time = adj_avg
	--select *
	from race_discipline rd
	inner join (
		select res.race_id, res.discipline, AVG(_time) adj_avg, STDEV(_time) adj_std_dev
		from result res
		left join (
			select race_id, discipline, AVG(_time) raw_avg, STDEV(_time) raw_std_dev
			from result
			where dns = 0 and dnf = 0 and dq = 0
			group by race_id, discipline
		) as raw_stats
		on res.race_id = raw_stats.race_id and res.discipline = raw_stats.discipline
		where _time between raw_avg - (2*raw_std_dev) and raw_avg + (2*raw_std_dev)
			and dns = 0 and dnf = 0 and dq = 0
		group by res.race_id, res.discipline
	) as adjres on adjres.race_id = rd.race_id and adjres.discipline = rd.discipline
	where rd.race_id = @raceID

end

GO


