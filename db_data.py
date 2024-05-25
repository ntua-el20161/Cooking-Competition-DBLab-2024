import mysql.connector
import random
import string
import json
from datetime import datetime, timedelta
from itertools import product

# Function to execute SQL queries
def execute_query(connection, query, data=None):
    cursor = connection.cursor()
    if data:
        cursor.execute(query, data)
    else:
        cursor.execute(query)
    connection.commit()

# Connect to your MySQL database
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    port="3306",  # Adjust the port if necessary
    password="root",
    database="cooking_show"
)

if conn.is_connected():
    print("Connected to MySQL database")

# Function to reset auto-increment ID to start from 1
def reset_auto_increment(table_name):
    query = f"ALTER TABLE {table_name} AUTO_INCREMENT = 1"
    execute_query(conn, query)

# Function to delete existing contents of a table
def delete_existing_data(table_name):
    query = f"DELETE FROM {table_name}"
    execute_query(conn, query)

# Function to generate random usernames and passwords
def generate_random_string(length):
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def generate_random_url():
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=20))
# Function to generate dummy data for app_user table
def generate_dummy_users(num_users):
    usernames = set()
    roles = ['cook', 'admin']

    # Ensure at least one admin
    admin_generated = False

    query = "INSERT INTO app_user (app_username, password, role) VALUES (%s, %s, %s)"

    for i in range(num_users):
        while True:
            username = generate_random_string(8)
            if username not in usernames:
                usernames.add(username)
                break

        password = generate_random_string(10)

        # Ensure only one admin
        if not admin_generated:
            role = random.choice(roles)
            if(role == 'admin'): admin_generated = True
        else:
            role = 'cook'

        data = (username, password, role)
        execute_query(conn, query, data)

# Function to generate dummy data for cook table
def generate_dummy_cooks(num_cooks):
    # List of standard first and last names
    first_names = ['John', 'Emma', 'Michael', 'Sophia', 'William', 'Olivia', 'James', 'Amelia', 'Benjamin', 'Isabella', 'Daniel', 'Mia', 'Matthew', 'Charlotte', 'Jackson', 'Evelyn', 'Samuel', 'Harper', 'David', 'Abigail']
    last_names = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson']

    # Generate permutations of first and last names to create unique combinations
    name_combinations = list(product(first_names, last_names))

    query = "INSERT INTO cook (first_name, last_name, phone_number, birthdate, age, yrs_of_exp, episode_count, cook_rank) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
    for i in range(num_cooks):
        first_name, last_name = random.choice(name_combinations)
        phone_number = f"{random.randint(1000000000, 9999999999)}"
        birthdate = datetime.now() - timedelta(days=random.randint(20*365, 60*365))
        age = datetime.now().year - birthdate.year
        max_years_of_exp = age - 18
        yrs_of_exp = random.randint(1, max_years_of_exp)
        episode_count = 0  # Set episode count to 0
        cook_rank = random.choice(['A cook', 'B cook', 'C cook', 'Chef Assistant', 'Chef'])
        data = (first_name, last_name, phone_number, birthdate, age, yrs_of_exp, episode_count, cook_rank)
        execute_query(conn, query, data)

