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
-- is_judge relationship attribute sto episode_cook

-- paradoxh: kathe mageiras mporei na ektelesei kathe syntagh ths ethnikhs kouzinas sthn opoia eidikeuetai

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
    tags VARCHAR(200), 
    preparation_mins INT UNSIGNED NOT NULL,
    cooking_mins INT UNSIGNED NOT NULL,
    -- total_time INT AS (preparation_mins + cooking_mins),
    category VARCHAR(50) NOT NULL,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3),
    national_cuisine_id INT UNSIGNED NOT NULL,
    basic_ingredient_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(recipe_id)
);

CREATE INDEX idx_recipe_title ON recipe(title);

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
    cook_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    birthdate DATE NOT NULL,
    age INT NOT NULL,
    yrs_of_exp INT NOT NULL,
    episode_count INT CHECK(episode_count BETWEEN 0 AND 3),
    cook_rank VARCHAR(20) NOT NULL CHECK (cook_rank in('A cook', 'B cook', 'C cook', 'Chef Asssistant', 'Chef')),
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
    episode_number INT NOT NULL CHECK(episode_number > 0),
    season INT NOT NULL CHECK(season > 0),
    PRIMARY KEY(episode_id)
);

CREATE TABLE episode_cook (
    episode_id INT UNSIGNED NOT NULL,
    cook_id INT UNSIGNED NOT NULL,
    is_judge BOOLEAN NOT NULL,
    PRIMARY KEY (episode_id, cook_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE episode_recipe (
    episode_id INT UNSIGNED NOT NULL,
    recipe_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (episode_id, recipe_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE episode_cuisine (
    episode_id INT UNSIGNED NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (episode_id, national_cuisine_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE rating (
    rating_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    cook_id INT UNSIGNED NOT NULL,
    episode_id INT UNSIGNED NOT NULL,
    judge_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (rating_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (judge_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook_cuisine_assignment (
    cook_id INT UNSIGNED NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    episode_number INT UNSIGNED NOT NULL,
    season_number INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, national_cuisine_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE cook_recipe_assignment (
    cook_id INT UNSIGNED NOT NULL,
    recipe_id INT UNSIGNED NOT NULL,
    episode_number INT UNSIGNED NOT NULL,
    season_number INT UNSIGNED NOT NULL,
    PRIMARY KEY (cook_id, recipe_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_rating_rating ON rating(rating);

CREATE TABLE image (
    image_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    image_url VARCHAR(20) NOT NULL,
    image_description VARCHAR(200) NOT NULL,
    PRIMARY KEY (image_id)
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
        SELECT ec.national_cuisine_id
        FROM episode_cuisine ec
        INNER JOIN episode e ON ec.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no
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
        SELECT ec.cook_id
        FROM episode_cook ec
        INNER JOIN episode e ON ec.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no
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
        SELECT er.recipe_id
        FROM episode_recipe er
        INNER JOIN episode e ON er.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no
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
    DECLARE cursor_list CURSOR FOR SELECT cook_id, national_cuisine_id FROM temp_cook_national_cuisine;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    CREATE TEMPORARY TABLE temp_cook_national_cuisine (
            cook_id INT UNSIGNED NOT NULL,
            national_cuisine_id INT UNSIGNED NOT NULL
    );

    INSERT INTO temp_cook_national_cuisine(cook_id, national_cuisine_id)
    SELECT cnc.cook_id, nc.national_cuisine_id
    FROM (
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
    ) AS cnc ON nc.national_cuisine_id = cnc.national_cuisine_id;

    OPEN cursor_list;
    a_loop: LOOP 
        FETCH cursor_list INTO cur_cook, cur_nc;
        IF done THEN 
            LEAVE a_loop;
        END IF;
        
        IF(
            cur_cook NOT IN (
                SELECT cook_id
                FROM cook_cuisine_assignment
                WHERE episode_number = episode_no AND season_number = season_no
            )
            AND
            cur_nc NOT IN (
                SELECT national_cuisine_id
                FROM cook_cuisine_assignment
                WHERE episode_number = episode_no AND season_number = season_no
            )
        ) THEN 
        INSERT INTO cook_cuisine_assignment(cook_id, national_cuisine_id, episode_number, season_number)
        VALUES (cur_cook, cur_nc, episode_no, season_no);
        END IF;
    END LOOP;
    CLOSE cursor_list;

    INSERT INTO cook_recipe_assignment(cook_id, recipe_id, episode_number, season_number) 
    SELECT cra.cook_id, cra.recipe_id, episode_no, season_no 
    FROM (
        SELECT cr.cook_id, r.recipe_id, ROW_NUMBER() OVER (PARTITION BY r.recipe_id ORDER BY RAND()) AS rank
        FROM (
            -- filter out the recipes that have been used in more than 3 episodes
            SELECT r.recipe_id
            FROM recipe r
            WHERE r.episode_count <= 3 
        ) AS r
        INNER JOIN (
            -- filter out the recipes that do not belong to the national cuisines assigned to the episode
            SELECT national_cuisine_id
            FROM cook_cuisine_assignment
            WHERE episode_number = episode_no AND season_number = season_no
        ) AS cca ON r.national_cuisine_id = cca.national_cuisine_id
        INNER JOIN cook_recipe cr ON cr.recipe_id = r.recipe_id
        INNER JOIN (
            SELECT cook_id
            FROM cook_cuisine_assignment
            WHERE episode_number = episode_no AND season_number = season_no
        ) AS cca1 ON cr.cook_id = cca1.cook_id
    ) as cra
    WHERE cra.rank = 1;

    CALL national_cuisine_episode_count(episode_no, season_no);

    DROP TEMPORARY TABLE temp_cook_national_cuisine;
END;
//
DELIMITER ;



