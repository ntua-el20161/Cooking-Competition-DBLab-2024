DROP SCHEMA IF EXISTS cooking_show;
CREATE SCHEMA cooking_show;
USE cooking_show;

-- TODO:
-- update query 3.8
-- add alternative queries for 3.6 and 3.8
-- ratings table (automata?)
-- diakyrhksh nikhth apo kathe epeisodio (view?)
-- images table
-- steps table
-- users relationship with cooks?

-- 21/5 UPDATES:
-- quantity sto recipe gear relationship
-- total_time = cooking_mins + preparation_mins sto recipe

-- ER UPDATES:
-- recipe also many to one with ingredient for the basic ingredient relationship
-- Cook many to many relationship with national cuisine
-- many to many ingredient nutritional info (UPDATE 21/5: this table is deleted)
-- add season attribute to episode
-- many to many recipe-episode
-- episode count se national cuisine, cook, recipe
-- recipe: serving_size, servings attributes

-- PARADOXES:
-- prin apo thn enarksh tou diagwnismou kathe mageiras sysxetizetai hdh me enan arithmo syntagwn
-- h syntagh pou kaleitai na ektelesei kathe mageiras se ena epeisodio einai mia syntagh pou kserei (dhladh o mageiras sxetizetai me th syntagh sto table cook_recipe)
-- kathe mageiras sysxetizetai mono me syntages mias ethnikhs kouzinas pou kserei
-- se kathe epeisodio epilegontai 10 ethnikes kouzines kai gia thn kathe mia enas antiproswpos mageiras (o mageiras prepei na sysxetizetai me thn sygkekrimenh kouzina)
-- o arithmos synexomenwn symmetoxwn einai enas gia kathe mageira dhladh h symmetoxh metraei ston idio metrhth eite o mageiras symmeteixe san kriths eite san diagwnizomenos
-- 

CREATE TABLE app_user (
    app_user_id INT UNSIGNED NOT NULL AUTO_INCREMENT,  
    app_username VARCHAR(20) NOT NULL UNIQUE,
    password VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role in ('cook', 'admin')),
    PRIMARY KEY (app_user_id)
);

CREATE TABLE recipe (
    recipe_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    is_dessert BOOLEAN NOT NULL,    -- 0 h 1 an einai glyko h oxi
    difficulty INT NOT NULL CHECK(difficulty BETWEEN 1 AND 5),
    title VARCHAR(100) NOT NULL UNIQUE,
    small_description VARCHAR(300),
    tips VARCHAR(400),  -- ena string xwrismeno me komata pou tha exei mexri 3 tips
    preparation_mins INT UNSIGNED NOT NULL,
    cooking_mins INT UNSIGNED NOT NULL,
    total_time INT UNSIGNED, -- tha ginei update apo trigger
    category VARCHAR(50), -- valto NULL giati tha ginei update apo trigger 
    serving_size_in_grams INT UNSIGNED NOT NULL,    -- posa grammaria einai mia merida (oti noumero thes)
    servings INT UNSIGNED NOT NULL,     -- meta thn ektelesh twn vhmatwn pou leei sthn ekfwnhsh prokyptoun servings (oti noumero thes)
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3), -- 0 
    national_cuisine_id INT UNSIGNED NOT NULL, -- to id ths ethnikhs kouzinas pou anhkei h syntagh
    basic_ingredient_id INT UNSIGNED NOT NULL,  -- to id tou basikou yliou ths syntaghs
    PRIMARY KEY(recipe_id)
);

CREATE INDEX idx_recipe_title ON recipe(title);
CREATE INDEX idx_recipe_category ON recipe(servings);

DELIMITER //
CREATE TRIGGER update_total_time 
BEFORE INSERT ON recipe
FOR EACH ROW
BEGIN
    SET NEW.total_time = NEW.preparation_mins + NEW.cooking_mins;
END;
//
DELIMITER ;

