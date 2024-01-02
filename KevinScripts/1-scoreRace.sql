USE [fng]
GO

/****** Object:  StoredProcedure [dbo].[scoreRace]    Script Date: 1/1/2024 10:32:32 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE
procedure [dbo].[scoreRace]
(
	@leagueID int,
	@raceID int
)
as
begin

	set nocount on

	if exists (select * from result where race_id = @raceID and points IS NOT NULL)
	begin
		raiserror ('Race has already been scored', 15, 1)
	end
	else
	begin

		select discipline, tier, COUNT(*) as num_racers
		into #tier_counts
		from league_racer
		where league_id = @leagueID and team IS NOT NULL
		group by discipline, tier

		insert into result (race_id, discipline, racer_id, name_on_timesheet, dns)
		select @raceID, lr.discipline, lr.racer_id, lr.racer_id + ' (DNS)', 1
		from league_racer lr
		left join result res on res.race_id = @raceID and res.discipline = lr.discipline and res.racer_id = lr.racer_id
		where league_id = @leagueID and res.racer_id IS NULL

		declare @tmpPoints table (discipline char(4), racer_id varchar(32), tier_place int, points float)

		declare @pointsSummary table (discipline char(4), racer_id varchar(32), tier_place int, points float)

		declare @result cursor

		set @result = CURSOR FOR
			select lr.discipline, lr.tier, lr.racer_id, lr.is_bonus, lr.is_wildcard, lr.team, tc.num_racers,
			res.dnf, res.dns, res.dq, CASE WHEN res.dns = 1 THEN 99999.99 ELSE ISNULL(res._time,88888.88) END as adj_time
			from league_racer lr
			join #tier_counts tc on tc.discipline = lr.discipline and tc.tier = lr.tier
			left join result res on res.discipline = lr.discipline and res.racer_id = lr.racer_id and race_id = @raceID
			where league_id = @leagueID and team IS NOT NULL
			order by lr.discipline, lr.tier, adj_time --CASE WHEN res.racer_id IS NULL THEN 99999.99 ELSE ISNULL(res._time,88888.88) END

		declare @fetchStatus int
		declare @lastTier int
		declare @lastAdjTime float
		declare @numRacersInTier int
		declare @tierPlace int
		declare @pointValue float

		declare @discipline char(4)
		declare @tier int
		declare @racer_id varchar(32)
		declare @is_bonus bit
		declare @is_wildcard bit
		declare @team int
		declare @num_racers int
		declare @dnf bit, @dns bit, @dq bit
		declare @adj_time float

		open @result

		set @lastTier = -1

		fetch next from @result into @discipline, @tier, @racer_id, @is_bonus, @is_wildcard, @team, @num_racers, @dnf, @dns, @dq, @adj_time

		set @fetchStatus = @@FETCH_STATUS

		while @fetchStatus = 0
		begin

			if @tier <> @lastTier
			begin
				set @numRacersInTier = @num_racers
				set @tierPlace = 1
			end
			set @lastTier = @tier
			set @pointValue = @numRacersInTier - @tierPlace + 1
			if @is_wildcard = 1
			begin
				set @pointValue = @pointValue / 2
			end

			insert into @tmpPoints (discipline, racer_id, tier_place, points)
			VALUES (@discipline, @racer_id, @tierPlace, @pointValue)

			set @tierPlace = @tierPlace + 1
			set @lastAdjTime = @adj_time

			fetch next from @result into @discipline, @tier, @racer_id, @is_bonus, @is_wildcard, @team, @num_racers, @dnf, @dns, @dq, @adj_time
			set @fetchStatus = @@FETCH_STATUS

			if (@fetchStatus <> 0 or @lastAdjTime <> @adj_time or @lastTier <> @tier)
			begin
				insert into @pointsSummary (discipline, racer_id, tier_place, points)
				SELECT discipline, racer_id, plcpts.tier_place, plcpts.points
				FROM @tmpPoints tpts
				inner join (select MIN(tier_place) tier_place, AVG(points) points from @tmpPoints) plcpts on 1=1

				delete from @tmpPoints
			end

		end

		update result set result.tier_place = ps.tier_place, result.points = ps.points
		from result res --on res.discipline = lr.discipline and res.racer_id = lr.racer_id
		inner join @pointsSummary ps on ps.discipline = res.discipline and ps.racer_id = res.racer_id
		where --lr.league_id = @leagueID and 
			res.race_id = @raceID
--		order by res.discipline, tier, res.tier_place

		select *
		from league_racer lr
		inner join result res on res.discipline = lr.discipline and res.racer_id = lr.racer_id
		where lr.league_id = @leagueID and res.race_id = @raceID
		order by res.discipline, tier, res.tier_place

	end  

end


GO


