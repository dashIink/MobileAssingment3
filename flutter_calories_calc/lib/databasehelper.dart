import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

//Database management class
class DatabaseHelper {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  //On initialization of database
  Future<void> initDatabase() async {
    bool databaseExists = await checkDatabaseExists();
    if (!databaseExists) {//If no database exists, make a new one using the foods from file
      await _createDatabase();
      await insertInitialData();
    }

  }

  Future<bool> checkDatabaseExists() async {
    String path = join(await getDatabasesPath(), 'FlutterCaloriesCalc_db.sqlite');
    return databaseFactory.databaseExists(path);
  }

  Future<void> _createDatabase() async {
    String path = join(await getDatabasesPath(), 'FlutterCaloriesCalc_db.sqlite');
    _database = await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> insertInitialData() async {//Get the foods from file, and add them to the database
    await insertFoodsFromFile();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'FlutterCaloriesCalc_db.sqlite');
    return openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {//Create each of our tables
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        calories INTEGER
      )
    ''');//Foods contains the ID of each food type, these are used in reference to the meal_plan_food_items table

    await db.execute('''
      CREATE TABLE meal_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT
      );
    ''');//Meal plan contains the date and ID of the meal plan

    await db.execute('''
      CREATE TABLE meal_plan_food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_plan_id INTEGER,
        food_id INTEGER,
        FOREIGN KEY (meal_plan_id) REFERENCES meal_plan(id),
        FOREIGN KEY (food_id) REFERENCES foods(id)
      );
    ''');//Using this table, we associated each food item to a meal plan by giving it a related food ID and the associated meal plan ID it is apart of
  }
//Basic operations for each table
  Future<int> insertFood(Map<String, dynamic> food) async {
    Database db = await database;
    return await db.insert('foods', food);
  }

  Future<List<Map<String, dynamic>>> getFoods() async {
    Database db = await database;
    return await db.query('foods');
  }

  Future<int> updateFood(Map<String, dynamic> food) async {
    Database db = await database;
    return await db.update('foods', food,
        where: 'id = ?', whereArgs: [food['id']]);
  }

  Future<int> deleteFood(int id) async {
    Database db = await database;
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertMealPlan(Map<String, dynamic> mealPlan) async {
    Database db = await database;
    return await db.insert('meal_plan', mealPlan);
  }

  Future<List<Map<String, dynamic>>> getMealPlans() async {
    Database db = await database;
    return await db.query('meal_plan');
  }

  Future<int> updateMealPlan(Map<String, dynamic> mealPlan) async {
    Database db = await database;
    return await db.update('meal_plan', mealPlan,
        where: 'id = ?', whereArgs: [mealPlan['id']]);
  }

  Future<int> deleteMealPlan(String id) async {
    Database db = await database;
    return await db.delete('meal_plan', where: 'date LIKE ?', whereArgs: [id]);
  }

  Future<int> insertMealPlanFoodItem(Map<String, dynamic> mealPlanFoodItem) async {
    Database db = await database;
    print(mealPlanFoodItem);
    return await db.insert('meal_plan_food_items', mealPlanFoodItem);
  }

  Future<void> insertFoodsFromFile() async {//When no database is found, read foods from a file to create food list
    try {
      String foodsData = await rootBundle.loadString('foods');
      List<String> foodsList = foodsData.split('\n');

      Database db = await database;
      Batch batch = db.batch();

      for (String foodLine in foodsList) {
        List<String> foodInfo = foodLine.split('    '); // Split using the delineator
        String name = foodInfo[0].trim();
        int calories = int.tryParse(foodInfo[1].trim()) ?? 0; // Parse calories as int

        batch.insert('foods', {'name': name, 'calories': calories});
      }

      await batch.commit();
      print('Foods inserted successfully.');
    } catch (e) {
      print('Error inserting foods: $e');
    }
  }

  Future<int> clearFoodsTable() async {
    Database db = await database;
    return await db.delete('foods');
  }

  Future<int> clearMealPlanTable() async {
    Database db = await database;
    return await db.delete('meal_plan');
  }

  Future<int> clearAddressesTable() async {
    Database db = await database;
    return await db.delete('addresses');
  }
//removes all data from all tables
  Future<void> clearAllTables() async {
    await clearFoodsTable();
    await clearMealPlanTable();
    await clearAddressesTable();
    print('All tables cleared.');
  }

  Future<void> deleteDatabaseFile() async {//remove database in case it needs to be re-created
    String path = join(await getDatabasesPath(), 'FlutterCaloriesCalc_db.sqlite');
    if (await databaseExists(path)) {
      Database? db = _database;
      if (db != null && db.isOpen) {
        await db.close();
      }
      await deleteDatabase(path);
      _database = null; // Reset the database reference after deletion
      print('Database file deleted successfully.');
    } else {
      print('Database file does not exist.');
    }
  }
  Future<List<String>> getFoodsByMealPlanDate(String date) async {//returns list of foods based on specific dates meal plan
    try {
      // Get meal plan ID for the specified date
      List<Map<String, dynamic>> mealPlan = await getMealPlansByDate(date);

      if (mealPlan.isEmpty) {
        print("Nothing Found");
        return []; // No meal plan found for the specified date
      }
      print(mealPlan);

      int mealPlanId = mealPlan[0]['id'] as int;
      print(mealPlanId);

      // Get food IDs for the meal plan from meal_plan_food_items table
      List<Map<String, dynamic>> mealPlanFoodItems =
      await getMealPlanFoodItemsByMealPlanId(mealPlanId);

      if (mealPlanFoodItems.isEmpty) {
        print(mealPlanFoodItems);
        return []; // No food items found for the meal plan
      }
      print(mealPlanFoodItems);
      // Get food items from foods table using food IDs
      List<String> foods = [];

      for (Map<String, dynamic> foodItem in mealPlanFoodItems) {
        int foodId = foodItem['food_id'] as int;
        Map<String, dynamic> food = await getFoodById(foodId);
        print(food);

        if (food.isNotEmpty) {
          foods.add(food['name'] as String);
        }
      }

      return foods;
    } catch (e) {
      print('Error getting foods by meal plan date: $e');
      return [];
    }
  }
//Returns the meal plan of a specific date
  Future<List<Map<String, dynamic>>> getMealPlansByDate(String date) async {
    Database db = await database;
    return await db.query('meal_plan', where: 'date = ?', whereArgs: [date]);
  }
//Returns the meal plan food items associated with a food plan ID
  Future<List<Map<String, dynamic>>> getMealPlanFoodItemsByMealPlanId(int mealPlanId) async {
    Database db = await database;
    return await db.query('meal_plan_food_items', where: 'meal_plan_id = ?', whereArgs: [mealPlanId]);
  }
//Gets the name of a food associated with an ID
  Future<Map<String, dynamic>> getFoodById(int foodId) async {
    Database db = await database;
    List<Map<String, dynamic>> result =
    await db.query('foods', where: 'id = ?', whereArgs: [foodId]);

    if (result.isNotEmpty) {
      return result[0];
    }

    return {};
  }
}


