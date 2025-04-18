DROP SCHEMA IF EXISTS cooking_show;
DROP USER IF EXISTS 'cook'@'localhost';
DROP USER IF EXISTS 'admin'@'localhost';
CREATE SCHEMA cooking_show;
USE cooking_show;

SET optimizer_trace = 'enabled=on';

-- to login as a user: mysql -u 'username' -p
-- the granted privileges are found at the end of the script
CREATE USER 'cook'@'localhost' IDENTIFIED BY 'cook';
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';

CREATE TABLE recipe (
    recipe_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    is_dessert BOOLEAN NOT NULL,    
    difficulty INT NOT NULL CHECK(difficulty BETWEEN 1 AND 5),
    title VARCHAR(100) NOT NULL UNIQUE,
    small_description VARCHAR(300),
    tips VARCHAR(400),  
    preparation_mins INT UNSIGNED NOT NULL,
    cooking_mins INT UNSIGNED NOT NULL,
    total_time INT UNSIGNED, 
    category VARCHAR(50), 
    serving_size_in_grams INT UNSIGNED NOT NULL,    
    servings INT UNSIGNED NOT NULL,     
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3), 
    national_cuisine_id INT UNSIGNED NOT NULL, 
    basic_ingredient_id INT UNSIGNED NOT NULL, 
    PRIMARY KEY(recipe_id)
);

CREATE INDEX idx_recipe_title ON recipe(title);

DELIMITER //
CREATE TRIGGER update_total_time 
BEFORE INSERT ON recipe
FOR EACH ROW
BEGIN
    SET NEW.total_time = NEW.preparation_mins + NEW.cooking_mins;
END;
//
DELIMITER ;