-- morfh geumatos ths syntaghs (prwino, mesimeriano, bradino, klp)
CREATE TABLE recipe_meal_type(
    recipe_id INT UNSIGNED NOT NULL,    -- id syntaghs pou einai tetoiou typou geumatos
    meal_type VARCHAR(20) NOT NULL, -- onoma tou meal type
    PRIMARY KEY(recipe_id, meal_type),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- tag ths syntaghs
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
    small_description VARCHAR(200) NOT NULL,
    ordering INT UNSIGNED DEFAULT 0, -- vale times analoga me thn seira twn vhmatwn (1o vhma 1, 2o vhma 2, klp) alla ta xeirizetai kai trigger an apla ta valeis insert me th seira kai valeis null auto to pedio
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
    kcal_per_100 INT NOT NULL CHECK(kcal_per_100 >= 0),     -- thermides ana 100 g
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
    quantity VARCHAR(50) NOT NULL,       -- posothta pou xrhsimopoieitai apo to sygkekrimeno yliko pou den einai safws orismenh (px ligo aleuri, mia koutalia klp)
    estimated_grams INT UNSIGNED NOT NULL,  -- posa grammaria peripou einai auth h posothta pou xrhsimopoieitai
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
    title VARCHAR(30) NOT NULL UNIQUE,      -- thematikh enothta syntaghs (pasxalinh, xristougenniatikh, klp)
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (recipe_theme_id)
);

CREATE INDEX idx_recipe_theme_title ON recipe_theme(title);

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

-- 5 sezon apo 10 epeisodia h kathe mia 
-- kathe zeugos epeisodio sezon prepei na einai monadiko px s1e1, s1e2, s1e3, klp
CREATE TABLE episode (
    episode_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    episode_number INT UNSIGNED NOT NULL,   -- 1-10  
    season_number INT UNSIGNED NOT NULL,    -- 1-5
    PRIMARY KEY (episode_id)
);

CREATE INDEX idx_episode_episode_number ON episode(episode_number);
CREATE INDEX idx_episode_season_number ON episode(season_number);

