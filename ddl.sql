DROP SCHEMA IF EXISTS cooking_show;
CREATE SCHEMA cooking_show;
USE cooking_show;

-- ER UPDATES:
-- recipe also many to one with ingredient for the basic ingredient relationship
-- Cook many to many relationship with national cuisine
-- many to many ingredient nutritional info
-- na kanoyme table gia tags h oxi?
-- add season attribute to episode
-- many to many recipe-episode
-- episode count se national cuisine, cook, recipe
-- recipe: serving_size, servings attributes

CREATE TABLE app_user (
    app_user_id INT UNSIGNED NOT NULL AUTO_INCREMENT,  
    app_username VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role in ('cook', 'admin')),
    PRIMARY KEY (app_user_id)
);

CREATE TABLE recipe (
    recipe_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    is_dessert BOOLEAN NOT NULL,
    difficulty INT NOT NULL CHECK(difficulty BETWEEN 1 AND 5),
    title VARCHAR(100) NOT NULL UNIQUE,
    small_description VARCHAR(300),
    meal_type VARCHAR(200),
    tips VARCHAR(200),
    preparation_mins INT UNSIGNED NOT NULL,
    cooking_mins INT UNSIGNED NOT NULL,
    -- total_time INT AS (preparation_mins + cooking_mins),
    category VARCHAR(50) NOT NULL,
    serving_size_in_grams INT UNSIGNED NOT NULL,
    servings INT UNSIGNED NOT NULL,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3),
    national_cuisine_id INT UNSIGNED NOT NULL,
    basic_ingredient_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(recipe_id)
);

CREATE INDEX idx_recipe_title ON recipe(title);

