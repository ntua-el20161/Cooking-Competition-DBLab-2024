import mysql.connector
import random
import string
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
    port="8887",  # Adjust the port if necessary
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
    ("Potato Masher", "Use for mashing cooked potatoes or other vegetables.")
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
    "Caribbean", "German", "British", "Argentinian", "Indonesian",
    "Malaysian", "Swedish", "Polish", "Australian", "South African"
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

# Delete existing data and reset auto-increment for all tables
tables = ["cook", "gear", "food_group", "national_cuisine", "app_user"]
for table in tables:
    delete_existing_data(table)
    reset_auto_increment(table)

# Generate and insert data
generate_dummy_cooks(100)  # Generate 100 dummy cooks
insert_gear_data(gear_data)
generate_dummy_food_groups(food_group_data)
generate_dummy_cuisines(28)  # Generate 28 dummy cuisines
generate_dummy_users(50)  # Generate 50 dummy users

print("Dummy data inserted successfully into all tables.")

# Close the connection when done
conn.close()

