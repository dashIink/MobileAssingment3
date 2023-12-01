// dialogs.dart
import 'package:flutter/material.dart';
import 'databasehelper.dart';
import 'mealplan.dart';

void showMealPlanDialog(BuildContext context, List<String> mealPlanItems, String date) {
  //A simple class that contains the dialog box used to show the meal plan for a specific day
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Meal Plan for $date'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected Food Items:'),
              for (String item in mealPlanItems)
                Text('- $item'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _handleDeleteAction(context, date);
            },
            child: Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              _handleUpdateAction(context, date);
            },
            child: Text('Update'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

void _handleDeleteAction(BuildContext context, String date) async {
  //If the user wants to delete this plan, remove it from the database
  await DatabaseHelper().deleteMealPlan(date);
  Navigator.of(context).pop();
  print('Delete action for $date');
}

void _handleUpdateAction(BuildContext context, String date) {
  //If the user wants to update this plan, send them to the meal plan screen with argument of todays date
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MealPlanScreen(selectedDate: date)),
  );
  print('Update action for $date');
}

void showNoMealPlanDialog(BuildContext context) {

}

void showDateEmptyDialog(BuildContext context) {

}