-- gemizei automata
CREATE TABLE cook_cuisine_assignment (
    cook_id INT UNSIGNED NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, national_cuisine_id, episode_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- gemizei automata
CREATE TABLE recipe_assignment (
    recipe_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, episode_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- gemizei automata
CREATE TABLE judge_assignment (
    cook_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, episode_id),
    FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- asto pros to parwn
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

CREATE TRIGGER different_cook_judge AS
BEFORE INSERT ON rating
FOR EACH ROW
BEGIN
    IF NEW.cook_id = NEW.judge_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cook and judge cannot be the same person';
    END IF;
END;

CREATE TABLE image (
    image_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    image_url VARCHAR(20) NOT NULL,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (image_id)
);

CREATE TABLE recipe_image (
    recipe_id INT UNSIGNED NOT NULL,
    image_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, image_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook_image (
    cook_id INT UNSIGNED NOT NULL,
    image_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, image_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (image_id) REFERENCES image(image_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE 

CREATE VIEW recipe_total_time AS
SELECT r.recipe_id, r.title, r.preparation_mins + r.cooking_mins AS total_time
FROM recipe r;

CREATE VIEW total_nutritional_info AS
SELECT r.recipe_id, SUM(ri.estimated_grams*i.kcal_per_100/100)/r.servings AS calories, ni.fats, ni.carbohydrates, ni.protein
FROM recipe r
INNER JOIN nutritional_info ni ON r.recipe_id = ni.recipe_id
INNER JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
INNER JOIN ingredient i ON ri.ingredient_id = i.ingredient_id;

CREATE VIEW cook_episode_count AS
SELECT c.cook_id, c.first_name, c.last_name, COUNT(*) as episode_count
FROM cook c
INNER JOIN cook_cuisine_assignment cca ON c.cook_id = cca.cook_id;

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
    
-- 3.1: mesos oros aksiologhsewn ana mageira
CREATE VIEW cook_mean_rating AS
SELECT c.first_name, c.last_name, AVG(r.rating_value) as mean_rating
FROM cook c
INNER JOIN rating r ON c.cook_id = r.cook_id
GROUP BY c.first_name, c.last_name;

-- 3.1: mesos oros aksiologhsewn ana ethnikh kouzina
CREATE VIEW national_cuisine_mean_rating AS
SELECT nc.cuisine_name, AVG(r.rating_value) as mean_rating
FROM national_cuisine nc
INNER JOIN cook_cuisine_assignment cca ON nc.national_cuisine_id = cca.national_cuisine_id
INNER JOIN episode e ON cca.episode_id = e.episode_id
INNER JOIN rating r ON cca.cook_id = r.cook_id AND r.episode_id = e.episode_id
GROUP BY nc.cuisine_name;

-- 3.2 review
DELIMITER //
CREATE PROCEDURE cuisine_year_cook_participations (IN season_no INT, IN cuisine_name VARCHAR(30))
BEGIN
    CREATE TEMPORARY TABLE temp (
        cook_id INT UNSIGNED NOT NULL,
        national_cuisine_id INT UNSIGNED NOT NULL,
        participated INT DEFAULT 0
    );

    INSERT INTO temp(cook_id, national_cuisine_id)
    SELECT c.cook_id, nc.national_cuisine_id
    FROM national_cuisine nc
    INNER JOIN cook_national_cuisine cnc ON nc.national_cuisine_id = cnc.national_cuisine_id
    WHERE nc.cuisine_name = cuisine_name;

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
            SELECT national_cuisine_id
            FROM national_cuisine
            WHERE cuisine_name = cuisine_name
        )AS nc ON cca.national_cuisine_id = nc.national_cuisine_id    
    );

    SELECT cuisine_name, season_no, c.cook_first_name, c.cook_last_name, t.participated
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
CREATE VIEW judges_with_equal_episodes AS
SELECT j.cook_id, j.first_name, j.last_name, e.season_number, COUNT(*) as episode_count
FROM judge_assignment ja
INNER JOIN episode e ON ja.episode_id = e.episode_id
INNER JOIN cook j ON ja.cook_id = j.cook_id
GROUP BY ja.cook_id, e.season_number
HAVING COUNT(*) > 3
ORDER BY episode_count DESC;

-- 3.6
CREATE VIEW most_used_tag_combinations AS 
SELECT rt1.tag AS tag_1, rt2.tag AS tag_2, COUNT(*) AS appearance_count
FROM recipe_tag rt1
JOIN recipe_tag rt2 ON rt1.recipe_id = rt2.recipe_id AND rt1.tag < rt2.tag
GROUP BY rt1.tag, rt2.tag
ORDER BY appearance_count DESC
LIMIT 3;

-- 3.6 alternative with force index
/*
CREATE VIEW most_used_tag_combinations_alt AS
SELECT rt1.tag AS tag_1, rt2.tag AS tag_2, COUNT(*) AS appearance_count
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
CREATE VIEW cuisine_yearly_participations AS
SELECT nc.cuisine_name, e.season_number, COUNT(*) as episode_count
FROM national_cuisine nc
INNER JOIN cook_cuisine_assignment cca ON nc.national_cuisine_id = cca.national_cuisine_id
INNER JOIN episode e ON cca.episode_id = e.episode_id
GROUP BY nc.cuisine_name, e.season_number
HAVING COUNT(*) > 3
ORDER BY episode_count DESC;

CREATE VIEW cuisine_two_year_participations AS
SELECT cyp1.cuisine_name, COUNT(*) as episode_count
FROM cuisine_yearly_participations cyp1
INNER JOIN cuisine_yearly_participations cyp2 ON cyp1.cuisine_name = cyp2.cuisine_name
WHERE cyp1.season_number = cyp2.season_number - 1
GROUP BY cyp1.cuisine_name, cyp1.season_number, cyp2.season_number
ORDER BY episode_count DESC;    

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
GROUP BY episode_id
ORDER BY total_rank ASC
LIMIT 1;

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

    IF episode_no = 1
    THEN (
        UPDATE national_cuisine SET episode_count = 0;
        UPDATE cook SET episode_count = 0;
        UPDATE recipe SET episode_count = 0;
    )
    END IF;

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


-- First attempt at a procedure to find cooks under 30 with the most recipes
-- todo: check if this is correct
DELIMITER //


CREATE PROCEDURE find_cooks_with_most_recipes_under_30()
BEGIN
    -- Select cook information along with recipe count
    SELECT c.cook_id, c.first_name, c.last_name, c.age, COUNT(r.recipe_id) AS recipe_count
    FROM cook c
    LEFT JOIN recipe r ON c.cook_id = r.cook_id
    WHERE c.age < 30
    GROUP BY c.cook_id, c.first_name, c.last_name, c.age
    ORDER BY recipe_count DESC; -- Order by recipe count in descending order
END //

DELIMITER ;
