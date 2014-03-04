use superliga
drop table matches
drop table teams
go
create table teams
(
Id char(3) primary key,
name varchar(40),
nomatches int,
owngoals int,
othergoals int,
points int
)
create table matches
(
id int identity(1,1), --nummerering af matches, start på 1 og spring på 1
homeid char(3) foreign key references teams(id),
outid char(3) foreign key references teams(id),
homegoal int,
outgoal int,
matchdate datetime
)


-- Trigger på indsættelse af ny fodboldkamp til match tabellen. Anvender denormalisering til at opdatere
-- teams tabellen for at gøre det lettere at tilgå målstatistikken.
drop trigger InsertMatchTrigger
go
create trigger InsertMatchTrigger
on matches
for insert, update
as
--Deklarering af variable, som vi gemmer de relevante værdier fra inserted tabellen i
declare @homegoal int
declare @homeid char(3)
declare @outgoal int
declare @outid char(3)
select @homegoal = homegoal, @outgoal = outgoal, @homeid = homeid, @outid = outid from inserted

--Tjek på kampens resultat, og opdatering af værdier herefter. Vundet kamp +3 point, lige kamp +1 til begge hold, tabt kamp +0
if @homegoal > @outgoal 
	update teams set points += 3 where Id = @homeid
else if @homegoal = @outgoal 
	update teams set points += 1 where Id = @homeid or Id = @outid
else 
	update teams set points += 3 where Id = @outid

--Opdatering af begge holds målstatistik samt antal af spillede kampe med redundant information.
update teams set nomatches+=1, owngoals += @homegoal, othergoals += @outgoal where Id = @homeid
update teams set nomatches+=1, owngoals += @outgoal, othergoals += @homegoal where Id = @outid

go

-- Trigger på sletning og slette-delen af en opdatering af ny fodboldkamp til match tabellen. 
go
drop trigger DeletedMatchTrigger
go
create trigger DeletedMatchTrigger
on matches
for delete, update
as
--Deklarering af variable, som vi gemmer de relevante værdier fra inserted tabellen i
declare @homegoal int
declare @homeid char(3)
declare @outgoal int
declare @outid char(3)
select @homegoal = homegoal, @outgoal = outgoal, @homeid = homeid, @outid = outid from deleted

--Tjek på kampens resultat, og opdatering af værdier herefter. Vundet kamp +3 point, lige kamp +1 til begge hold, tabt kamp +0
if @homegoal > @outgoal 
	update teams set points -= 3 where Id = @homeid
else if @homegoal = @outgoal 
	update teams set points -= 1 where Id = @homeid or Id = @outid
else 
	update teams set points -= 3 where Id = @outid

--Opdatering af begge holds målstatistik samt antal af spillede kampe.
update teams set nomatches-=1, owngoals -= @homegoal, othergoals -= @outgoal where Id = @homeid
update teams set nomatches-=1, owngoals -= @outgoal, othergoals -= @homegoal where Id = @outid

go



--Stored procedure to show the scoretable on a given date. Requires teams to be created, 
--and matches, if you want your result to be interesting.
drop procedure ShowScoreTable
go
--Parameter: datetime - the date of the scoretable. Return: void
create procedure ShowScoretable @DateToShow datetime as
--Temporary table to store the results 
declare @resultTable table
(
	Id char(3) primary key,
	name varchar(40),
	nomatches int,
	owngoals int,
	othergoals int,
	points int
)
--Copy values from teams table, resetting goal and point values.
insert into @resultTable select Id, name, 0, 0, 0, 0 from teams

--Cursor to loop through each match whose matchdate <= @DateToShow
declare p cursor
for select Id, homeid, outid, homegoal, outgoal from matches where matchdate <= @DateToShow
declare @Id int, @homeid char(3), @outid char(3), @homegoal int, @outgoal int
open p
--fetch first match values into variables
fetch p into @Id, @homeid, @outid, @homegoal, @outgoal
while @@fetch_status != -1
begin
	--same logic as the UpdateScoreTrigger
	if @homegoal > @outgoal 
		update @resultTable set points += 3 where Id = @homeid
	else if @homegoal = @outgoal 
		update @resultTable set points += 1 where Id = @homeid or Id = @outid
	else 
		update @resultTable set points += 3 where Id = @outid

	update @resultTable set nomatches+=1, owngoals += @homegoal, othergoals += @outgoal where Id = @homeid
	update @resultTable set nomatches+=1, owngoals += @outgoal, othergoals += @homegoal where Id = @outid
	--done with this match, onto the next
	fetch p into @Id, @homeid, @outid, @homegoal, @outgoal
end
close p
deallocate p
select * from @resultTable order by points desc
go
exec ShowScoreTable @DateToShow = '2009-10-01'
---
---