CREATE TABLE recipe_tag(
    recipe_id INT UNSIGNED NOT NULL,
    tag VARCHAR(20) NOT NULL,
    PRIMARY KEY(recipe_id, tag),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- cooking gear
CREATE TABLE gear(
    gear_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL UNIQUE,
    instructions VARCHAR(300) NOT NULL,
    PRIMARY KEY(gear_id)
);

CREATE INDEX idx_gear_title ON gear(title);

CREATE TABLE recipe_gear(
    recipe_id INT UNSIGNED NOT NULL,
    gear_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, gear_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (gear_id) REFERENCES gear(gear_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE step (
    step_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    small_description VARCHAR(200) NOT NULL,
    ordering INT UNSIGNED NOT NULL ,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (step_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- trigger to automatically assign ordering for the recipe steps
-- ensuring the ordering is of the steps is consecutive
DELIMITER //
CREATE TRIGGER step_ordering
BEFORE INSERT ON step
FOR EACH ROW
BEGIN
    DECLARE max_order INT;

    SET max_order = 0;

    SELECT MAX(ordering) INTO max_order
    FROM step
    WHERE recipe_id = NEW.recipe_id;

    SET NEW.ordering = max_order + 1;
END;
//
DELIMITER ;

CREATE TABLE food_group(
    food_group_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(50) NOT NULL UNIQUE,
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (food_group_id)
);

CREATE INDEX idx_food_group_title ON food_group(title);
 
CREATE TABLE ingredient (
    ingredient_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL UNIQUE,
    kcal_per_100 INT NOT NULL CHECK(kcal_per_100 >= 0),
    food_group_id INT UNSIGNED NOT NULL, 
    PRIMARY KEY (ingredient_id),
    CONSTRAINT FOREIGN KEY (food_group_id) REFERENCES food_group(food_group_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_ingredient_title ON ingredient(title);

ALTER TABLE recipe 
ADD CONSTRAINT FOREIGN KEY (basic_ingredient_id) REFERENCES ingredient(ingredient_id);

DELIMITER //
CREATE TRIGGER update_recipe_category
BEFORE INSERT ON recipe
FOR EACH ROW
BEGIN
    DECLARE food_group_name VARCHAR(50);

    -- Fetch the food group name for the basic ingredient
    SELECT fg.title INTO food_group_name
    FROM food_group fg
    INNER JOIN ingredient i ON fg.food_group_id = i.food_group_id
    WHERE i.ingredient_id = NEW.basic_ingredient_id;

    -- Update the category column based on the food group name
    CASE food_group_name
        WHEN 'vegetables' THEN SET NEW.category = 'Vegetarian';
        WHEN 'red meat' THEN SET NEW.category = 'Meat';
        WHEN 'dairy' THEN SET NEW.category = 'Dairy';
        WHEN 'grains' THEN SET NEW.category = 'Grains';
        WHEN 'fruits' THEN SET NEW.category = 'Fruits';
        WHEN 'legumes' THEN SET NEW.category = 'Vegetarian';
        WHEN 'seafood' THEN SET NEW.category = 'Seafood';
        WHEN 'eggs' THEN SET NEW.category = 'Meat';
        WHEN 'white meat' THEN SET NEW.category = 'Meat';
        WHEN 'fats, oils, nuts' THEN SET NEW.category = 'Fats/Oils/Nuts';
        ELSE SET NEW.category = ''; -- Default category if no match
    END CASE;   
END;
//
DELIMITER ;

CREATE TABLE recipe_ingredient(
    recipe_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity VARCHAR(50),
    PRIMARY KEY (recipe_id, ingredient_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- calculate calories dynamically on the query
CREATE TABLE nutritional_info (
    nutritional_info_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    recipe_id INT UNSIGNED UNIQUE,
    fats INT NOT NULL CHECK(fats >= 0),
    carbohydrates INT NOT NULL CHECK(carbohydrates >= 0),
    protein INT NOT NULL CHECK(protein >= 0),
    -- calories INT CHECK(calories >= 0),
    PRIMARY KEY (nutritional_info_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE ingredient_nutritional_info (
    ingredient_id INT UNSIGNED NOT NULL,
    nutritional_info_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(ingredient_id, nutritional_info_id),
    CONSTRAINT FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (nutritional_info_id) REFERENCES nutritional_info(nutritional_info_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE national_cuisine(
    national_cuisine_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cuisine_name VARCHAR(30) NOT NULL UNIQUE,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3),
    PRIMARY KEY(national_cuisine_id)
);

CREATE INDEX idx_national_cuisine_cuisine_name ON national_cuisine(cuisine_name);

ALTER TABLE recipe
ADD CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE recipe_theme (
    recipe_theme_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(30) NOT NULL UNIQUE,
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (recipe_theme_id)
);

CREATE INDEX idx_recipe_theme_title ON recipe_theme(title);

CREATE TABLE recipe_recipe_theme (
    recipe_theme_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(recipe_theme_id, recipe_id),
    CONSTRAINT FOREIGN KEY (recipe_theme_id) REFERENCES recipe_theme(recipe_theme_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook (
    cook_id INT UNSIGNED AUTO_INCREMENT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    birthdate DATE NOT NULL,
    age INT NOT NULL,
    yrs_of_exp INT NOT NULL,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3),
    cook_rank VARCHAR(20) NOT NULL CHECK (cook_rank in('A cook', 'B cook', 'C cook', 'Chef Assistant', 'Chef')),
    PRIMARY KEY (cook_id)
);

CREATE INDEX idx_cook_first_name ON cook(first_name);
CREATE INDEX idx_cook_last_name ON cook(last_name);

CREATE TABLE cook_national_cuisine(
    cook_id INT UNSIGNED NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(cook_id, national_cuisine_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook_recipe (
    cook_id INT UNSIGNED NOT NULL,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(cook_id, recipe_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE episode (
    episode_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    episode_number INT UNSIGNED NOT NULL,
    season_number INT UNSIGNED NOT NULL,
    PRIMARY KEY (episode_id)
);

CREATE TABLE cook_cuisine_assignment (
    cook_id INT UNSIGNED NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, national_cuisine_id, episode_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE recipe_assignment (
    recipe_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, episode_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE judge_assignment (
    cook_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, episode_id),
    FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- maybe check cook_id and judge_id are not the same
CREATE TABLE rating (
    rating_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    rating_value INT NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
    cook_id INT UNSIGNED NOT NULL,
    judge_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (rating_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (judge_id) REFERENCES judge_assignment(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_rating_rating ON rating(rating_value);

CREATE TABLE image (
    image_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    image_url VARCHAR(20) NOT NULL,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (image_id)
);

CREATE VIEW total_nutritional_info AS
SELECT r.recipe_id, (r.servings*ni.fats) AS fats, (r.servings*ni.carbohydrates) AS carbohydrates, (r.servings*ni.protein) AS protein
FROM recipe r
INNER JOIN nutritional_info ni ON r.recipe_id = ni.recipe_id; 

CREATE VIEW cook_episode_count AS
SELECT c.cook_id, c.first_name, c.last_name, COUNT(*) as episode_count
FROM cook c
INNER JOIN cook_cuisine_assignment cca ON c.cook_id = cca.cook_id;
    
-- 3.1: mesos oros aksiologhsewn ana mageira
CREATE VIEW cook_mean_rating AS
SELECT c.cook_id, AVG(r.rating_value) as mean_rating
FROM cook c
INNER JOIN rating r ON c.cook_id = r.cook_id
GROUP BY c.cook_id;

-- 3.1: mesos oros aksiologhsewn ana ethnikh kouzina
CREATE VIEW national_cuisine_mean_rating AS
SELECT nc.national_cuisine_id, AVG(r.rating_value) as mean_rating
FROM national_cuisine nc
INNER JOIN cook_cuisine_assignment cca ON nc.national_cuisine_id = cca.national_cuisine_id
INNER JOIN episode e ON cca.episode_id = e.episode_id
INNER JOIN rating r ON cca.cook_id = r.cook_id AND r.episode_id = e.episode_id
GROUP BY nc.national_cuisine_id;

-- 3.3
CREATE VIEW young_cooks_with_most_recipes AS
SELECT c.cook_id, c.first_name, c.last_name, COUNT(*) as recipe_count
FROM cook c
INNER JOIN cook_recipe cr ON c.cook_id = cr.cook_id
WHERE c.age < 30
ORDER BY recipe_count DESC
LIMIT 10;

-- 3.4
CREATE VIEW never_selected_as_judge AS
SELECT c.cook_id, c.first_name, c.last_name
FROM cook c
WHERE c.cook_id NOT IN (
    SELECT ja.cook_id
    FROM judge_assignment ja
);

-- 3.5 (lathos)
CREATE VIEW judges_with_equal_episodes AS
SELECT c.cook_id, c.first_name, c.last_name, c.age, c.yrs_of_exp, c.cook_rank, COUNT(*) as episode_count
FROM cook c
INNER JOIN judge_assignment ja ON c.cook_id = ja.cook_id
GROUP BY c.cook_id
HAVING COUNT(*) = 3;

-- 3.6
CREATE VIEW most_used_tag_combinations AS 
SELECT rt1.tag, rt2.tag, COUNT(*) AS appearance_count
FROM recipe_tag rt1
JOIN recipe_tag rt2 ON rt1.recipe_id = rt2.recipe_id AND rt1.tag < rt2.tag
GROUP BY rt1.tag, rt2.tag
ORDER BY appearance_count DESC
LIMIT 3;

-- 3.6 alternative with force index
/*
SELECT rt1.tag, rt2.tag, COUNT(*) AS appearance_count
FROM recipe_tag rt1
JOIN recipe_tag rt2 ON rt1.recipe_id = rt2.recipe_id AND rt1.tag < rt2.tag
FORCE INDEX FOR GROUP BY rt1.tag, rt2.tag
ORDER BY appearance_count DESC
LIMIT 3;
*/

-- 3.7
CREATE VIEW five_less_than_the_most AS
SELECT c.cook_id, c.first_name, c.last_name, c.episode_count
FROM cook_episode_count c
WHERE (SELECT MAX(episode_count) FROM cook_episode_count) - c.episode_count >= 5;

-- 3.9
CREATE VIEW mean_carbs_per_year AS
SELECT AVG(r.servings*ni.carbohydrates) as mean_carbs_per_year, e.season_number AS yr
FROM nutritional_info ni
INNER JOIN recipe r ON ni.recipe_id = r.recipe_id
INNER JOIN recipe_assignment ra ON r.recipe_id = ra.recipe_id
INNER JOIN episode e ON ra.episode_id = e.episode_id
GROUP BY e.season_number;

-- 3.10 

-- 3.14
CREATE VIEW theme_with_most_appearances AS
SELECT rt.recipe_theme_id, rt.title, COUNT(*) as appearance_count
FROM recipe_theme rt
INNER JOIN recipe_recipe_theme rrt ON rt.recipe_theme_id = rrt.recipe_theme_id
INNER JOIN recipe_assignment ra ON rrt.recipe_id = ra.recipe_id;

-- 3.15
CREATE VIEW never_used_food_groups AS
SELECT food_group_id, title
FROM food_group 
WHERE food_group_id NOT IN (
    SELECT DISTINCT fd.food_group_id
    FROM recipe_assignment r
    INNER JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
    INNER JOIN ingredient i ON ri.ingredient_id = i.ingredient_id
    INNER JOIN food_group fd ON i.food_group_id = fd.food_group_id
);

-- This is a procedure that will be used to increment the episode count for the national cuisine used in episode number episode_no
-- and reset the episode count for the rest of the national cuisines
DELIMITER //
CREATE PROCEDURE national_cuisine_episode_count (episode_no INT, season_no INT)
BEGIN
    UPDATE national_cuisine
    SET episode_count = 
    CASE 
    WHEN national_cuisine_id IN (
        SELECT cca.national_cuisine_id
        FROM cook_cuisine_assignment cca
        INNER JOIN episode e ON cca.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season_number = season_no
    )
    THEN episode_count + 1
    ELSE 0
    END;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE cook_episode_count (episode_no INT, season_no INT)
BEGIN
    UPDATE cook
    SET episode_count = 
    CASE 
    WHEN cook_id IN (
        SELECT cca.cook_id
        FROM cook_cuisine_assignment cca
        INNER JOIN episode e ON cca.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season_number = season_no
    )
    THEN episode_count + 1
    ELSE 0
    END;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE recipe_episode_count (episode_no INT, season_no INT)
BEGIN
    UPDATE recipe
    SET episode_count = 
    CASE 
    WHEN recipe_id IN (
        SELECT cra.recipe_id
        FROM cook_recipe_assignment cra
        INNER JOIN episode e ON cra.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season_number = season_no
    )
    THEN episode_count + 1
    ELSE 0
    END;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE episode_assignments (episode_no INT, season_no INT) 
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur_cook INT; 
    DECLARE cur_nc INT;
    DECLARE cur_episode INT;
    DECLARE cursor_list CURSOR FOR SELECT cook_id, national_cuisine_id, episode_id FROM temp_cook_national_cuisine;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    CREATE TEMPORARY TABLE temp_cook_national_cuisine (
            cook_id INT UNSIGNED NOT NULL,
            national_cuisine_id INT UNSIGNED NOT NULL,
            episode_id INT UNSIGNED NOT NULL
    );

    INSERT INTO temp_cook_national_cuisine(cook_id, national_cuisine_id, episode_id)
    SELECT cnc.cook_id, nc.national_cuisine_id, e.episode_id
    FROM (
        SELECT episode_id
        FROM episode
        WHERE episode_number = episode_no AND season_number = season_no
    ) AS e
    CROSS JOIN (
        -- we randomly select 10 national cuisines that have not been used in more than 3 episodes
        SELECT nc_temp.national_cuisine_id
        FROM national_cuisine nc_temp
        WHERE nc_temp.episode_count <= 3
        ORDER BY RAND()
        LIMIT 10
    ) as nc
    INNER JOIN (
        SELECT cnc.cook_id, cnc.national_cuisine_id
        FROM (
            -- first we filter out the cooks that have participated in more than 3 episodes
            SELECT cnc_temp.cook_id, cnc_temp.national_cuisine_id
            FROM cook_national_cuisine cnc_temp
            INNER JOIN cook c ON c.cook_id = cnc_temp.cook_id
            WHERE c.episode_count <= 3
        ) AS cnc
    ) AS cnc ON cnc.national_cuisine_id = nc.national_cuisine_id;


    OPEN cursor_list;
    a_loop: LOOP 
        FETCH cursor_list INTO cur_cook, cur_nc, cur_episode;
        IF done THEN 
            LEAVE a_loop;
        END IF;
        
        IF(
            cur_cook NOT IN (
                SELECT cca.cook_id
                FROM cook_cuisine_assignment cca
                WHERE cca.episode_id = cur_episode
            )
            AND
            cur_nc NOT IN (
                SELECT cca.national_cuisine_id
                FROM cook_cuisine_assignment cca
                WHERE cca.episode_id = cur_episode
            )
        ) THEN 
        INSERT INTO cook_cuisine_assignment(cook_id, national_cuisine_id, episode_id)
        VALUES (cur_cook, cur_nc, cur_episode);
        END IF;
    END LOOP;
    CLOSE cursor_list;

    INSERT INTO cook_recipe_assignment (recipe_id, episode_id) 
    SELECT cra.recipe_id, e.episode_id
    FROM (
        SELECT episode_id
        FROM episode
        WHERE episode_number = episode_no AND season_number = season_no
    ) AS e
    CROSS JOIN (
        SELECT cr.cook_id, r.recipe_id, ROW_NUMBER() OVER (PARTITION BY cr.cook_id ORDER BY RAND()) AS row_num
        FROM (
            -- filter out the recipes that have been used in more than 3 episodes
            SELECT r.recipe_id
            FROM recipe r
            WHERE r.episode_count <= 3 
        ) AS r
        INNER JOIN cook_recipe cr ON cr.recipe_id = r.recipe_id
        INNER JOIN (
            SELECT cook_id, national_cuisine_id
            FROM cook_cuisine_assignment
            WHERE episode_id = e.episode_id
        ) AS cca ON r.national_cuisine_id = cca.national_cuisine_id AND cr.cook_id = cca.cook_id
    ) as cra
    WHERE cra.row_num = 1;

    INSERT INTO judge_assignment(cook_id, episode_id)
    SELECT c.cook_id, episode_id
    FROM (
        SELECT episode_id
        FROM episode
        WHERE episode_number = episode_no AND season_number = season_no
    ) AS e
    CROSS JOIN (
        SELECT cook_id
        FROM cook
        WHERE episode_count <= 3
        ORDER BY RAND()
    ) as c
    WHERE c.cook_id NOT IN (
        SELECT cook_id
        FROM cook_cuisine_assignment
        WHERE episode_id = e.episode_id
    )
    LIMIT 3;

    CALL national_cuisine_episode_count(episode_no, season_no);
    CALL cook_episode_count(episode_no, season_no);
    CALL recipe_episode_count(episode_no, season_no);

    DROP TEMPORARY TABLE temp_cook_national_cuisine;
END;
//
DELIMITER ;

