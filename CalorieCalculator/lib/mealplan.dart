import 'package:flutter/material.dart';
import 'databasehelper.dart';

class MealPlanScreen extends StatefulWidget {
  //Our selected date is retrieved when we start this class, and its value it put into the text box for submission
  final String selectedDate;

  const MealPlanScreen({required this.selectedDate});

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState(selectedDate);
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  //Declaring variables we will need for this screen
  final TextEditingController targetCaloriesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  List<Map<String, dynamic>> foodItems = [];
  List<bool> checkboxStates = [];
  Color textColor = Colors.black;
  int totalCalories = 0;
  String selectedDate;
  //puts our selected date into the state object
  _MealPlanScreenState(this.selectedDate);

  @override
  void initState() {
    super.initState();
    targetCaloriesController.text = '2000';// By defualt, we set a goal of 2000 calories
    dateController.text = _getFormattedDate(DateTime.now());//If no date is passed, retireve the current date
    _fetchFoodItems();//Get the food items from the database
    _checkSelectedItemsForDate();//compare the items from our passed date to the ones in the database, this enables us to autocheck ones that are part of a meal plan
  }

  String _getFormattedDate(DateTime dateTime) { //returns the proper date for today
    return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  void _fetchFoodItems() async {//Gets our list of all food items
    List<Map<String, dynamic>> fetchedItems = await DatabaseHelper().getFoods();
    setState(() {
      foodItems = fetchedItems;
      checkboxStates = List.generate(fetchedItems.length, (index) => false);
    });
  }

  void _updateTotalCalories() {//When a box is clicked, get its corrisponding calories and add them to the total calories
    int total = 0;
    int targetCalories = int.tryParse(targetCaloriesController.text) ?? 0;
    for (int i = 0; i < foodItems.length; i++) {
      if (checkboxStates[i]) {
        total += foodItems[i]['calories'] as int;
      }
    }
    setState(() {//Update the state to reflect the total calories we have
      totalCalories = total;
      textColor = (totalCalories <= targetCalories) ? Colors.black : Colors.red;
    });
  }

  Future<void> _insertMealPlan() async {//When the user taps on add meal plan, take the selected foods marked by a checkmark and add them to the database
    List<int> selectedFoodIds = [];
    for (int i = 0; i < foodItems.length; i++) {
      if (checkboxStates[i]) {
        selectedFoodIds.add(foodItems[i]['id'] as int);
      }
    }
    await DatabaseHelper().deleteMealPlan(selectedDate);//Clear any mealplan for this date, there should be only one mealplan able to be created each day

    Map<String, dynamic> newMealPlan = {
      'date': dateController.text,
    };
    //Insert our meal plan into database
    int insertedMealPlanId = await DatabaseHelper().insertMealPlan(newMealPlan);
    //Insert the meal plan items into the database, using the ID of the meal plan and the ID of the food value to make a table that holds both.
    for (int foodId in selectedFoodIds) {
      await DatabaseHelper().insertMealPlanFoodItem(
          {'meal_plan_id': insertedMealPlanId, 'food_id': foodId}
      );
    }

    print('Inserted Meal Plan ID: $insertedMealPlanId');
  }

  void _checkSelectedItemsForDate() async {//Get today as a mealplan, if items are found, check the corrisponding box off
    List<String> selectedFoodItems =
    await DatabaseHelper().getFoodsByMealPlanDate(selectedDate);

    setState(() {
      for (int i = 0; i < foodItems.length; i++) {
        checkboxStates[i] = selectedFoodItems.contains(foodItems[i]['name']);
      }
      _updateTotalCalories();
    });
  }
//Build the display for the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: Colors.orange, // Change app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 20),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: targetCaloriesController,
              decoration: InputDecoration(
                labelText: 'Target Calories',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Text(
              'Total Calories: $totalCalories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: foodItems.length,
                //For each item in food items
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    //Create a tile with a checkbox
                    title: Text(foodItems[index]['name']),
                    value: checkboxStates[index],
                    onChanged: (bool? value) {
                      setState(() {//When clicked, update the state value of this item and the calories at the top of the page
                        checkboxStates[index] = value ?? false;
                        _updateTotalCalories();
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _insertMealPlan();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // Change button color
              ),
              child: const Text('Add Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}