insert into teams values('agf','AGF',0,0,0,0)
insert into teams values('sif','Silkeborg',0,0,0,0)
insert into teams values('fck','FC København',0,0,0,0)
insert into teams values('rfc','Randers FC',0,0,0,0)
insert into teams values('hbk','HB Køge',0,0,0,0)
insert into teams values('søn','SønderjyskE',0,0,0,0)
insert into teams values('ob','OB',0,0,0,0)
insert into teams values('fcm','FC Midtjylland',0,0,0,0)
insert into teams values('efb','Esbjerg fB',0,0,0,0)
insert into teams values('bif','Brøndby IF',0,0,0,0)
insert into teams values('fcn','FC Nordsjælland',0,0,0,0)
insert into teams values('aab','AaB',0,0,0,0)

insert into matches values('fcn','fck',2,0,'2009-07-18')
insert into matches values('fcm','efb',0,0,'2009-07-18')
insert into matches values('søn','rfc',1,0,'2009-07-19')
insert into matches values('hbk','sif',1,1,'2009-07-19')
insert into matches values('bif','ob',2,2,'2009-07-19')
insert into matches values('agf','aab',1,0,'2009-07-20')
--
insert into matches values('fck','hbk',7,1,'2009-07-25')
insert into matches values('ob','søn',3,1,'2009-07-25')
insert into matches values('sif','fcm',4,0,'2009-07-26')
insert into matches values('efb','bif',2,1,'2009-07-26')
insert into matches values('rfc','agf',2,3,'2009-07-27')
--
insert into matches values('fck','sif',1,1,'2009-08-01')
insert into matches values('søn','efb',1,1,'2009-08-01')
insert into matches values('hbk','aab',0,5,'2009-08-02')
insert into matches values('fcn','rfc',2,2,'2009-08-02')
insert into matches values('bif','fcm',3,1,'2009-08-02')
insert into matches values('agf','ob',2,2,'2009-08-03')
--
insert into matches values('fcn','sif',3,0,'2009-08-08')
insert into matches values('fcm','rfc',4,1,'2009-08-09')
insert into matches values('agf','hbk',2,1,'2009-08-09')
insert into matches values('efb','ob',1,2,'2009-08-09')
insert into matches values('søn','fck',0,1,'2009-08-09')
insert into matches values('bif','aab',0,2,'2009-08-09')
--
insert into matches values('fck','agf',0,1,'2009-08-15')
insert into matches values('aab','søn',1,0,'2009-08-15')
insert into matches values('sif','efb',2,3,'2009-08-16')
insert into matches values('rfc','bif',1,3,'2009-08-16')
insert into matches values('hbk','fcn',1,1,'2009-08-16')
insert into matches values('ob','fcm',1,0,'2009-08-17')
--
insert into matches values('aab','fcn',1,0,'2009-08-19')
--
insert into matches values('fcm','fck',1,4,'2009-08-22')
insert into matches values('agf','sif',2,2,'2009-08-22')
insert into matches values('efb','aab',2,0,'2009-08-23')
insert into matches values('søn','fcn',1,0,'2009-08-23')
insert into matches values('bif','hbk',6,1,'2009-08-23')
insert into matches values('ob','rfc',1,0,'2009-08-24')
--
insert into matches values('fcn','agf',0,2,'2009-08-29')
insert into matches values('rfc','efb',0,1,'2009-08-30')
insert into matches values('hbk','søn',1,0,'2009-08-30')
insert into matches values('aab','fcm',1,0,'2009-08-30')
insert into matches values('fck','bif',1,1,'2009-08-30')
insert into matches values('sif','ob',3,1,'2009-08-31')
--
insert into matches values('ob','fck',1,1,'2009-09-12')
insert into matches values('fcm','fcn',0,2,'2009-09-12')
insert into matches values('efb','hbk',3,2,'2009-09-13')
insert into matches values('sif','søn',1,1,'2009-09-13')
insert into matches values('bif','agf',1,0,'2009-09-13')
insert into matches values('rfc','aab',0,3,'2009-09-14')
--
insert into matches values('aab','sif',0,1,'2009-09-19')
insert into matches values('hbk','ob',1,3,'2009-09-20')
insert into matches values('søn','bif',2,4,'2009-09-20')
insert into matches values('fcn','efb',0,4,'2009-09-20')
insert into matches values('fck','rfc',3,0,'2009-09-20')
insert into matches values('agf','fcm',2,4,'2009-09-14')
--
insert into matches values('ob','fcn',2,0,'2009-09-26')
insert into matches values('fcm','søn',0,2,'2009-09-27')
insert into matches values('rfc','hbk',1,1,'2009-09-27')
insert into matches values('sif','bif',4,1,'2009-09-27')
insert into matches values('aab','fck',1,2,'2009-09-27')
insert into matches values('efb','agf',3,2,'2009-09-28')
--
insert into matches values('agf','søn',2,1,'2009-10-03')
insert into matches values('rfc','sif',1,2,'2009-10-04')
insert into matches values('fck','efb',2,1,'2009-10-04')
insert into matches values('fcm','hbk',2,1,'2009-10-04')
insert into matches values('bif','fcn',6,3,'2009-10-04')
insert into matches values('ob','aab',2,1,'2009-10-05')
--
insert into matches values('fcn','ob',0,2,'2009-10-17')
insert into matches values('aab','rfc',1,1,'2009-10-18')
insert into matches values('hbk','fck',0,2,'2009-10-18')
insert into matches values('sif','efb',2,2,'2009-10-18')
insert into matches values('bif','fcm',1,1,'2009-10-18')
insert into matches values('søn','agf',1,0,'2009-10-19')
--
insert into matches values('rfc','ob',1,1,'2009-10-24')
insert into matches values('efb','søn',2,0,'2009-10-25')
insert into matches values('fcm','hbk',2,1,'2009-10-25')
insert into matches values('fck','sif',1,0,'2009-10-25')
insert into matches values('aab','bif',1,2,'2009-10-25')
insert into matches values('agf','fcn',0,2,'2009-10-26')
--
insert into matches values('agf','fcm',2,2,'2009-10-31')
insert into matches values('rfc','sif',0,2,'2009-11-01')
insert into matches values('fcn','bif',0,1,'2009-11-01')
insert into matches values('søn','hbk',0,0,'2009-11-01')
insert into matches values('efb','fck',0,0,'2009-11-01')
insert into matches values('ob','aab',1,1,'2009-11-02')
--
insert into matches values('hbk','agf',1,1,'2009-11-07')
insert into matches values('sif','ob',0,1,'2009-11-07')
insert into matches values('fcm','rfc',2,1,'2009-11-08')
insert into matches values('søn','fcn',0,1,'2009-11-08')
insert into matches values('bif','efb',2,4,'2009-11-08')
insert into matches values('aab','fck',1,0,'2009-11-08')
--
insert into matches values('hbk','fcn',1,2,'2009-11-21')
insert into matches values('fcm','efb',3,0,'2009-11-21')
insert into matches values('sif','søn',1,2,'2009-11-22')
insert into matches values('fck','rfc',2,0,'2009-11-22')
insert into matches values('bif','ob',1,3,'2009-11-22')
insert into matches values('aab','agf',0,0,'2009-11-23')
--
insert into matches values('efb','aab',1,1,'2009-11-28')
insert into matches values('rfc','søn',0,0,'2009-11-29')
insert into matches values('fcn','sif',0,1,'2009-11-29')
insert into matches values('fck','fcm',2,0,'2009-11-29')
insert into matches values('agf','bif',1,0,'2009-11-29')
insert into matches values('ob','hbk',1,0,'2009-11-30')
--
insert into matches values('søn','aab',2,0,'2009-12-05')
insert into matches values('fcn','fcm',3,0,'2009-12-06')
insert into matches values('sif','bif',3,0,'2009-12-06')
insert into matches values('rfc','hbk',2,1,'2009-12-06')
insert into matches values('ob','fck',0,2,'2009-12-06')
insert into matches values('agf','efb',1,1,'2009-12-07')
--
insert into matches values('fcm','ob',2,2,'2010-03-06')
insert into matches values('efb','rfc',0,0,'2010-03-07')
insert into matches values('hbk','sif',1,4,'2010-03-07')
insert into matches values('bif','søn',1,1,'2010-03-07')
insert into matches values('fck','agf',5,0,'2010-03-07')
insert into matches values('aab','fcn',2,1,'2010-03-08')
--
insert into matches values('ob','søn',1,1,'2010-03-13')
insert into matches values('efb','hbk',2,1,'2010-03-14')
insert into matches values('rfc','fcn',0,0,'2010-03-14')
insert into matches values('fcm','aab',2,0,'2010-03-14')
insert into matches values('fck','bif',2,0,'2010-03-14')
insert into matches values('agf','sif',1,2,'2010-03-15')
--
insert into matches values('sif','fcm',0,2,'2010-03-20')
insert into matches values('hbk','aab',0,3,'2010-03-21')
insert into matches values('fcn','efb',1,0,'2010-03-21')
insert into matches values('ob','agf',2,0,'2010-03-21')
insert into matches values('søn','fck',0,2,'2010-03-21')
insert into matches values('bif','rfc',1,1,'2010-03-22')
--
insert into matches values('fck','fcn',0,2,'2010-03-24')
insert into matches values('aab','sif',1,0,'2010-03-24')
insert into matches values('bif','hbk',1,3,'2010-03-25')
insert into matches values('efb','ob',1,2,'2010-03-25')
insert into matches values('fcm','søn',0,0,'2010-03-25')
insert into matches values('rfc','agf',2,1,'2010-03-25')
--
insert into matches values('fcn','aab',1,1,'2010-03-27')
insert into matches values('agf','fck',0,0,'2010-03-28')
insert into matches values('rfc','efb',4,0,'2010-03-28')
insert into matches values('sif','hbk',3,0,'2010-03-28')
insert into matches values('søn','bif',1,3,'2010-03-28')
insert into matches values('ob','fcm',1,2,'2010-03-29')
--
insert into matches values('efb','agf',0,4,'2010-03-31')
insert into matches values('bif','sif',2,2,'2010-04-01')
insert into matches values('fck','ob',2,0,'2010-04-01')
insert into matches values('fcm','fcn',1,0,'2010-04-01')
insert into matches values('hbk','rfc',1,2,'2010-04-01')
insert into matches values('aab','søn',1,1,'2010-04-02')
--
insert into matches values('agf','rfc',0,0,'2010-04-04')
insert into matches values('hbk','bif',1,2,'2010-04-04')
insert into matches values('fcn','fck',0,3,'2010-04-05')
insert into matches values('ob','efb',0,0,'2010-04-05')
insert into matches values('sif','aab',1,1,'2010-04-05')
insert into matches values('søn','fcm',0,2,'2010-04-05')
--
insert into matches values('agf','aab',0,2,'2010-04-10')
insert into matches values('søn','sif',4,0,'2010-04-11')
insert into matches values('efb','fcm',2,1,'2010-04-11')
insert into matches values('rfc','fck',1,0,'2010-04-11')
insert into matches values('ob','bif',0,1,'2010-04-11')
insert into matches values('fcn','hbk',1,1,'2010-04-12')
--
insert into matches values('fcm','agf',1,0,'2010-04-14')
insert into matches values('aab','ob',1,0,'2010-04-14')
insert into matches values('sif','rfc',1,3,'2010-04-14')
insert into matches values('fck','efb',3,2,'2010-04-14')
insert into matches values('hbk','søn',1,2,'2010-04-15')
insert into matches values('bif','fcn',0,1,'2010-04-15')
--
insert into matches values('fcm','fck',3,2,'2010-04-17')
insert into matches values('sif','fcn',1,4,'2010-04-18')
insert into matches values('bif','agf',1,0,'2010-04-18')
insert into matches values('søn','rfc',0,1,'2010-04-18')
insert into matches values('hbk','ob',1,2,'2010-04-18')
insert into matches values('aab','efb',0,0,'2010-04-19')
--
insert into matches values('ob','sif',1,0,'2010-04-24')
insert into matches values('agf','hbk',0,3,'2010-04-25')
insert into matches values('fck','aab',2,0,'2010-04-25')
insert into matches values('fcn','søn',3,1,'2010-04-25')
insert into matches values('efb','bif',1,1,'2010-04-25')
insert into matches values('rfc','fcm',2,0,'2010-04-26')
--
insert into matches values('sif','agf',1,4,'2010-05-01')
insert into matches values('fcn','rfc',1,1,'2010-05-02')
insert into matches values('hbk','efb',1,2,'2010-05-02')
insert into matches values('aab','fcm',3,2,'2010-05-02')
insert into matches values('bif','fck',0,2,'2010-05-02')
insert into matches values('søn','ob',2,0,'2010-05-03')
--
insert into matches values('fcm','bif',2,4,'2010-05-05')
insert into matches values('rfc','aab',3,1,'2010-05-05')
insert into matches values('fck','hbk',4,0,'2010-05-05')
insert into matches values('efb','sif',4,0,'2010-05-06')
insert into matches values('agf','søn',1,2,'2010-05-06')
insert into matches values('ob','fcn',2,1,'2010-05-06')
--
insert into matches values('fcn','agf',0,1,'2010-05-09')
insert into matches values('sif','fck',2,0,'2010-05-09')
insert into matches values('hbk','fcm',1,0,'2010-05-09')
insert into matches values('bif','aab',2,0,'2010-05-09')
insert into matches values('søn','efb',1,0,'2010-05-09')
insert into matches values('ob','rfc',1,3,'2010-05-09')
--
insert into matches values('agf','ob',0,3,'2010-05-16')
insert into matches values('rfc','bif',1,3,'2010-05-16')
insert into matches values('fck','søn',3,1,'2010-05-16')
insert into matches values('efb','fcn',3,3,'2010-05-16')
insert into matches values('aab','hbk',0,0,'2010-05-16')
insert into matches values('fcm','sif',3,0,'2010-05-16')
--

select * from teams order by points desc
update matches set homegoal = 999 where id = 33
delete from matches where id = 33