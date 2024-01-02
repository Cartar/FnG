USE [fng]
GO

/****** Object:  StoredProcedure [dbo].[calculate_x_avg]    Script Date: 1/1/2024 10:25:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE
procedure [dbo].[calculate_x_avg]
@leagueID int
as
begin

	declare @extraWeightDate datetime

--	select top 1 @extraWeightDate = race_date from league_race lr inner join race r on r.race_id = lr.race_id and lr.league_id < @leagueID order by league_id desc, race_date

	update league_racer set calculated_x_avg =
	(select AVG(_time / adj_avg_time)
				from ( select * from result union all select result.* from result inner join race r on r.race_id = result.race_id and race_date >= @extraWeightDate
				) as res
				inner join race_discipline rd on rd.race_id = res.race_id and rd.discipline = res.discipline
				where res.racer_id = league_racer.racer_id and LEFT(res.discipline,3) = LEFT(league_racer.discipline,3) and _time IS NOT NULL)
	where league_id = @leagueID
end

GO