CREATE TABLE recipe_meal_type(
    recipe_id INT UNSIGNED NOT NULL,    
    meal_type VARCHAR(20) NOT NULL, 
    PRIMARY KEY(recipe_id, meal_type),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE recipe_tag(
    recipe_id INT UNSIGNED NOT NULL,    
    tag VARCHAR(20) NOT NULL,
    PRIMARY KEY(recipe_id, tag),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_recipe_tag_tag ON recipe_tag(tag);

-- cooking gear
CREATE TABLE gear(
    gear_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL UNIQUE,
    instructions VARCHAR(300) NOT NULL,
    PRIMARY KEY(gear_id)
);

CREATE TABLE recipe_gear(
    recipe_id INT UNSIGNED NOT NULL,
    gear_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (recipe_id, gear_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (gear_id) REFERENCES gear(gear_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE step (
    step_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    small_description VARCHAR(300) NOT NULL,
    ordering INT UNSIGNED NOT NULL DEFAULT 0,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (step_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- trigger to automatically assign ordering for the recipe steps
-- ensuring the ordering of the steps is consecutive
DELIMITER //
CREATE TRIGGER step_ordering
BEFORE INSERT ON step
FOR EACH ROW
BEGIN
    DECLARE max_order INT;

    SET max_order = 0;

    IF NEW.ordering IS NOT NULL AND NEW.recipe_id IN (SELECT recipe_id FROM step WHERE recipe_id = NEW.recipe_id) 
    THEN
    SELECT MAX(ordering) INTO max_order
    FROM step
    WHERE recipe_id = NEW.recipe_id;
    END IF;

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
 
CREATE TABLE ingredient (
    ingredient_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL UNIQUE,
    kcal_per_100 INT NOT NULL CHECK(kcal_per_100 >= 0),     
    food_group_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (ingredient_id),
    CONSTRAINT FOREIGN KEY (food_group_id) REFERENCES food_group(food_group_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

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
        WHEN 'Seasonings and Essential Oils' THEN SET NEW.category = 'Aromatic';
        WHEN 'Coffee, Tea, and Their Products' THEN SET NEW.category = 'Caffeinated';
        WHEN 'Preserved Foods' THEN SET NEW.category = 'Canned';
        WHEN 'Sweetening Substances' THEN SET NEW.category = 'Sweet';
        WHEN 'Fats and Oils' THEN SET NEW.category = 'Fatty';
        WHEN 'Milk, Eggs, and Their Products' THEN SET NEW.category = 'Dairy';
        WHEN 'Meat and Its Products' THEN SET NEW.category = 'Meat-Based';
        WHEN 'Fish and Their Products' THEN SET NEW.category = 'Seafood';
        WHEN 'Grains and Their Products' THEN SET NEW.category = 'Grain Based';
        WHEN 'Various Plant-Based Foods' THEN SET NEW.category = 'Vegetarian';
        WHEN 'Products with Sweetening Substances' THEN SET NEW.category = 'Sweets';
        WHEN 'Various Beverages' THEN SET NEW.category = 'Drinks';
        ELSE SET NEW.category = ''; -- Default category if no match
    END CASE;   
END;
//
DELIMITER ;

CREATE TABLE recipe_ingredient(
    recipe_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity VARCHAR(50) NOT NULL,       
    estimated_grams INT UNSIGNED NOT NULL, 
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
    PRIMARY KEY (nutritional_info_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE national_cuisine(
    national_cuisine_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cuisine_name VARCHAR(30) NOT NULL UNIQUE,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3), -- 0
    PRIMARY KEY(national_cuisine_id)
);

CREATE INDEX idx_national_cuisine_cuisine_name ON national_cuisine(cuisine_name);
CREATE INDEX idx_national_cuisine_episode_count ON national_cuisine(episode_count);

ALTER TABLE recipe
ADD CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE recipe_theme (
    recipe_theme_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(30) NOT NULL UNIQUE,     
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (recipe_theme_id)
);

CREATE TABLE recipe_recipe_theme (
    recipe_theme_id INT UNSIGNED NOT NULL,
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
CREATE INDEX idx_cook_episode_count ON cook(episode_count);

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
    episode_number INT UNSIGNED NOT NULL,   -- 1-10  
    season_number INT UNSIGNED NOT NULL,    -- 1-5
    PRIMARY KEY (episode_id)
);

CREATE INDEX idx_episode_episode_number ON episode(episode_number);
CREATE INDEX idx_episode_season_number ON episode(season_number);

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

DELIMITER //
CREATE TRIGGER different_cook_judge
BEFORE INSERT ON rating
FOR EACH ROW
BEGIN
    IF NEW.cook_id = NEW.judge_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cook and judge cannot be the same person';
    END IF;
END;
//
DELIMITER ;

CREATE TABLE image (
    image_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    image_url VARCHAR(20) NOT NULL,
    PRIMARY KEY (image_id)
);

CREATE TABLE recipe_image (
    recipe_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (recipe_id, image_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE gear_image (
    gear_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (gear_id, image_id),
    CONSTRAINT FOREIGN KEY (gear_id) REFERENCES gear(gear_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE food_group_image (
    food_group_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (food_group_id, image_id),
    CONSTRAINT FOREIGN KEY (food_group_id) REFERENCES food_group(food_group_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE ingredient_image (
    ingredient_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (ingredient_id, image_id),
    CONSTRAINT FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE recipe_theme_image (
    recipe_theme_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (recipe_theme_id, image_id),
    CONSTRAINT FOREIGN KEY (recipe_theme_id) REFERENCES recipe_theme(recipe_theme_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook_image (
    cook_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (cook_id, image_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE episode_image (
    episode_id INT UNSIGNED NOT NULL UNIQUE,
    image_id INT UNSIGNED NOT NULL UNIQUE,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (episode_id, image_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Views for the cook_user (he is the cook with cook_id = 1)
-- this user can alter or insert on all these views
CREATE VIEW cook_user_info AS 
SELECT c.cook_id, c.first_name, c.last_name, c.phone_number, c.birthdate, c.age, c.yrs_of_exp, c.episode_count, c.cook_rank
FROM cook c
WHERE c.cook_id = 1;

CREATE VIEW cook_user_recipes AS
SELECT r.recipe_id, r.title, r.preparation_mins, r.cooking_mins, r.total_time, r.category, r.serving_size_in_grams, r.servings, r.episode_count, r.national_cuisine_id, r.basic_ingredient_id
FROM recipe r
INNER JOIN cook_recipe cr ON r.recipe_id = cr.recipe_id
WHERE cr.cook_id = 1;

CREATE VIEW cook_user_steps AS  
SELECT s.step_id, s.small_description, s.ordering, s.recipe_id
FROM step s
INNER JOIN recipe r ON s.recipe_id = r.recipe_id
INNER JOIN cook_recipe cr ON r.recipe_id = cr.recipe_id
WHERE cr.cook_id = 1;

CREATE VIEW cook_user_ingredients AS
SELECT i.ingredient_id, i.title, i.kcal_per_100, i.food_group_id, ri.quantity, ri.estimated_grams, r.recipe_id
FROM ingredient i
INNER JOIN recipe_ingredient ri ON i.ingredient_id = ri.ingredient_id
INNER JOIN recipe r ON ri.recipe_id = r.recipe_id
INNER JOIN cook_recipe cr ON r.recipe_id = cr.recipe_id
WHERE cr.cook_id = 1;

CREATE VIEW cook_user_gear AS
SELECT g.gear_id, g.title, g.instructions, r.recipe_id, rg.quantity
FROM gear g
INNER JOIN recipe_gear rg ON g.gear_id = rg.gear_id
INNER JOIN recipe r ON rg.recipe_id = r.recipe_id
INNER JOIN cook_recipe cr ON r.recipe_id = cr.recipe_id
WHERE cr.cook_id = 1;

-- total rating for each cook for all episodes
CREATE VIEW total_cook_rating AS
SELECT c.cook_id, c.first_name, c.last_name, SUM(r.rating_value) as total_rating
FROM cook c
INNER JOIN rating r ON c.cook_id = r.cook_id
GROUP BY c.cook_id, c.first_name, c.last_name;

-- dynamically calculating the calories for each recipe 
CREATE VIEW total_nutritional_info AS
SELECT r.recipe_id, SUM(ri.estimated_grams*i.kcal_per_100/100)/r.servings AS calories, ni.fats, ni.carbohydrates, ni.protein
FROM recipe r
INNER JOIN nutritional_info ni ON r.recipe_id = ni.recipe_id
INNER JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
INNER JOIN ingredient i ON ri.ingredient_id = i.ingredient_id
GROUP BY r.recipe_id, ni.fats, ni.carbohydrates, ni.protein;

-- total episode participations for each cook
CREATE VIEW cook_episode_count AS
SELECT c.cook_id, c.first_name, c.last_name, COUNT(*) as episode_count
FROM cook c
INNER JOIN cook_cuisine_assignment cca ON c.cook_id = cca.cook_id
GROUP BY c.cook_id;

-- Assigning a numeric value to the cook rank
-- this is created for 3.13 query
CREATE VIEW cook_rank_numeric AS
SELECT cook_id, cook_rank,
    CASE 
        WHEN cook_rank = 'A cook' THEN 1
        WHEN cook_rank = 'B cook' THEN 2
        WHEN cook_rank = 'C cook' THEN 3
        WHEN cook_rank = 'Chef Assistant' THEN 4
        WHEN cook_rank = 'Chef' THEN 5
    END AS rank_numeric
FROM cook;
    
-- total rating for each cook in each episode
CREATE VIEW episode_cook_rating AS
SELECT r.episode_id, r.cook_id, cr.rank_numeric, SUM(r.rating_value) as total_rating
FROM rating r 
INNER JOIN cook_rank_numeric cr ON r.cook_id = cr.cook_id
GROUP BY r.episode_id, r.cook_id, cr.rank_numeric
ORDER BY r.episode_id, total_rating DESC;

-- 3.1: mesos oros aksiologhsewn ana mageira
CREATE VIEW cook_mean_rating AS
SELECT c.cook_id, c.first_name, c.last_name, AVG(r.rating_value) as mean_rating
FROM cook c
INNER JOIN rating r ON c.cook_id = r.cook_id
GROUP BY c.cook_id, c.first_name, c.last_name;

-- 3.1: mesos oros aksiologhsewn ana ethnikh kouzina
CREATE VIEW national_cuisine_mean_rating AS
SELECT nc.national_cuisine_id, nc.cuisine_name, AVG(r.rating_value) as mean_rating
FROM national_cuisine nc
INNER JOIN cook_cuisine_assignment cca ON nc.national_cuisine_id = cca.national_cuisine_id
INNER JOIN episode e ON cca.episode_id = e.episode_id
INNER JOIN rating r ON cca.cook_id = r.cook_id AND r.episode_id = e.episode_id
GROUP BY nc.national_cuisine_id, nc.cuisine_name;

-- 3.2 
DELIMITER //
CREATE PROCEDURE cuisine_year_cook_participations (IN season_no INT, IN cuisine_name VARCHAR(30))
BEGIN
    -- we create a temporary table to store the cook_id, national_cuisine_id, and a flag to indicate if the cook has participated in the episode
    CREATE TEMPORARY TABLE temp (
        cook_id INT UNSIGNED NOT NULL,
        national_cuisine_id INT UNSIGNED NOT NULL,
        participated INT DEFAULT 0
    );

    -- insert into the temporary table the cook_id and national_cuisine_id of all the cooks that are associated with the national cuisine
    INSERT INTO temp(cook_id, national_cuisine_id)
    SELECT cnc.cook_id, nc.national_cuisine_id
    FROM national_cuisine nc
    INNER JOIN cook_national_cuisine cnc ON nc.national_cuisine_id = cnc.national_cuisine_id
    WHERE nc.cuisine_name = cuisine_name;

    -- update the participated flag for the cooks that have participated in any episode of the season
    UPDATE temp
    SET participated = 1
    WHERE cook_id IN (
        SELECT cook_id
        FROM cook_cuisine_assignment cca
        INNER JOIN (
            SELECT e.episode_id
            FROM episode e
            WHERE e.season_number = season_no
        ) AS e ON cca.episode_id = e.episode_id
        INNER JOIN (
            SELECT nc.national_cuisine_id
            FROM national_cuisine nc
            WHERE nc.cuisine_name = cuisine_name
        )AS nc ON cca.national_cuisine_id = nc.national_cuisine_id    
    );

    SELECT cuisine_name, season_no, c.first_name, c.last_name, t.participated
    FROM temp t
    INNER JOIN cook c ON t.cook_id = c.cook_id;

    DROP TEMPORARY TABLE temp;
END;
//
DELIMITER ;

-- 3.3
CREATE VIEW young_cooks_with_most_recipes AS
SELECT c.cook_id, c.first_name, c.last_name, COUNT(*) as recipe_count
FROM cook c
INNER JOIN cook_recipe cr ON c.cook_id = cr.cook_id
WHERE c.age < 30
GROUP BY c.cook_id
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

-- 3.5
-- first we create a view that contains the episode count for each judge in each season
CREATE VIEW judges_episode_count_per_year AS
SELECT j.cook_id, j.first_name, j.last_name, e.season_number, COUNT(*) as episode_count
FROM judge_assignment ja
INNER JOIN episode e ON ja.episode_id = e.episode_id
INNER JOIN cook j ON ja.cook_id = j.cook_id
GROUP BY j.cook_id, e.season_number
HAVING COUNT(*) > 3
ORDER BY episode_count DESC;

CREATE VIEW judges_with_equal_episode_count AS 
SELECT j1.cook_id AS judge_id_1, j1.first_name AS judge_first_name_1, j1.last_name AS judge_last_name_1, j2.cook_id AS judge_id_2, j2.first_name AS judge_first_name_2, j2.last_name AS judge_last_name_2, j1.episode_count AS judge_1_episode_count, j2.episode_count AS judge_2_episode_count
FROM judges_episode_count_per_year j1
INNER JOIN judges_episode_count_per_year j2 ON j1.cook_id < j2.cook_id AND j1.episode_count = j2.episode_count
ORDER BY j1.episode_count DESC;

-- 3.6
CREATE VIEW most_used_tag_combinations AS 
SELECT rt1.tag AS tag_1, rt2.tag AS tag_2, COUNT(*) AS appearance_count
FROM recipe_tag rt1
JOIN recipe_tag rt2 ON rt1.recipe_id = rt2.recipe_id AND rt1.tag < rt2.tag
GROUP BY rt1.tag, rt2.tag
ORDER BY appearance_count DESC
LIMIT 3;

-- 3.6 alternative with force index
CREATE VIEW most_used_tag_combinations_alt AS
SELECT rt1.tag AS tag_1, rt2.tag AS tag_2, COUNT(*) AS appearance_count
FROM recipe_tag rt1 FORCE INDEX (idx_recipe_tag_tag)
JOIN recipe_tag rt2 FORCE INDEX (idx_recipe_tag_tag)
ON rt1.recipe_id = rt2.recipe_id AND rt1.tag < rt2.tag
GROUP BY rt1.tag, rt2.tag 
ORDER BY appearance_count DESC
LIMIT 3;

-- 3.7 
CREATE VIEW five_less_than_the_most AS
SELECT c.cook_id, c.first_name, c.last_name, c.episode_count
FROM cook_episode_count c
WHERE (SELECT MAX(episode_count) FROM cook_episode_count) - c.episode_count <= 5;

-- 3.8
CREATE VIEW episode_with_most_gear AS
SELECT e.episode_id, e.episode_number, e.season_number, SUM(rg.quantity) as total_gear
FROM episode e
INNER JOIN recipe_assignment ra ON e.episode_id = ra.episode_id
INNER JOIN recipe_gear rg ON ra.recipe_id = rg.recipe_id
GROUP BY e.episode_id
ORDER BY total_gear DESC
LIMIT 1;

-- 3.8 alternative
CREATE VIEW episode_with_most_gear_alt AS
SELECT e.episode_id, e.episode_number, e.season_number, COUNT(*) as total_gear
FROM episode e
INNER JOIN recipe_assignment ra ON e.episode_id = ra.episode_id
INNER JOIN recipe_gear rg ON ra.recipe_id = rg.recipe_id
GROUP BY e.episode_id
ORDER BY total_gear DESC
LIMIT 1;

-- 3.9
CREATE VIEW mean_carbs_per_year AS
SELECT AVG(r.servings*ni.carbohydrates) AS mean_carbs_per_year, e.season_number AS yr
FROM nutritional_info ni
INNER JOIN recipe r ON ni.recipe_id = r.recipe_id
INNER JOIN recipe_assignment ra ON r.recipe_id = ra.recipe_id
INNER JOIN episode e ON ra.episode_id = e.episode_id
GROUP BY e.season_number;

-- 3.10
-- we want to find which national cuisine have the same number of participations the span of two consecutive seasons
-- for this query we will create two views
-- the first view will contain the number of participations for each national cuisine in each season and it will work as a helper view
-- the second view will contain the national cuisines that have the same number of participations in two consecutive seasons

CREATE VIEW cuisine_yearly_participations AS
SELECT nc.cuisine_name, e.season_number, COUNT(*) as episode_count
FROM national_cuisine nc
INNER JOIN cook_cuisine_assignment cca ON nc.national_cuisine_id = cca.national_cuisine_id
INNER JOIN episode e ON cca.episode_id = e.episode_id
GROUP BY nc.cuisine_name, e.season_number
HAVING COUNT(*) > 3
ORDER BY episode_count DESC;

CREATE VIEW cuisine_two_year_participations AS
SELECT cyp1.cuisine_name, cyp1.season_number AS season_number_1, cyp2.season_number AS season_number_2, (cyp1.episode_count+cyp2.episode_count) as episode_count
FROM cuisine_yearly_participations cyp1
INNER JOIN cuisine_yearly_participations cyp2 ON cyp1.cuisine_name = cyp2.cuisine_name
WHERE cyp1.season_number = cyp2.season_number - 1
GROUP BY cyp1.cuisine_name, cyp1.season_number, cyp2.season_number
ORDER BY episode_count DESC;

CREATE VIEW cuisine_equal_two_year_participations AS
SELECT cyp1.cuisine_name AS cuisine_1, cyp2.cuisine_name AS cuisine_2, cyp1.episode_count
FROM cuisine_two_year_participations cyp1
INNER JOIN cuisine_two_year_participations cyp2 ON cyp1.cuisine_name < cyp2.cuisine_name AND cyp1.episode_count = cyp2.episode_count
ORDER BY cyp1.episode_count DESC;

-- 3.11 
CREATE VIEW top_rating_judges AS
SELECT tr.judge_first_name, tr.judge_last_name, tr.cook_first_name, tr.cook_last_name , tr.total_rating
FROM (
    SELECT r.judge_id, j.first_name AS judge_first_name, j.last_name AS judge_last_name , r.cook_id, c.first_name AS cook_first_name, c.last_name AS cook_last_name, SUM(r.rating_value) AS total_rating
    FROM rating r
    INNER JOIN cook j ON j.cook_id = r.judge_id
    INNER JOIN cook c ON c.cook_id = r.cook_id
    GROUP BY r.judge_id, r.cook_id
    ORDER BY total_rating DESC
    LIMIT 5
) AS tr;

-- 3.12
CREATE VIEW hardest_recipes_episode AS
SELECT e.episode_id, e.episode_number, e.season_number, SUM(r.difficulty) AS total_difficulty
FROM episode e
INNER JOIN recipe_assignment ra ON e.episode_id = ra.episode_id
INNER JOIN recipe r ON ra.recipe_id = r.recipe_id
GROUP BY e.episode_id
ORDER BY total_difficulty DESC
LIMIT 1;

-- 3.13
CREATE VIEW lowest_total_rank_episode AS
SELECT episode_id, episode_number, season_number, SUM(rank_numeric) AS total_rank
FROM (
    SELECT e.episode_id, e.episode_number, e.season_number, c.cook_id, crn.rank_numeric
    FROM episode e
    INNER JOIN cook_cuisine_assignment cca ON e.episode_id = cca.episode_id
    INNER JOIN cook c ON cca.cook_id = c.cook_id
    INNER JOIN cook_rank_numeric crn ON c.cook_id = crn.cook_id
    UNION ALL
    SELECT e.episode_id, e.episode_number, e.season_number, j.cook_id, jrn.rank_numeric
    FROM episode e
    INNER JOIN judge_assignment ja ON e.episode_id = ja.episode_id
    INNER JOIN cook j ON ja.cook_id = j.cook_id
    INNER JOIN cook_rank_numeric jrn ON j.cook_id = jrn.cook_id
) AS combined_assignments
GROUP BY episode_id, episode_number, season_number
ORDER BY total_rank ASC
LIMIT 1;

-- 3.14
CREATE VIEW theme_with_most_appearances AS
SELECT rt.recipe_theme_id, rt.title, COUNT(*) as appearance_count
FROM recipe_theme rt
INNER JOIN recipe_recipe_theme rrt ON rt.recipe_theme_id = rrt.recipe_theme_id
INNER JOIN recipe_assignment ra ON rrt.recipe_id = ra.recipe_id
GROUP BY rt.recipe_theme_id, rt.title;

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

-- This is a procedure that will be used to increment the episode count for the national cuisines used in a specific episode
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

-- This is a procedure that will be used to increment the episode count for the cooks used in a specific episode
-- and reset the episode count for the rest of the cooks
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

-- This is a procedure that will be used to increment the episode count for the recipes used in a specific episode
-- and reset the episode count for the rest of the recipes
DELIMITER //
CREATE PROCEDURE recipe_episode_count (episode_no INT, season_no INT)
BEGIN
    UPDATE recipe
    SET episode_count = 
    CASE 
    WHEN recipe_id IN (
        SELECT cra.recipe_id
        FROM recipe_assignment cra
        INNER JOIN episode e ON cra.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season_number = season_no
    )
    THEN episode_count + 1
    ELSE 0
    END;
END;
//
DELIMITER ;

-- This is a procedure that will be used to assign cooks, national cuisines, recipes, and judges to an episode
DELIMITER //
CREATE PROCEDURE episode_assignments (episode_no INT, season_no INT) 
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE exact_episode_id INT UNSIGNED;
    DECLARE cur_cook INT; 
    DECLARE cur_nc INT;
    DECLARE cur_episode INT;
    DECLARE cursor_list CURSOR FOR SELECT cook_id, national_cuisine_id, episode_id FROM temp_cook_national_cuisine;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- this table will contain 10 randomly selected national cuisines that have not been used in more than 3 episodes
    -- and all the cooks that have not participated in more than 3 episodes and are associated with the selected national cuisines
    CREATE TEMPORARY TABLE temp_cook_national_cuisine (
            cook_id INT UNSIGNED NOT NULL,
            national_cuisine_id INT UNSIGNED NOT NULL,
            episode_id INT UNSIGNED NOT NULL
    );

    SET exact_episode_id = (
        SELECT episode_id
        FROM episode
        WHERE episode_number = episode_no AND season_number = season_no
    );

    -- if it is the first episode of the season, reset the episode count for national cuisines, cooks, and recipes
    IF episode_no = 1
    THEN 
    UPDATE national_cuisine SET episode_count = 0;
    UPDATE cook SET episode_count = 0;
    UPDATE recipe SET episode_count = 0;    
    END IF;

    INSERT INTO temp_cook_national_cuisine(cook_id, national_cuisine_id, episode_id)
    SELECT cnc.cook_id, nc.national_cuisine_id, exact_episode_id
    FROM (
        -- we randomly select 10 national cuisines that have not been used in more than 3 episodes
        SELECT nc_temp.national_cuisine_id
        FROM national_cuisine nc_temp
        WHERE nc_temp.episode_count < 3
        ORDER BY RAND()
        LIMIT 10
    ) as nc
    INNER JOIN (
        SELECT cnc.cook_id, cnc.national_cuisine_id
        FROM (
            -- we filter out the cooks that have participated in more than 3 episodes
            SELECT cnc_temp.cook_id, cnc_temp.national_cuisine_id
            FROM cook_national_cuisine cnc_temp
            INNER JOIN cook c ON c.cook_id = cnc_temp.cook_id
            WHERE c.episode_count < 3
        ) AS cnc
    ) AS cnc ON cnc.national_cuisine_id = nc.national_cuisine_id
    ORDER BY RAND();

    -- insert into cook_cuisine_assignment table 
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

    -- populate recipe_assignment table
    INSERT INTO recipe_assignment (recipe_id, episode_id) 
    SELECT cra.recipe_id, exact_episode_id
    FROM (
        SELECT cca.national_cuisine_id, r.recipe_id, ROW_NUMBER() OVER (PARTITION BY cca.national_cuisine_id ORDER BY RAND()) AS row_num
        FROM (
            -- filter out the recipes that have been used in more than 3 episodes
            SELECT r.recipe_id, r.national_cuisine_id
            FROM recipe r
            WHERE r.episode_count < 3 
        ) AS r
        -- INNER JOIN cook_recipe cr ON cr.recipe_id = r.recipe_id -- if we decide that its not necessary for a cook to be assigned a recipe he knows we can remove this join
        INNER JOIN (
            SELECT cook_id, national_cuisine_id
            FROM cook_cuisine_assignment
            WHERE episode_id = exact_episode_id
        ) AS cca ON r.national_cuisine_id = cca.national_cuisine_id
    ) as cra
    WHERE cra.row_num = 1;


    -- the cook must now know the recipe he is assigned in the episode 
    -- so we insert the recipe into the cook_recipe table
    INSERT INTO cook_recipe (cook_id, recipe_id)
    SELECT cca.cook_id, ra.recipe_id
    FROM (
        SELECT cca.cook_id, cca.national_cuisine_id
        FROM cook_cuisine_assignment cca
        WHERE cca.episode_id = exact_episode_id
    ) AS cca 
    INNER JOIN (
        SELECT r.recipe_id, r.national_cuisine_id
        FROM recipe r
        INNER JOIN recipe_assignment ra ON r.recipe_id = ra.recipe_id
        WHERE ra.episode_id = exact_episode_id
    ) AS ra ON cca.national_cuisine_id = ra.national_cuisine_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM cook_recipe cr
        WHERE cr.cook_id = cca.cook_id AND cr.recipe_id = ra.recipe_id
    ); 

    INSERT INTO judge_assignment(cook_id, episode_id)
    SELECT c.cook_id, exact_episode_id
    FROM (
        SELECT cook_id
        FROM cook
        WHERE episode_count < 3
    ) as c
    WHERE c.cook_id NOT IN (
        SELECT cook_id
        FROM cook_cuisine_assignment
        WHERE episode_id = exact_episode_id
    )
    ORDER BY RAND()
    LIMIT 3;

    CALL national_cuisine_episode_count(episode_no, season_no);
    CALL cook_episode_count(episode_no, season_no);
    CALL recipe_episode_count(episode_no, season_no);

    DROP TEMPORARY TABLE temp_cook_national_cuisine;
END;
//
DELIMITER ;

DELIMITER //

CREATE PROCEDURE declare_winners()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE currect_episode_id INT;
    DECLARE cook_cursor CURSOR FOR 
        SELECT DISTINCT episode_id 
        FROM episode_cook_rating;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cook_cursor;
    
    read_loop: LOOP
        FETCH cook_cursor INTO currect_episode_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Create a temporary table to hold the cooks for the current episode
        CREATE TEMPORARY TABLE temp_episode_cooks AS
        SELECT cook_id, total_rating, rank_numeric
        FROM episode_cook_rating
        WHERE episode_id = currect_episode_id;

        -- Find the cook with the highest rating
        -- ORDER BY first sorts by total rating and if there is a tie, it sorts by expertise, and if there is still a tie, it sorts randomly
        SELECT cook_id, total_rating, rank_numeric 
        INTO @cook_id, @max_rating, @max_expertise
        FROM temp_episode_cooks
        ORDER BY total_rating DESC, rank_numeric DESC, RAND()
        LIMIT 1;

        SELECT currect_episode_id AS episode_id, @cook_id AS cook_id, @max_rating AS rating, @max_expertise AS rank_numeric;

        -- Drop the temporary table
        DROP TEMPORARY TABLE temp_episode_cooks;
    END LOOP;
    
    CLOSE cook_cursor;
END //

DELIMITER ;

GRANT INSERT, UPDATE, SELECT ON cooking_show.cook_user_recipes TO 'cook'@'localhost';
GRANT INSERT, UPDATE, SELECT ON cooking_show.cook_user_steps TO 'cook'@'localhost';
GRANT INSERT, UPDATE, SELECT ON cooking_show.cook_user_ingredients TO 'cook'@'localhost';
GRANT INSERT, UPDATE, SELECT ON cooking_show.cook_user_gear TO 'cook'@'localhost';
GRANT UPDATE, SELECT ON cooking_show.cook_user_info TO 'cook'@'localhost';
GRANT INSERT, SELECT ON cooking_show.recipe TO 'cook'@'localhost';
GRANT ALL PRIVILEGES ON cooking_show.* TO 'admin'@'localhost';
