
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS app_user;
DROP TABLE IF EXISTS recipe;
DROP TABLE IF EXISTS meal_type;
DROP TABLE IF EXISTS recipe_meal_type;
DROP TABLE IF EXISTS gear;
DROP TABLE IF EXISTS recipe_gear;
DROP TABLE IF EXISTS step;
DROP TABLE IF EXISTS food_group;
DROP TABLE IF EXISTS ingredient;
DROP TABLE IF EXISTS recipe_ingredient;
DROP TABLE IF EXISTS nutritional_info;
DROP TABLE IF EXISTS ingredient_nutritional_info;
DROP TABLE IF EXISTS national_cuisine;
DROP TABLE IF EXISTS recipe_theme;
DROP TABLE IF EXISTS recipe_recipe_theme;
DROP TABLE IF EXISTS cook;
DROP TABLE IF EXISTS cook_national_cuisine;
DROP TABLE IF EXISTS cook_recipe;
DROP TABLE IF EXISTS episode;
DROP TABLE IF EXISTS episode_cook;
DROP TABLE IF EXISTS episode_cuisine;
DROP TABLE IF EXISTS rating;
DROP TABLE IF EXISTS image;


SET FOREIGN_KEY_CHECKS = 1;

-- ER UPDATES:
-- recipe also many to one with ingredient for the basic ingredient relationship
-- Cook many to many relationship with national cuisine
-- meal type table 
-- many to many ingredient nutritional info
-- na kanoyme table gia tags h oxi?

CREATE TABLE app_user (
    app_user_id INT NOT NULL,
    app_username VARCHAR(20) NOT NULL,
    password VARCHAR(20) NOT NULL,
    type varchar(20) NOT NULL CHECK (type in ('cook', 'admin')),
    PRIMARY KEY (app_user_id)
);

CREATE TABLE recipe (
    recipe_id INT NOT NULL,
    is_dessert BOOLEAN NOT NULL,
    difficulty INT NOT NULL CHECK(difficulty BETWEEN 1 AND 5),
    title VARCHAR(100) NOT NULL,
    small_description varchar(300),
    tips VARCHAR(200),
    preparation_mins INT NOT NULL,
    cooking_mins INT NOT NULL,
    -- total_time INT AS (preparation_mins + cooking_mins),
    -- category varchar(50) NOT NULL,
    national_cuisine_id INT NOT NULL,
    basic_ingredient_id INT NOT NULL,
    PRIMARY KEY(recipe_id)
);

CREATE TABLE meal_type (
    meal_type_id INT NOT NULL,
    title VARCHAR(30) NOT NULL,
    PRIMARY KEY (meal_type_id)
);

CREATE TABLE recipe_meal_type (
    recipe_id INT NOT NULL,
    meal_type_id INT NOT NULL,
    PRIMARY KEY (recipe_id, meal_type_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id),
    CONSTRAINT FOREIGN KEY (meal_type_id) REFERENCES meal_type(meal_type_id)
);

-- cooking gear
CREATE TABLE gear(
    gear_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    instructions VARCHAR(300) NOT NULL,
    PRIMARY KEY(gear_id)
);

CREATE TABLE recipe_gear(
    recipe_id INT NOT NULL,
    gear_id INT NOT NULL,
    PRIMARY KEY (recipe_id, gear_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id),
    CONSTRAINT FOREIGN KEY (gear_id) REFERENCES gear(gear_id)
);

-- step
CREATE TABLE step (
    step_id INT NOT NULL,
    small_description VARCHAR(200) NOT NULL,
    ordering INT NOT NULL CHECK(ordering > 0),
    recipe_id INT NOT NULL,
    PRIMARY KEY (step_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id)
);
/*
CREATE OR REPLACE TRIGGER trg_step_ordering_consecutive
BEFORE INSERT OR UPDATE ON step FOR EACH ROW 
BEGIN
    IF NEW.ordering <= 0 THEN
        RAISE EXCEPTION 'Ordering value must be greater than zero';
    END IF;
    
    IF EXISTS (SELECT 1 FROM step WHERE Ordering = NEW.ordering AND recipeID = NEW.recipeID) THEN
        RAISE EXCEPTION 'Ordering value must be unique within the recipe';
    END IF;
    
    IF NEW.ordering <> 1 AND NOT EXISTS (SELECT 1 FROM step WHERE Ordering = NEW.ordering - 1 AND recipeID = NEW.recipeID) THEN
        RAISE EXCEPTION 'Ordering values must be consecutive';
    END IF;
    
    RETURN NEW;
END;
*/

-- Food Group

CREATE TABLE food_group(
    food_group_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (food_group_id)
);

