#1) How many total point have users having id ≥0  (-1 is server)?

create view stats.totalPoints(`User Id`  , `Number of posts`, Votes , Reputations , Views , `Total Point`) as
	(SELECT owneruserId as Id, count(*) as `Number of posts`, (UpVotes-DownVotes) as 
	votes, reputation, views, (views + reputation + (UpVotes-DownVotes) + count(*)) as `Total Point`
	FROM stats.posts join stats.users as u on owneruserid = u.id group by owneruserid having id >= 0 order by `Total point` desc);
#see the view
select * from stats.totalpoints; 


#2)Which is the average point for each badge? 

select b.name as `Badge Name`, round(avg(`total point`),2) as `Average Point` 
from stats.totalpoints as tp 
join stats.badges as b on tp.`User id` = b.userid 
group by b.name 
order by `Average Point` desc;


#3)Who are User Id of questioner and answerer belonging to the same badge?

select distinct p2.owneruserid as `Questioner ID`, p1.owneruserid as `Answerer ID` 
from stats.posts as p1, stats.posts as p2, stats.badges as b1, stats.badges as b2 
where p1.id = p2.acceptedanswerid and b2.userid = p2.owneruserid and b1.userid = p1.owneruserid and b2.name = b1.name;

#4)Which are posts asked by non critic answered by a critic?

select p1.id as `Post Id`,p1.ParentId as `Id of question post`, IFNULL(p1.Title, 'No Title') as `Title`, p1.body as `Post` 
from stats.posts as p1, stats.posts as p2 , stats.badges as b 
where p1.id = p2.acceptedanswerid and p1.owneruserid = b.userid and b.name = 'critic'
	and p2.owneruserid not in (SELECT userid 
								FROM stats.badges 
								where name = 'critic');


#5)Which are profile picture url of commenteres between the age of 20 and 25?

select distinct IFNULL (users.ProfileImageUrl,'nourlpic') as `Profile Url Pic`, users.Id as `Id User`, users.Age 
from stats.users, stats.comments
where  users.Id = comments.UserId and users.Age between 20 and 45
order by age asc;


#6)Which are comments of each post with score greater than 0?

select IFNULL (comments.UserDisplayName,'NoName') as `User Name`, comments.score as Score , comments.Text as Comments , posts.Title 
from stats.comments
right join stats.posts
on posts.Id=comments.PostId
where comments.score>0 ; 

#right join because comment.postid will exist in posts, but a post may not have a comment


#7)How many posts are released on the latest day?
select count(*) as `Number of posts`,  max(p.CreaionDate) as `Latest date`
from stats.posts p
where p.CreaionDate = (select max(p.CreaionDate) 
						from stats.posts p);


#8)Which are the Badge categories of the user with the max favourite count?
select distinct b.Name as `Badge Name`, b.userid as `User Id`
from stats.badges b
where b.UserId = (select owneruserid 
					from stats.posts 
					where favoritecount = (select max(favoritecount) from stats.posts)); 


#9)What is the title of the post viewed most and that includes ‘bayesian’ ?
select p.title as `Title`, max(p.ViewCount) as `Maximum view count`
from stats.posts p
where Tags like '%bayesian%';


#10)Which is the average comment count based on user’s location (25 stray location)?
select IFNULL(u.Location,'NoLocation') as Location, avg(CommentCount) as `Average Comment Count`
from stats.posts as p
left join stats.users as u on p.OwnerUserId = u.Id
group by u.Location
having avg(upvotes) > 1000
order by 2 desc
limit 25; 





