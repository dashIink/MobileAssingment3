import 'package:flutter/material.dart';
import 'databasehelper.dart';
import 'mealplan.dart';
import 'dialogs.dart';

void main() async {
  //Start the main app, initialize the database
  WidgetsFlutterBinding.ensureInitialized();
  final DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  //Create our overall theme and set our homepage as MyHomePage
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);
//Create the look of our homepage. Top button passes to the create meal plan page with no date.
// Future passes to this page will have a date.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Calculator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  //Route to next page
                  MaterialPageRoute(builder: (context) => MealPlanScreen(selectedDate: 'null')),
                );
              },
              child: const Text('Create Meal Plan'),
            ),
            const SizedBox(height: 20), // Add spacing between buttons
            //Add in the widgets nessecary for seraching and displaying our meal plan
            MealPlanSearchWidget(),
          ],
        ),
      ),
    );
  }
}

class MealPlanSearchWidget extends StatefulWidget {
  const MealPlanSearchWidget({Key? key}) : super(key: key);

  @override
  _MealPlanSearchWidgetState createState() => _MealPlanSearchWidgetState();
}

class _MealPlanSearchWidgetState extends State<MealPlanSearchWidget> {
  final TextEditingController searchDateController = TextEditingController();
  //Create the display that our mealplan will show
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          //Using this textfield, the user can search for a specific date as text. The format is MM/DD/YYYY by defualt
          controller: searchDateController,
          decoration: InputDecoration(
            labelText: 'Search Meal Plan by Date',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            String searchDate = searchDateController.text;
            if (searchDate.isNotEmpty) {//Assuming the text isn't empty, gather the items from the mealplan that exists for that date
              List<String> mealPlan = await DatabaseHelper().getFoodsByMealPlanDate(searchDate);
              if (mealPlan.isNotEmpty) {
                //Display our dialog containing all items
                showMealPlanDialog(context, mealPlan, searchDate);
                print(mealPlan);
              } else {
                showNoMealPlanDialog(context);
              }
            } else {
              showDateEmptyDialog(context);
            }
          },
          child: const Text('Search Meal Plan'),
        ),
      ],
    );
  }
}