# Define gear data
gear_data = [
    ("Chef's Knife", "Use for chopping, slicing, and dicing."),
    ("Cutting Board", "Place ingredients on this surface for cutting."),
    ("Mixing Bowls", "Use for mixing ingredients."),
    ("Measuring Cups", "Measure liquid ingredients accurately."),
    ("Measuring Spoons", "Measure dry and liquid ingredients accurately."),
    ("Whisk", "Use for blending and mixing ingredients."),
    ("Spatula", "Use for flipping food items."),
    ("Tongs", "Use for flipping and gripping hot food items."),
    ("Grater", "Use for grating cheese, vegetables, etc."),
    ("Peeler", "Use for peeling fruits and vegetables."),
    ("Rolling Pin", "Use for rolling out dough."),
    ("Pastry Brush", "Use for applying egg wash or glaze."),
    ("Oven Mitts", "Use to handle hot dishes and pans."),
    ("Baking Sheet", "Use for baking cookies, sheet cakes, etc."),
    ("Mixing Spoon", "Use for stirring ingredients."),
    ("Strainer", "Use for draining pasta or washing vegetables."),
    ("Colander", "Use for draining pasta, rice, etc."),
    ("Chef's Apron", "Wear to protect clothing from spills and stains."),
    ("Kitchen Timer", "Use to time cooking and baking."),
    ("Food Thermometer", "Use to check the internal temperature of cooked foods."),
    ("Kitchen Scale", "Use for precise measurement of ingredients."),
    ("Can Opener", "Use to open cans."),
    ("Kitchen Shears", "Use for cutting herbs, vegetables, and meat."),
    ("Potato Masher", "Use for mashing cooked potatoes or other vegetables."),
    ("Salad Spinner", "Use for drying washed salad greens."),
    ("Pizza Cutter", "Use for cutting pizza."),
    ("Ice Cream Scoop", "Use for scooping ice cream."),
    ("Wine Opener", "Use to open wine bottles."),
    ("Citrus Juicer", "Use for juicing citrus fruits."),
    ("Garlic Press", "Use for mincing garlic."),
    ("Ladle", "Use for serving soups and sauces."),
    ("Corkscrew", "Use for opening wine bottles."),
    ("Mortar and Pestle", "Use for grinding spices and herbs."),
    ("Cookie Cutter", "Use for cutting cookie dough."),
    ("Basting Brush", "Use for applying marinades."),
    ("Pot Holder", "Use to protect hands from hot pots and pans."),
    ("Ice Cube Tray", "Use for making ice cubes."),
    ("Egg Separator", "Use for separating egg whites and yolks."),
    ("Vegetable Peeler", "Use for peeling vegetables."),
    ("Meat Tenderizer", "Use for tenderizing meat."),
    ("Cheese Slicer", "Use for slicing cheese."),
    ("Egg Slicer", "Use for slicing hard-boiled eggs."),
    ("Cake Tester", "Use for testing if cakes are done."),
    ("Funnels", "Use for transferring liquids."),
    ("Pie Weights", "Use for blind baking pie crusts."),
    ("Candy Thermometer", "Use for making candy."),
    ("Corn Holders", "Use for eating corn on the cob."),
    ("Apple Corer", "Use for coring apples."),
    ("Avocado Slicer", "Use for slicing and pitting avocados."),
    ("Biscuit Cutter", "Use for cutting biscuit dough."),
    ("Nutcracker", "Use for cracking nuts."),
    ("Pasta Fork", "Use for serving pasta."),
    ("Paring Knife", "Use for intricate cutting tasks."),
    ("Utility Knife", "Use for general cutting tasks."),
    ("Bread Knife", "Use for slicing bread."),
    ("Filleting Knife", "Use for filleting fish."),
    ("Carving Knife", "Use for carving meats."),
    ("Cheese Knife", "Use for cutting cheese."),
    ("Butter Knife", "Use for spreading butter."),
    ("Cake Server", "Use for serving cake."),
    ("Sushi Mat", "Use for rolling sushi."),
    ("Bread Box", "Use for storing bread."),
    ("Salt and Pepper Grinder", "Use for grinding salt and pepper."),
    ("Coffee Grinder", "Use for grinding coffee beans."),
    ("Tea Infuser", "Use for brewing loose leaf tea."),
    ("Muffin Pan", "Use for baking muffins."),
    ("Cake Pan", "Use for baking cakes."),
    ("Pie Pan", "Use for baking pies."),
    ("Casserole Dish", "Use for baking casseroles."),
    ("Roasting Pan", "Use for roasting meats."),
    ("Springform Pan", "Use for baking cheesecakes."),
    ("Bundt Pan", "Use for baking bundt cakes."),
    ("Loaf Pan", "Use for baking bread loaves."),
    ("Soufflé Dish", "Use for baking soufflés."),
    ("Tart Pan", "Use for baking tarts."),
    ("Quiche Pan", "Use for baking quiches."),
    ("Bain Marie", "Use for gentle cooking or keeping food warm."),
    ("Food Processor", "Use for chopping and blending ingredients."),
    ("Blender", "Use for blending smoothies and soups."),
    ("Stand Mixer", "Use for mixing dough and batters."),
    ("Hand Mixer", "Use for mixing smaller batches of ingredients."),
    ("Toaster", "Use for toasting bread."),
    ("Toaster Oven", "Use for baking and toasting."),
    ("Microwave", "Use for quick heating and cooking.")
]

# Function to insert gear data into the database
def insert_gear_data(gear_data):
    query = "INSERT INTO gear (title, instructions) VALUES (%s, %s)"
    for gear in gear_data:
        execute_query(conn, query, gear)

# Food group data with English titles and small descriptions
food_group_data = [
    ("Seasonings and Essential Oils", "Various herbs, spices, and essential oils used to flavor food."),
    ("Coffee, Tea, and Their Products", "Beverages and products derived from coffee and tea plants."),
    ("Preserved Foods", "Foods preserved through canning, drying, or other methods."),
    ("Sweetening Substances", "Natural and artificial sweeteners used to add sweetness to foods."),
    ("Fats and Oils", "Edible fats and oils used in cooking and baking."),
    ("Milk, Eggs, and Their Products", "Dairy and egg products used in various culinary applications."),
    ("Meat and Its Products", "Various types of meat and meat-based products."),
    ("Fish and Their Products", "Fish and seafood products."),
    ("Grains and Their Products", "Whole grains and grain-based products like bread and pasta."),
    ("Various Plant-Based Foods", "A variety of foods derived from plants."),
    ("Products with Sweetening Substances", "Foods and beverages containing added sweeteners."),
    ("Various Beverages", "Different types of drinks, including non-alcoholic and alcoholic beverages.")
]

