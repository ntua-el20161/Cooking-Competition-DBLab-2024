DROP SCHEMA IF EXISTS cooking_show;
CREATE SCHEMA cooking_show;
USE cooking_show;

-- ER UPDATES:
-- recipe also many to one with ingredient for the basic ingredient relationship
-- Cook many to many relationship with national cuisine
-- meal type table (?)
-- many to many ingredient nutritional info
-- na kanoyme table gia tags h oxi?
-- add season attribute to episode

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
    small_description varchar(300),
    tips VARCHAR(200),
    preparation_mins INT UNSIGNED NOT NULL,
    cooking_mins INT UNSIGNED NOT NULL,
    -- total_time INT AS (preparation_mins + cooking_mins),
    category VARCHAR(50) NOT NULL,
    national_cuisine_id INT UNSIGNED NOT NULL,
    basic_ingredient_id INT UNSIGNED NOT NULL,
    PRIMARY KEY(recipe_id)
);

CREATE INDEX idx_recipe_title ON recipe(title);

CREATE TABLE meal_type (
    meal_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(30) NOT NULL,
    PRIMARY KEY (meal_type_id)
);

CREATE TABLE recipe_meal_type (
    recipe_id INT UNSIGNED NOT NULL,
    meal_type_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (recipe_id, meal_type_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (meal_type_id) REFERENCES meal_type(meal_type_id) ON DELETE RESTRICT ON UPDATE CASCADE
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
    cook_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    birthdate DATE NOT NULL,
    age INT NOT NULL,
    yrs_of_exp INT NOT NULL,
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
    PRIMARY KEY (episode_id, cook_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id) ON DELETE RESTRICT ON UPDATE CASCADE
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
CREATE PROCEDURE increment_reset_episode_count (episode_no INT)
BEGIN
    UPDATE national_cuisine
    SET episode_count = episode_count + 1
    WHERE national_cuisine_id IN (
        SELECT ec.national_cuisine_id
        FROM episode_cuisine ec
        INNER JOIN episode e ON ec.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no
    );

    UPDATE national_cuisine
    SET episode_count = 0
    WHERE national_cuisine_id NOT IN (
        SELECT ec.national_cuisine_id
        FROM episode_cuisine ec
        INNER JOIN episode e ON ec.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no
    );
END;
//
DELIMITER ;

-- This is a procedure that will be used to assign 10 random national cuisines to an episode
DELIMITER //
CREATE PROCEDURE proc_episode_assignments (episode_no INT, season_no INT) 
BEGIN
    CREATE LOCAL TEMPORARY TABLE episode_assignments (
        episode_assignments_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
        episode_id INT UNSIGNED NOT NULL,
        national_cuisine_id INT UNSIGNED NOT NULL,
        cook_id INT UNSIGNED NOT NULL,
        recipe_id INT UNSIGNED NOT NULL,
        PRIMARY KEY (episode_assignments_id)
    );

    INSERT INTO episode_assignments(episode_id, national_cuisine_id, cook_id, recipe_id)
    SELECT e.episode_id, nc.national_cuisine_id, cnc.cook_id, r.recipe_id
    FROM episode e
    CROSS JOIN (
        SELECT national_cuisine_id
        FROM national_cuisine
        WHERE episode_count <= 3
    ) AS nc
    INNER JOIN (
        SELECT cnc_temp.cook_id, cnc_temp.national_cuisine_id
        FROM cook_national_cuisine cnc_temp
        INNER JOIN cook c ON c.cook_id = cnc_temp.cook_id
        WHERE c.episode_count <= 3
    ) AS cnc ON cnc.national_cuisine_id = nc.national_cuisine_id
    INNER JOIN (
        SELECT r_temp.recipe_id
        FROM recipe r_temp
        WHERE r_temp.episode_count <= 3
    ) AS r ON r.national_cuisine_id = nc.national_cuisine_id
    WHERE e.episode_number = episode_no AND e.season = season_no    -- maybe move this at the start of the query
    ORDER BY RAND()
    LIMIT 10;

    /*INSERT INTO episode_cuisine(episode_id, national_cuisine_id)
    SELECT e.episode_id, nc.national_cuisine_id
    FROM episode e
    CROSS JOIN (
        SELECT national_cuisine_id
        FROM national_cuisine
        WHERE episode_count <= 3
        ORDER BY RAND()
        LIMIT 10
    ) AS nc
    WHERE e.episode_number = episode_no AND e.season = season_no;
    */
    CALL increment_reset_episode_count(episode_no);
END;
//
DELIMITER ;

/*
DELIMITER //
CREATE PROCEDURE episode_cook_assignments (episode_no INT, season_no INT) 
BEGIN   
    INSERT INTO episode_cook(episode_id, cook_id)
    SELECT e.episode_id, c.cook_id
    FROM episode e
    CROSS JOIN (
        SELECT c.cook_id
        FROM cook c
        INNER JOIN cook_national_cuisine cnc 
        ON c.cook_id = cnc.cook_id
        INNER JOIN episode_cuisine ec
        ON cnc.national_cuisine_id = ec.national_cuisine_id
        INNER JOIN episode e
        ON ec.episode_id = e.episode_id
        WHERE e.episode_number = episode_no AND e.season = season_no AND c.episode_count <= 3
        ORDER BY RAND()
        LIMIT 10
    ) AS c
END;
// 
DELIMITER ;

*/
