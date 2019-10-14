#1. info on posts posted with the last 10 days on our data 
#with out INDEXing ~~ 5 sec
SELECT id, owneruserid, title, commentcount 
	  FROM posts 
          WHERE creaiondate >= (SELECT Date_sub(max(creaiondate), interval 10 day) 	
									  FROM posts);

#INDEXing... 
#we don't INDEX id and owneruserid FROM posts becasue id is primary key and owneruserid is foreign key i.e already INDEXed. 
CREATE INDEX ix_posts_t 
            ON posts(title,commentcount); 
CREATE INDEX ix_posts_c 
            ON posts(creaiondate); 


#with INDEX ~~ 0.02 sec

SELECT id, owneruserid, title, commentcount 
	  FROM posts 
          WHERE creaiondate >= (SELECT Date_sub(max(creaiondate), interval 10 day) 
                                      FROM posts);

DROP INDEX ix_posts_c 
		  ON posts;
DROP INDEX ix_posts_t
          ON posts;

#2.Badge names of poster of a post commented on and voted on the same day 

CREATE INDEX ix_comment 
            ON comments(creationDate,score);
CREATE INDEX ix_vote 
            ON votes(creationDate,votetypeid);

#Without temporary table and with INDEX ~~ 2.3 sec

SELECT badges.name, owneruserid 
      FROM comments, votes, posts, badges
          WHERE Date(comments.creationDate) = votes.CreationDate AND comments.postid = votes.postid
				AND comments.score > 10 AND votetypeid = 2 AND posts.owneruserid = badges.userid; 

#With temporary table and INDEX ~~ 0.8 sec

CREATE TEMPORARY TABLE com AS
	   SELECT DISTINCT owneruserid
	         FROM comments, votes, posts
			      WHERE Date(comments.creationDate) = votes.CreationDate AND comments.score > 10 AND votetypeid = 2 AND posts.id = comments.postid;
-- DROP temporary table com; 

SELECT userid, badges.name 
	   FROM badges 
            WHERE userid IN 
                 (SELECT owneruserid 
                        FROM com); 

DROP INDEX ix_vote 
          ON votes;
DROP INDEX ix_comment 
          ON comments;

#3. Original Query 7 ~~ 5.813 sec

SELECT count(id) AS `Number of posts`,  Date(MAX(p.CreaionDate)) AS `Latest date` 
	  FROM stats.posts p
		  WHERE Date(p.CreaionDate) = (SELECT Date(MAX(p.CreaionDate))
											 FROM stats.posts p);
                        
CREATE INDEX ix_id_creaiondate 
            ON posts(id, CreaionDate);

#After INDEXing ~~ 0.187
SELECT count(id) AS `Number of posts`,  Date(MAX(p.CreaionDate)) AS `Latest date` 
	  FROM stats.posts p
           WHERE Date(p.CreaionDate) = (SELECT Date(MAX(p.CreaionDate)) 
		                                      FROM stats.posts p);
                                              
DROP INDEX ix_id_creaiondate 
           ON posts;

#4. Original Query  ~~ 6.105
SELECT DISTINCT b.Name AS `Badge Name`, b.userid AS `User Id`
	   FROM stats.badges b
		   WHERE b.UserId = (SELECT owneruserid 
								   FROM stats.posts 
									   WHERE favoritecount = (SELECT MAX(favoritecount)
																	FROM stats.posts)); 
                    

#rewrite - replacing the unnecessary subquery with a JOIN ~~ 5.4    

SELECT  b.Name AS `Badge Name`, b.userid AS `User Id`
	  FROM stats.badges b JOIN stats.posts p ON b.UserId= p.OwnerUserId 
		  WHERE p.favoritecount = 
               (SELECT MAX(favoritecount) 
					   FROM stats.posts); 

#After INDEXing with the re-written query ~~ 0.016
CREATE INDEX ix_favcount 
             ON posts(FavoriteCount);


SELECT  b.Name AS `Badge Name`, b.userid AS `User Id`
      FROM stats.badges b JOIN stats.posts p ON b.UserId= p.OwnerUserId 
           WHERE p.favoritecount = 
                (SELECT MAX(favoritecount) 
                           FROM stats.posts); 
                           
DROP INDEX ix_favcount 
		  ON posts;



# 5 and 6. Average comment count based on user's location, 25 locations which aren't null taken randomly

# 5. Average comment count based on user's location, 25 locations which aren't null taken randomly
# without INDEX ~ 3 sec
SELECT count(*) AS 'Number of Inactive Users' 
      FROM posts p
           WHERE Date(p.LasActivityDate) <= (SELECT Date(Date_sub(MAX(LasActivityDate), interval 1 year)) 
                                                    FROM posts);

CREATE INDEX lasactivitydate ON posts(LasActivityDate);

#with INDEX ~ 0.05 sec
SELECT COUNT(*) AS 'Number of Inactive Users' 
      FROM posts p
          WHERE Date(p.LasActivityDate) <= (SELECT Date(Date_sub(max(LasActivityDate), INTERVAL 1 YEAR)) 
               FROM posts);

DROP INDEX  lasactivitydate 
          ON posts;

#6. What is the title of the post that have been viewed most and includes 'bayesian' tag?
# before INDEXing ~ 1.234 sec
SELECT p.title AS `Title`, MAX(p.ViewCount) AS `Maximum view count` 
      FROM stats.posts p
          WHERE Tags LIKE '%bayesian%';

CREATE INDEX ix_title 
            ON posts (ViewCount, title, tags);
DROP INDEX ix_title 
		  ON posts;

# after adding INDEX; ~ 0.110 sec
SELECT p.title AS `Title`, MAX(p.ViewCount) AS `Maximum view count`
	  FROM stats.posts p
          WHERE Tags LIKE '%bayesian%';