# Function to generate dummy data for food_group table
def generate_dummy_food_groups(food_group_data):
    query = "INSERT INTO food_group (title, small_description) VALUES (%s, %s)"
    for food_group in food_group_data:
        execute_query(conn, query, food_group)

# List of sample cuisine names for the national_cuisine table
cuisine_names = [
    "Italian", "Chinese", "Japanese", "Mexican", "Indian", "French",
    "Thai", "Spanish", "Greek", "Turkish", "Moroccan", "Vietnamese",
    "Korean", "Brazilian", "Peruvian", "Ethiopian", "Lebanese", "Russian",
    "Caribbean", "German","British", "Argentinian", "Indonesian",
    "Malaysian", "Swedish", "Polish", "Australian", "South African", "Canadian", "American"
]

# Function to generate dummy data for national_cuisine table
def generate_dummy_cuisines(num_cuisines):
    # Ensure there are enough cuisine names to cover the requested number of dummy entries
    if num_cuisines > len(cuisine_names):
        raise ValueError("Not enough unique cuisine names available. Reduce the number of dummy entries or add more cuisine names.")

    # Generate and insert cuisines
    query = "INSERT INTO national_cuisine (cuisine_name, episode_count) VALUES (%s, %s)"
    for i in range(num_cuisines):
        cuisine_name = cuisine_names[i]
        episode_count = 0
        data = (cuisine_name, episode_count)
        execute_query(conn, query, data)


