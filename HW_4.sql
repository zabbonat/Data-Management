create schema star; 

create table star.facttable(
	id int primary key auto_increment,
	user_id int,
    post_id int,
    tag_id varchar(100)
);
select *
from  star.user_table;
#users and badges 
create table star.user_table as
(select u.Id, u.Reputation, u.CreationDate, u.DisplayName, u.LastAccessDate, u.WebsiteUrl, 
		u.Location, u.AboutMe, u.Views, u.UpVotes, u.DownVotes, u.AccountId, 
        u.Age, u.ProfileImageUrl, b.Name, b.Date 
from stats.users u inner join stats.badges b on b.userid = u.id);



#posts, votes, commets
create table star.posts_table as
(select p.Id, p.Score, p.ViewCount, p.Body, c.Score as commentScore, c.Text, c.UserId as commenterId, 
        v.VoteTypeId, v.UserId as voterid, v.BountyAmount
 from stats.posts p inner join stats.comments c on p.id = c.postid inner join stats.votes as v on v.postid = p.id);

create table star.tags_table as select * from  stats.tags;

insert into star.facttable (user_id, post_id, tag_id) 
SELECT p.OwnerUserId, p.id as post_id, group_concat(t.id) as tag_id FROM stats.posts p, tags t
where Tags like concat('%', t.TagName,'%') group by p.id;

#drop foreign keys in facts table no need because we didn't include in the select
#alter table star.posts_table drop OwnerUserId;
#alter table star.posts_table drop Tags;
#alter table star.posts_table drop OwnerDisplayName; 
#alter table snowflake.posts_table drop LastEditorDisplayName;
#alter table snowflake.posts_table add comment_id int default null;
#alter table snowflake.posts_table add vote_id int;




#snow flake 
create schema snowflake; 

create table snowflake.facttable(
	id int primary key auto_increment,
	user_id int,
    post_id int,
    tag_id varchar(100)
);

insert into snowflake.facttable (user_id, post_id, tag_id) 
SELECT p.OwnerUserId, p.id as post_id, group_concat(t.id) as tag_id FROM stats.posts p, tags t
where Tags like concat('%', t.TagName,'%') group by p.id;

#create and insert user table with a badge id
SET session group_concat_max_len=15000;
create table snowflake.user_table as
select u.Id, u.Reputation, u.CreationDate, u.DisplayName, u.LastAccessDate, u.WebsiteUrl, 
		u.Location, u.AboutMe, u.Views, u.UpVotes, u.DownVotes, u.AccountId, 
        u.Age, u.ProfileImageUrl, group_concat(b.id) as badge_id
from stats.users u inner join stats.badges b on u.id = b.userid group by u.id; 


create table snowflake.tags_table as select * from  stats.tags;

#create and insert posts table and add comment_id and vote_id
SET session group_concat_max_len=1500000;
create table snowflake.posts_table as 
select p.Id, p.PostTypeId, p.AcceptedAnswerId, p.CreaionDate, p.Score, p.ViewCount, p.Body, p.OwnerUserId, p.LasActivityDate,
		p.Title, p.Tags, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.LastEditorUserId, p.LastEditDate, 
		p.CommunityOwnedDate, p.ParentId, p.ClosedDate,group_concat(c.id) as comment_id, group_concat(v.id) as vote_id
from stats.posts p inner join stats.comments c on p.id = c.postid inner join stats.votes v on p.id = v.postid group by p.id; 



create table snowflake.commetns_table as select * from  stats.comments;
#remove postid from commet, already do it 
alter table snowflake.commetns_table drop postid; 

create table snowflake.votes_table as select * from  stats.votes;
#remove postid from vote 
alter table snowflake.commetns_table drop postid; 

create table snowflake.badges_table as select * from  stats.badges;
#remove userid from badge
alter table snowflake.badges_table drop userid; 



RENAME TABLE snowflake.commetns_table TO snowflake.comments_table;


###############QUERY
#1) Age of the user where the difference between up votes and downvote >0 about the post wich contain text='valuable'																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									

#star schema 
select user_table.Name as Badge_of_User,  IFNULL(user_table.Age , 'NoAge') as Age_of_User
from star.user_table
where (user_table.UpVotes - user_table.DownVotes)>0 and user_table.Id in (select  facttable.user_id
																			from star.facttable, star.posts_table
                                                                            where posts_table.Body like '%valuable%');


#snowflake_schema 
select badges_table.Name as Badge_of_User,  IFNULL(user_table.Age , 'NoAge') as Age_of_User
from snowflake.user_table,snowflake.badges_table
where (user_table.UpVotes - user_table.DownVotes)>0 and user_table.Id in (select  facttable.user_id
																			from snowflake.facttable, snowflake.posts_table
                                                                            where posts_table.Body like '%valuable%');
                                                                            
                                                                            
#2)Count Tag, say the Name of badge and the User that aren't from Corvaliss where the score of the post is major/equal
#than the difference between view count and commentcount

#snowflake_schema
select tags_table.Count as Number_of_Tag, badges_table.Name as Badge_of_User, user_table.Location as Location
from snowflake.tags_table, snowflake.badges_table, snowflake.user_table,snowflake.posts_Table
where Score>=ViewCount and Location not like '%Corvallis, OR%'
#group by Location;

#starschema
select tags_table.Count as Number_of_Tag, user_table.Name as Badge_of_User, user_table.Location as Location
from star.tags_table, star.user_table,star.posts_table
where Score >=ViewCount and Location not like '%Corvallis, OR%'
#group by Location;







#########################LIWAM QUERY


SELECT
  distinct SUBSTRING_INDEX(SUBSTRING_INDEX(tag_id, ',', n.digit +1), ',', -1) tags, n.digit
FROM
  snowflake.facttable ft  
	inner join snowflake.posts_table pt on pt.id = ft.post_id 
	inner join snowflake.comments_table ct on ct.id = pt.comment_id
INNER JOIN
	(SELECT 0 digit UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 ) n
	ON LENGTH(REPLACE(tag_id, ',' , '')) <= LENGTH(tag_id)-n.digit
	where ct.score > 10;
    
    