-- ingredients 
CREATE TABLE ingredient (
    ingredient_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    kcal_per_100 INT NOT NULL CHECK(kcal_per_100 >= 0),
    food_group_id INT NOT NULL, 
    PRIMARY KEY (ingredient_id),
    CONSTRAINT FOREIGN KEY (food_group_id) REFERENCES food_group(food_group_id)
);

ALTER TABLE recipe 
ADD CONSTRAINT FOREIGN KEY (basic_ingredient_id) REFERENCES ingredient(ingredient_id);

CREATE TABLE recipe_ingredient(
    recipe_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity VARCHAR(50),
    PRIMARY KEY (recipe_id, ingredient_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id),
    CONSTRAINT FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id)
);

-- Nutritional Info per seving

-- calculate calories dynamically on the query
CREATE TABLE nutritional_info (
    nutritional_info_id INT NOT NULL,
    recipe_id INT UNIQUE,
    fats INT NOT NULL CHECK(fats >= 0),
    carbohydrates INT NOT NULL CHECK(carbohydrates >= 0),
    protein INT NOT NULL CHECK(protein >= 0),
    -- calories INT CHECK(calories >= 0),
    PRIMARY KEY (nutritional_info_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id)
);

CREATE TABLE ingredient_nutritional_info (
    ingredient_id INT NOT NULL,
    nutritional_info_id INT NOT NULL,
    PRIMARY KEY(ingredient_id, nutritional_info_id),
    CONSTRAINT FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id),
    CONSTRAINT FOREIGN KEY (nutritional_info_id) REFERENCES nutritional_info(nutritional_info_id)
);

-- National Cuisine

CREATE TABLE national_cuisine(
    national_cuisine_id INT NOT NULL,
    cuisine_name VARCHAR(30) NOT NULL,
    PRIMARY KEY(national_cuisine_id)
);

ALTER TABLE recipe
ADD CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id);


-- recipe Theme

CREATE TABLE recipe_theme (
    recipe_theme_id INT NOT NULL,
    title VARCHAR(30) NOT NULL,
    small_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (recipe_theme_id)
);

CREATE TABLE recipe_recipe_theme (
    recipe_theme_id INT NOT NULL,
    recipe_id INT NOT NULL,
    PRIMARY KEY(recipe_theme_id, recipe_id),
    CONSTRAINT FOREIGN KEY (recipe_theme_id) REFERENCES recipe_theme(recipe_theme_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id)
);

-- cook


CREATE TABLE cook (
    cook_id INT NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    birthdate DATE NOT NULL,
    age INT NOT NULL,
    yrs_of_exp INT NOT NULL,
    cook_rank VARCHAR(20) NOT NULL CHECK (cook_rank in('A cook', 'B cook', 'C cook', 'Chef Asssistant', 'Chef')),
    PRIMARY KEY (cook_id)
);

CREATE TABLE cook_national_cuisine(
    cook_id INT NOT NULL,
    national_cuisine_id INT NOT NULL,
    PRIMARY KEY(cook_id, national_cuisine_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id),
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id)
);

CREATE TABLE cook_recipe (
    cook_id INT NOT NULL,
    recipe_id INT NOT NULL,
    PRIMARY KEY(cook_id, recipe_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id),
    CONSTRAINT FOREIGN KEY (recipe_id) REFERENCES recipe(recipe_id)
);

CREATE TABLE episode (
    episode_id INT NOT NULL,
    episode_number INT NOT NULL CHECK(episode_number > 0),
    PRIMARY KEY(episode_id)
);

CREATE TABLE episode_cook (
    episode_id INT NOT NULL,
    cook_id INT NOT NULL,
    PRIMARY KEY (episode_id, cook_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id)
);

CREATE TABLE episode_cuisine (
    episode_id INT NOT NULL,
    national_cuisine_id INT NOT NULL,
    PRIMARY KEY (episode_id, national_cuisine_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id),
    CONSTRAINT FOREIGN KEY (national_cuisine_id) REFERENCES national_cuisine(national_cuisine_id)
);

CREATE TABLE rating (
    rating_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    cook_id INT NOT NULL,
    episode_id INT NOT NULL,
    judge_id INT NOT NULL,
    PRIMARY KEY (rating_id),
    CONSTRAINT FOREIGN KEY (cook_id) REFERENCES cook(cook_id),
    CONSTRAINT FOREIGN KEY (episode_id) REFERENCES episode(episode_id),
    CONSTRAINT FOREIGN KEY (judge_id) REFERENCES cook(cook_id)
);

CREATE TABLE image (
    image_id INT NOT NULL,
    image_url VARCHAR(20) NOT NULL,
    PRIMARY KEY (image_id)
);