# Function to generate dummy data for ingredients
def generate_dummy_ingredients(num_ingredients):
    # Sample ingredients data with titles, kcal_per_100, and corresponding food group names
    ingredients_data = [
        ("Apple", 52, 10), ("Banana", 89, 10), ("Carrot", 41, 10), ("Spinach", 23, 10),
        ("Rice", 130, 9), ("Bread", 265, 9), ("Milk", 42, 6), ("Cheese", 402, 6),
        ("Chicken", 165, 7), ("Meat", 180, 7), ("Kebab", 215, 7), ("Veal", 170, 7), ("Pork", 220, 7), ("Chicken Wings", 165, 7), ("Salmon", 208, 8), ("Fish", 208, 8), ("Clam", 208, 8), ("Lettuce", 15, 10),
        ("Tomato", 18, 10), ("Onion", 40, 10), ("Potato", 77, 10), ("Broccoli", 34, 10),
        ("Egg", 155, 6), ("Beef", 250, 7), ("Shrimp", 99, 8), ("Pasta", 131, 9),
        ("Olive Oil", 884, 5), ("Lemon", 29, 1), ("Garlic", 149, 1), ("Honey", 304, 4),
        ("Cucumber", 15, 10), ("Avocado", 160, 10), ("Yogurt", 61, 6), ("Oats", 389, 9),
        ("Cabbage", 25, 10), ("Green Beans", 31, 10), ("Bell Pepper", 31, 10),
        ("Lime", 30, 1), ("Pineapple", 50, 10), ("Strawberry", 32, 10), ("Blueberry", 57, 10),
        ("Kiwi", 61, 10), ("Peach", 39, 10), ("Grapes", 69, 10), ("Watermelon", 30, 10),
        ("Cherry", 50, 10), ("Mango", 60, 10), ("Pear", 57, 10), ("Pumpkin", 26, 10),
        ("Zucchini", 17, 10), ("Corn", 86, 10), ("Artichoke", 47, 10), ("Asparagus", 20, 10),
        ("Celery", 16, 10), ("Beetroot", 43, 10), ("Cauliflower", 25, 10), ("Radish", 16, 10),
        ("Eggplant", 25, 10), ("Green Onion", 32, 10), ("Sweet Potato", 86, 10), ("Squash", 45, 10),
        ("Turnip", 28, 10), ("Parsnip", 75, 10), ("Rutabaga", 35, 10), ("Leek", 61, 10),
        ("Swiss Chard", 19, 10), ("Kale", 35, 10), ("Arugula", 25, 10), ("Collard Greens", 33, 10),
        ("Mustard Greens", 27, 10), ("Endive", 17, 10), ("Chard", 19, 10), ("Iceberg Lettuce", 14, 10),
        ("Romaine Lettuce", 17, 10), ("Feta Cheese", 264, 6), ("Parmesan Cheese", 420, 6),
        ("Brie Cheese", 334, 6), ("Gouda Cheese", 356, 6), ("Cheddar Cheese", 402, 6),
        ("Mozzarella Cheese", 280, 6), ("Almonds", 579, 10), ("Walnuts", 654, 10), ("Cashews", 553, 10), ("Peanuts", 567, 10),
        ("Pistachios", 562, 10), ("Brazil Nuts", 656, 10),
        ("Pecans", 691, 10), ("Macadamia Nuts", 718, 10), ("Sunflower Seeds", 584, 10),
        ("Pumpkin Seeds", 559, 10), ("Chia Seeds", 486, 10), ("Flaxseeds", 534, 10),
        ("Quinoa", 120, 9), ("Barley", 354, 9), ("Buckwheat", 343, 9), ("Millet", 378, 9),
        ("Sorghum", 329, 9), ("Amaranth", 371, 9), ("Triticale", 339, 9), ("Spelt", 338, 9),
        ("Teff", 367, 9), ("Farro", 329, 9), ("Rye", 338, 9), ("Couscous", 112, 9),
        ("Semolina", 360, 9), ("Wild Rice", 357, 9), ("Coconut Rice", 357, 9), ("Popcorn", 375, 9), ("White Beans", 337, 10),
        ("Black Beans", 341, 10), ("Kidney Beans", 337, 10), ("Lentils", 116, 10),
        ("Chickpeas", 164, 10), ("Soybeans", 173, 10), ("Edamame", 122, 10), ("Tofu", 145, 10),
        ("Tempeh", 193, 10), ("Seitan", 370, 10), ("Textured Vegetable Protein", 341, 10),
        ("Soy Milk", 33, 6), ("Almond Milk", 15, 6), ("Coconut Milk", 230, 6),
        ("Oat Milk", 45, 6), ("Rice Milk", 47, 6), ("Cashew Milk", 22, 6),
        ("Hemp Milk", 46, 6), ("Hazelnut Milk", 28, 6), ("Pea Milk", 40, 6),
        ("Sunflower Milk", 50, 6), ("Banana Milk", 89, 6), ("Avocado Oil", 884, 5),
        ("Coconut Oil", 862, 5), ("Peanut Oil", 884, 5), ("Sesame Oil", 884, 5),
        ("Canola Oil", 884, 5), ("Sunflower Oil", 884, 5), ("Grapeseed Oil", 884, 5),
        ("Flaxseed Oil", 884, 5), ("Hempseed Oil", 884, 5), ("Rice Bran Oil", 884, 5),
        ("Walnut Oil", 884, 5), ("Macadamia Oil", 884, 5), ("Safflower Oil", 884, 5), ("Coconut", 354, 10),
        ("Sesame Seeds", 573, 10), ("Hemp Seeds", 553, 10), ("Poppy Seeds", 525, 10),
        ("Wheatberries", 339, 9), ("Brown Rice", 111, 9), ("Black Rice", 347, 9), ("Basmati Rice", 121, 9),
        ("Jasmine Rice", 130, 9), ("Arborio Rice", 97, 9), ("Carnaroli Rice", 121, 9), ("Sushi Rice", 135, 9),
        ("Long-Grain Rice", 130, 9), ("Short-Grain Rice", 130, 9), ("White Rice", 130, 9), ("Pearled Barley", 354, 9),
        ("Whole Wheat Pasta", 124, 9), ("Wheat Noodles", 124, 9), ("Brown Rice Pasta", 124, 9), ("Quinoa Pasta", 131, 9), ("Chickpea Pasta", 164, 9),
        ("Lentil Pasta", 107, 9), ("Soybean Pasta", 173, 9), ("Edamame Pasta", 122, 9), ("Buckwheat Pasta", 143, 9),
        ("Spaghetti Squash", 31, 10), ("Zucchini Noodles", 17, 10), ("Carrot Noodles", 41, 10), ("Butter", 45, 10),
        ("Sweet Potato Noodles", 86, 10), ("Red Lentil Pasta", 107, 9), ("Black Bean Pasta", 341, 9),
        ("Shirataki Noodles", 2, 10), ("Kelp Noodles", 6, 10), ("Miracle Noodles", 3, 10), ("Tofu Shirataki Noodles", 40, 10),
        ("Soba Noodles", 99, 9), ("Udon Noodles", 140, 9), ("Rice Noodles", 192, 9), ("Pad Thai Noodles", 192, 9),
        ("Glass Noodles", 181, 9), ("Egg Noodles", 138, 9), ("Ramen Noodles", 188, 9), ("Somen Noodles", 132, 9),
        ("Wonton Noodles", 200, 9), ("Lo Mein Noodles", 211, 9), ("Fettuccine", 357, 9), ("Tagliatelle", 364, 9), ("Pappardelle", 384, 9), ("Rigatoni", 357, 9), ("Farfalle", 360, 9), ("Cavatappi", 357, 9),
        ("Gemelli", 357, 9), ("Conchiglie", 357, 9), ("Tortellini", 384, 9), ("Rotini", 357, 9),
        ("Orzo", 357, 9), ("Ditalini", 357, 9), ("Acini de Pepe", 357, 9), ("Cannelloni", 357, 9),
        ("Manicotti", 357, 9), ("Lasagna", 357, 9), ("Ravioli", 384, 9), ("Stuffed Shells", 357, 9),
        ("Macaroni", 357, 9), ("Penne", 357, 9), ("Spaghetti", 357, 9), ("Curry", 40, 10), ("Sauerkraut", 19, 3), ("Ladyfingers", 302, 11), ("Peppers", 40, 10),
        ("Puff Pastry", 558, 9), ("Chocolate", 546, 11), ("Duck", 337, 7),
        ("Dough", 200, 9), ("Green curry paste", 125, 1), ("Sponge", 297, 11),
        ("Flour", 364, 9), ("Corn Tortillas", 218, 9), ("Catfish", 105, 8),
        ("Pastry", 406, 9), ("Beets", 43, 10), ("Cream Cheese", 342, 6),
        ("Rice Flour", 366, 9), ("Custard", 122, 11), ("Paneer", 265, 6),
        ("Lamb", 294, 7), ("Leafy Greens", 23, 10), ("Milk Solids", 502, 6),
        ("Octopus", 207, 8), ("Squid", 150, 8), ("Tea Powder", 73 , 10), ("Sausage", 450, 7),
        ("Maple Syrup", 140, 10), ("Bacon", 320, 7), ("Sugar", 387, 10)
    ]


    query = "INSERT INTO ingredient (title, kcal_per_100, food_group_id) VALUES (%s, %s, %s)"
    for ingredient_data in ingredients_data:
        execute_query(conn, query, ingredient_data)


def generate_dummy_recipes_from_json(json_file):
    with open(json_file, 'r') as file:
        recipes = json.load(file)

    query = """INSERT INTO recipe 
               (is_dessert, difficulty, title, small_description, tips, preparation_mins, cooking_mins, total_time, category, 
                serving_size_in_grams, servings, episode_count, national_cuisine_id, basic_ingredient_id)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""  # Adjusted number of placeholders

    for recipe in recipes:
        is_dessert = recipe.get('is_dessert', False)  # Default to False if not specified
        difficulty = random.randint(1, 5)
        title = recipe['name']
        small_description = recipe.get('description', '')[:300]  # Truncate to fit column limit
        tips = recipe.get('tips', '')[:400]  # Truncate to fit column limit
        preparation_mins = random.randint(30, 400)
        diff = random.randint(5, 15)
        cooking_mins = preparation_mins - diff
        total_time = None
        category = None  # Ensure category is set correctly or excluded if not used
        serving_size_in_grams = random.randint(50, 350)
        servings = random.randint(1, 4)
        episode_count = 0  # Default to 0
        national_cuisine_id = int(recipe['national_cuisine'])
        basic_ingredient_id = int(recipe['main_ingredient'])

        data = (is_dessert, difficulty, title, small_description, tips, preparation_mins, cooking_mins, total_time,
                category, serving_size_in_grams, servings, episode_count, national_cuisine_id, basic_ingredient_id)

        execute_query(conn, query, data)





### Start of retrieving methods


def get_recipe_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT recipe_id FROM recipe")
    result = cursor.fetchall()
    return [row[0] for row in result]


def get_gear_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT gear_id FROM gear")
    result = cursor.fetchall()
    return [row[0] for row in result]

def get_recipe_theme_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT recipe_theme_id FROM recipe_theme")
    result = cursor.fetchall()
    return [row[0] for row in result]

def get_cook_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT cook_id FROM cook")
    result = cursor.fetchall()
    return [row[0] for row in result]

def get_ingredient_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT ingredient_id FROM ingredient")
    result = cursor.fetchall()
    return [row[0] for row in result]

def get_national_cuisine_ids():
    cursor = conn.cursor()
    cursor.execute("SELECT national_cuisine_id FROM national_cuisine")
    result = cursor.fetchall()
    return [row[0] for row in result]


def get_cook_national_cuisines():
    cursor = conn.cursor()
    cursor.execute("SELECT cook_id, national_cuisine_id FROM cook_national_cuisine")
    result = cursor.fetchall()
    cook_cuisines = {}
    for cook_id, cuisine_id in result:
        if cook_id not in cook_cuisines:
            cook_cuisines[cook_id] = []
        cook_cuisines[cook_id].append(cuisine_id)
    return cook_cuisines


def get_recipe_national_cuisines():
    cursor = conn.cursor()
    cursor.execute("SELECT recipe_id, national_cuisine_id FROM recipe")
    result = cursor.fetchall()
    recipe_cuisines = {}
    for recipe_id, cuisine_id in result:
        if cuisine_id not in recipe_cuisines:
            recipe_cuisines[cuisine_id] = []
        recipe_cuisines[cuisine_id].append(recipe_id)
    return recipe_cuisines

def get_episode_cooks():
    cursor = conn.cursor()
    cursor.execute("SELECT cook_id, episode_id FROM cook_cuisine_assignment")
    result = cursor.fetchall()
    episode_cooks = {}
    for cook_id, episode_id in result:
        if episode_id not in episode_cooks:
            episode_cooks[episode_id] = []
        episode_cooks[episode_id].append(cook_id)
    return episode_cooks


def get_episodes():
    cursor = conn.cursor()
    cursor.execute("SELECT episode_id FROM episode")
    result = cursor.fetchall()
    return [row[0] for row in result]


def get_episode_judges():
    cursor = conn.cursor()
    cursor.execute("SELECT cook_id, episode_id FROM judge_assignment")
    result = cursor.fetchall()
    episode_judges = {}
    for cook_id, episode_id in result:
        if episode_id not in episode_judges:
            episode_judges[episode_id] = []
        episode_judges[episode_id].append(cook_id)
    return episode_judges



### End of retrieving methods




meal_types = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert", "Brunch", "Supper"]
def generate_recipe_meal_type_data(recipe_ids, meal_types):
    query = "INSERT INTO recipe_meal_type (recipe_id, meal_type) VALUES (%s, %s)"
    for recipe_id in recipe_ids:
        # Randomly choose exactly 2 meal types for each recipe
        chosen_meal_types = random.sample(meal_types, 2)
        for meal_type in chosen_meal_types:
            data = (recipe_id, meal_type)
            execute_query(conn, query, data)

def generate_recipe_gear_data(recipe_ids):
    gear_ids = get_gear_ids()  # Retrieve gear IDs
    query = "INSERT INTO recipe_gear (recipe_id, gear_id, quantity) VALUES (%s, %s, %s)"

    for recipe_id in recipe_ids:
        num_gears = random.randint(5, 15)
        selected_gears = random.sample(gear_ids, num_gears)
        for gear_id in selected_gears:
            quantity = random.randint(1,3)
            data = (recipe_id, gear_id, quantity)
            execute_query(conn, query, data)


tags = ["Healthy", "High protein", "Cold meal", "Comfort food", "For students", "Quick", "No sugar", "Low carbs", "Finger food", "Air fryer"]

def generate_recipe_tag_data(recipe_ids, tags):
    query = "INSERT INTO recipe_tag (recipe_id, tag) VALUES (%s, %s)"
    for recipe_id in recipe_ids:
        num_tags = random.randint(1, 3)  # Choose a random number of tags (between 1 and 3)
        chosen_tags = set()  # Set to store chosen tags for uniqueness
        while len(chosen_tags) < num_tags:
            tag = random.choice(tags)  # Randomly select a tag
            if tag not in chosen_tags:
                chosen_tags.add(tag)
                data = (recipe_id, tag)
                execute_query(conn, query, data)

def generate_recipe_theme_data():
    themes = [
        ("Summer", "Refreshing and vibrant meals perfect for grilling and outdoor dining. Think grilled meats and seafood, salads with seasonal fruits, and chilled desserts."),
        ("Winter", "Rich and decadent meals that bring warmth and comfort. Think roasts, braises, cheesy dishes, and chocolate desserts."),
        ("New Year's Eve", "Finger foods and appetizers for celebratory gatherings. Think dips, canapés, mini quiches, and sparkling beverages."),
        ("Valentine's Day", "Romantic and elegant dishes perfect for a date night in. Think steak dinners, pasta with creamy sauces, and decadent desserts like chocolate lava cake."),
        ("St. Patrick's Day", "Traditional Irish fare with a focus on potatoes, cabbage, and corned beef. Think corned beef and cabbage, shepherd's pie, and Irish soda bread."),
        ("Thanksgiving", "Classic American dishes for a bountiful feast. Think turkey, mashed potatoes, stuffing, cranberry sauce, and pumpkin pie."),
        ("Kwanzaa", "Dishes from the African diaspora that celebrate African American heritage. Think black-eyed peas, collard greens, jambalaya, and sweet potato pie."),
        ("Birthday Party", "Fun and festive dishes that cater to all ages. Think pizzas, burgers, finger foods, and colorful desserts."),
        ("Game Day", "Comfort food classics perfect for cheering on your favorite team. Think wings, nachos, chili, and dips."),
        ("Movie Night", "Cozy and easy snacks perfect for curling up on the couch. Think popcorn, nachos, candy, and homemade pizzas."),
        ("Decade Dinners", "Take a trip down memory lane with recipes popular during a specific decade."),
        ("Color-Coded Feasts", "Create a visually stunning meal by using ingredients of a particular color palette."),
        ("Breakfast for Dinner", "Break tradition and enjoy your favorite breakfast dishes for an evening meal.")
    ]

    query = "INSERT INTO recipe_theme (title, small_description) VALUES (%s, %s)"
    for theme in themes:
        execute_query(conn, query, theme)


def generate_recipe_recipe_theme_data():
    recipe_ids = get_recipe_ids()  # Retrieve recipe IDs
    theme_ids = get_recipe_theme_ids()  # Retrieve recipe theme IDs
    query = "INSERT INTO recipe_recipe_theme (recipe_theme_id, recipe_id) VALUES (%s, %s)"

    for recipe_id in recipe_ids:
        num_themes = random.randint(1, 2)  # Randomly choose 1 or 2 themes for each recipe
        selected_themes = random.sample(theme_ids, num_themes)  # Ensure unique themes for the recipe

        for theme_id in selected_themes:
            data = (theme_id, recipe_id)
            execute_query(conn, query, data)


def generate_recipe_ingredient_data(recipe_ids):
    ingredient_ids = get_ingredient_ids()  # Retrieve ingredient IDs
    quantity_descriptions = [
        "A little bit", "A small amount", "A pinch", "A big amount", "A generous amount", "A large quantity",
        "A small spoon", "A few drops", "A drizzle", "A handful", "A moderate amount", "Enough to comfortably hold in your hand",
        "A splash", "A small amount", "Just enough to coat/moisten", "Enough to cover the top", "A generous layer", "An even coating"
    ]
    query = "INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, estimated_grams) VALUES (%s, %s, %s, %s)"

    for recipe_id in recipe_ids:
        num_ingredients = random.randint(4, 15)
        selected_ingredients = random.sample(ingredient_ids, num_ingredients)
        for ingredient_id in selected_ingredients:
            quantity = random.choice(quantity_descriptions)
            estimated_grams = random.randint(30, 400)
            data = (recipe_id, ingredient_id, quantity, estimated_grams)
            execute_query(conn, query, data)


def generate_cook_national_cuisine_data():
    cook_ids = get_cook_ids()
    cuisine_ids = get_national_cuisine_ids()  # Retrieve national cuisine IDs
    query = "INSERT INTO cook_national_cuisine (cook_id, national_cuisine_id) VALUES (%s, %s)"

    for cook_id in cook_ids:
        num_cuisines = random.randint(4, 8)
        selected_cuisines = random.sample(cuisine_ids, num_cuisines)
        for cuisine_id in selected_cuisines:
            data = (cook_id, cuisine_id)
            execute_query(conn, query, data)


def generate_cook_recipe_data():
    cook_cuisines = get_cook_national_cuisines()
    recipe_cuisines = get_recipe_national_cuisines()
    query = "INSERT INTO cook_recipe (cook_id, recipe_id) VALUES (%s, %s)"

    for cook_id, cuisines in cook_cuisines.items():
        for cuisine_id in cuisines:
            if cuisine_id in recipe_cuisines:
                possible_recipes = recipe_cuisines[cuisine_id]

                # Exclude two random recipes for each cuisine
                # excluded_recipes = random.sample(possible_recipes, min(2, len(possible_recipes)))

                # Get the remaining recipes after excluding the two random ones
                # remaining_recipes = [recipe_id for recipe_id in possible_recipes]

                # Randomly select a subset of remaining recipes for the cook
                if possible_recipes:
                    num_recipes = random.randint(1, min(3, len(possible_recipes)))
                    selected_recipes = random.sample(possible_recipes, num_recipes)

                    for recipe_id in selected_recipes:
                        data = (cook_id, recipe_id)
                        execute_query(conn, query, data)


def generate_episode_data():
    query = "INSERT INTO episode (episode_number, season_number) VALUES (%s, %s)"
    for season in range(1, 6):  # Seasons 1 to 5
        for episode in range(1, 11):  # Episodes 1 to 10
            data = (episode, season)
            execute_query(conn, query, data)


def generate_nutritional_info_data(recipe_ids):

    query = "INSERT INTO nutritional_info (recipe_id, fats, carbohydrates, protein) VALUES (%s, %s, %s, %s)"

    for recipe_id in recipe_ids:
        fats = random.randint(5, 70)
        carbohydrates = random.randint(30, 200)
        protein = random.randint(10, 90)
        data = (recipe_id, fats, carbohydrates, protein)
        execute_query(conn, query, data)

def assignments():
    for season_number in range(1, 6):
        for episode_number in range(1, 11):
            query = "CALL episode_assignments(%s, %s)"
            data = (episode_number, season_number)
            execute_query(conn, query, data)

def generate_rating_data():
    query = "INSERT INTO rating (rating_value, cook_id, judge_id, episode_id) VALUES (%s, %s, %s, %s)"
    ep_cook_ids = get_episode_cooks()
    judge_ids = get_episode_judges()
    episode_ids = get_episodes()
    for episode_id in episode_ids:
        cooks = ep_cook_ids[episode_id]
        judges = judge_ids[episode_id]
        for cook in cooks:
            for judge in judges:
                rating_value = random.randint(1, 5)
                data = (rating_value, cook, judge, episode_id)
                execute_query(conn, query, data)

def insert_random_urls():
    for _ in range (596):
        url = generate_random_url()
        query = "INSERT INTO image (image_url) VALUES (%s)"
        data = [url]
        execute_query(conn, query, data)


def generate_recipe_image_data():

    fetch_query = "SELECT recipe_id, title FROM recipe"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    recipes = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO recipe_image (recipe_id, image_id, image_description) VALUES (%s, %s, %s)"
    for recipe_id, title in recipes:
        image_id = recipe_id
        image_description = title
        data = (recipe_id, image_id, image_description)
        execute_query(conn, query, data)

def generate_gear_image_data():

    fetch_query = "SELECT gear_id, title FROM gear"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    gears = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO gear_image (gear_id, image_id, image_description) VALUES (%s, %s, %s)"
    for gear_id, title in gears:
        image_id = gear_id+147
        image_description = title
        data = (gear_id, image_id, image_description)
        execute_query(conn, query, data)

def generate_food_group_image_data():

    fetch_query = "SELECT food_group_id, title FROM food_group"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    fdgrps = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO food_group_image (food_group_id, image_id, image_description) VALUES (%s, %s, %s)"
    for food_group_id, title in fdgrps:
        image_id = food_group_id+231
        image_description = title
        data = (food_group_id, image_id, image_description)
        execute_query(conn, query, data)


def generate_ingredient_image_data():

    fetch_query = "SELECT ingredient_id, title FROM ingredient"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    ingredients = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO ingredient_image (ingredient_id, image_id, image_description) VALUES (%s, %s, %s)"
    for ingredient_id, title in ingredients:
        image_id = ingredient_id+243
        image_description = title
        data = (ingredient_id, image_id, image_description)
        execute_query(conn, query, data)


def generate_recipe_theme_image_data():

    fetch_query = "SELECT recipe_theme_id, title FROM recipe_theme"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    themes = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO recipe_theme_image (recipe_theme_id, image_id, image_description) VALUES (%s, %s, %s)"
    for recipe_theme_id, title in themes:
        image_id = recipe_theme_id+482
        image_description = "A '" + title + "' themed recipe"
        data = (recipe_theme_id, image_id, image_description)
        execute_query(conn, query, data)


def generate_cook_image_data():

    fetch_query = "SELECT cook_id, first_name, last_name FROM cook"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    cooks = cursor.fetchall()  # Fetch all recipes
    cursor.close()
    query = "INSERT INTO cook_image (cook_id, image_id, image_description) VALUES (%s, %s, %s)"
    for cook_id, first_name, last_name in cooks:
        image_id = cook_id+495
        image_description = first_name + " " + last_name
        data = (cook_id, image_id, image_description)
        execute_query(conn, query, data)

def generate_episode_image_data():
    fetch_query = "SELECT episode_id FROM episode"
    cursor = conn.cursor()
    cursor.execute(fetch_query)
    episodes = cursor.fetchall()
    cursor.close()
    query = "INSERT INTO episode_image (episode_id, image_id, image_description) VALUES (%s, %s, %s)"

    for (episode_id,) in episodes:  # Unpack the episode_id directly as an integer
        image_id = episode_id + 546
        season_count = (episode_id // 10) + 1
        episode_count = episode_id % 10
        if episode_count == 0:
            season_count -= 1
            episode_count = 10
        image_description = f"Season {season_count}, Episode {episode_count}"  # Use f-string for formatting
        data = (episode_id, image_id, image_description)
        execute_query(conn, query, data)

def determine_winners():
    query = "CALL declare_winners()"
    execute_query(conn, query)

# Delete existing data and reset auto-increment for all tables
tables = ["episode_image", "cook_image", "recipe_theme_image", "ingredient_image", "food_group_image", "gear_image", "recipe_image",  "rating", "nutritional_info", "cook_recipe", "cook_national_cuisine", "recipe_ingredient", "recipe_recipe_theme", "recipe_gear", "recipe_tag", "recipe_meal_type", "cook", "recipe", "gear", "ingredient", "food_group", "national_cuisine", "app_user", "recipe_theme", "episode", "image"]


for table in tables:
    delete_existing_data(table)
    reset_auto_increment(table)




# Generate and insert data
generate_dummy_cooks(50)  # Generate 100 dummy cooks
insert_gear_data(gear_data)
generate_dummy_food_groups(food_group_data)
generate_dummy_cuisines(20)  # Generate 29 dummy cuisines
generate_dummy_users(50)  # Generate 50 dummy users
generate_dummy_ingredients(100)  # Generate data for about 100 ingredients
generate_dummy_recipes_from_json('recipes.json')
# Retrieve existing recipe IDs
recipe_ids = get_recipe_ids()
gear_ids = get_gear_ids()

# Populate the recipe_meal_type table with new data
generate_recipe_meal_type_data(recipe_ids, meal_types)
generate_recipe_gear_data(recipe_ids)
generate_recipe_tag_data(recipe_ids, tags)
generate_recipe_theme_data()
generate_recipe_recipe_theme_data()
generate_recipe_ingredient_data(recipe_ids)
generate_cook_national_cuisine_data()
generate_cook_recipe_data()
generate_episode_data()
generate_nutritional_info_data(recipe_ids)
assignments()
generate_rating_data()
insert_random_urls()
generate_recipe_image_data()
generate_gear_image_data()
generate_food_group_image_data()
generate_ingredient_image_data()
generate_recipe_theme_image_data()
generate_cook_image_data()
generate_episode_image_data()
determine_winners()

print("Dummy data inserted successfully into all tables.")

# Close the connection when done
conn.close()
