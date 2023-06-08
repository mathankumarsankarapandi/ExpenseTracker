import 'package:daily_expenses/DailyExpenseModel.dart';
import 'package:daily_expenses/DailyExpensesDao.dart';
import 'package:daily_expenses/DailyExpensesTable.dart';
import 'package:daily_expenses/FloorDBViewModel.dart';
import 'package:daily_expenses/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:high_chart/high_chart.dart';
import 'package:intl/intl.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DailyExpenseView(),
    );
  }
}

class DailyExpenseView extends StatefulWidget {
  const DailyExpenseView({Key? key}) : super(key: key);

  @override
  State<DailyExpenseView> createState() => _DailyExpenseViewState();
}

class _DailyExpenseViewState extends State<DailyExpenseView>  with SingleTickerProviderStateMixin {
  late Future<List<DailyExpensesModel>> dailyExpenseModelList;
  late Future<List<DailyExpensesModel>> dailyExpenseModelMonthList;
  late TabController tabController;
  CommonWidgets commonWidgets = CommonWidgets();
  List<String> chartDataList = [];
  List<DailyExpensesModel> dailyExpenseModelDataList = [];
  TextEditingController amountTextEditingController = TextEditingController();
  TextEditingController cityTextEditingController = TextEditingController();
  TextEditingController dateTimeTextEditingController = TextEditingController();
  static const String datedMyHMaFormatText = "dd/MM/yyyy hh:mm a";
  static const String datedMyHMFormatText = "dd/MM/yyyy HH:mm";
  static const String dateFormatText = "dd/MM/yyyy";
  static const String monthFormatText = "MMMM yyyy";
  String? selectedTime;
  String? selectedDate;
  String? dropDownValue;
  String? chartType = "Bar Chart";
  List<DailyExpensesModel> dailyExpenseDataModelList = [];
  List<DailyExpensesModel> monthlyExpenseDataModelList = [];
  List<String> list = ["Food", "Shopping", "Rent", "Travel", "Fun Activities", "Movie" , "EMI", "Others"];
  List<String> chartTypeList = ["Pie Chart", "Line Graph","Bar Chart"];


  String dateText = DateFormat(dateFormatText).format(DateTime.now()).toString();
  String monthText = DateFormat(monthFormatText).format(DateTime.now()).toString();
  String startDateOfMonth = "", lastDateOfMonth="";
  int initialIncrementCountDate = 0,initialDecrementCountDate = 0;
  int initialIncrementCountMonth = 0,initialDecrementCountMonth = 0;
  String? currentDateChartData;
  Future<bool> onWillPop() {
    return CommonWidgets().launchPage(context,const DailyExpenseView());
  }

  @override
  void initState() {
    setFirstAndLastDateOfTheMonth(DateTime.now());
    dailyExpenseModelList = fetchExpenseDetailsFromDB(context,dateText,false);
    dailyExpenseModelMonthList = fetchExpenseDetailsFromDB(context,dateText,true);
    tabController = TabController(vsync: this, length: 3);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Expense Tracker", style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),),
          actions: const <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.more_vert),
            ),
          ],
          backgroundColor: Colors.green,
          bottom: TabBar(
            tabs: const [
              Tab(child: Text("Daily"),),
              Tab(child: Text("Weekly",)),
              Tab(child: Text("Monthly",)),
            ], indicatorColor: Colors.white,
            controller: tabController,
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children:  [
            showDailyExpensesData(),
            errorAlertLayout("Coming Soon"),
            errorAlertLayout("Coming Soon"),
            // showExpensesBasedOnMonth(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () {
            showExpenseDialog(context);
          },
          tooltip: 'Add Expense',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget showExpensesBasedOnMonth(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Visibility(
              visible: monthText != DateFormat(monthFormatText).format(DateTime.now()).toString(),
              replacement: commonWidgets.getIcon(Icons.arrow_back_ios_new_rounded, Colors.transparent, 15, () {}),
              child: commonWidgets.getIcon(Icons.arrow_back_ios_new_rounded, Colors.green, 15, () {
                DateTime now = DateTime.now();
                initialIncrementCountMonth ++;
                DateTime changeDate = DateTime(now.year,(now.month-initialDecrementCountMonth)+initialIncrementCountMonth,now.day);
                monthText = DateFormat(monthFormatText).format(changeDate).toString();
                setFirstAndLastDateOfTheMonth(changeDate);
                dailyExpenseModelMonthList = fetchExpenseDetailsFromDB(context,dateText,true);
                setState(() {

                });
              }),
            ),
            commonWidgets.getNormalTextWithBold(monthText, Colors.green, 1, 15),
            commonWidgets.getIcon(Icons.arrow_forward_ios_rounded, Colors.green, 15, () {
              DateTime now = DateTime.now();
              initialDecrementCountMonth ++;
              DateTime changeDate = DateTime(now.year,(now.month+initialIncrementCountMonth)-initialDecrementCountMonth,now.day);
              monthText = DateFormat(monthFormatText).format(changeDate).toString();
              setFirstAndLastDateOfTheMonth(changeDate);
              dailyExpenseModelMonthList = fetchExpenseDetailsFromDB(context,dateText,true);
              setState(() {

              });
            })
          ],
        ),
        Expanded(
            child:showMonthlyExpense()
        )
      ],
    );
  }

  setFirstAndLastDateOfTheMonth(DateTime dateTime){
    startDateOfMonth = DateFormat(dateFormatText).format(DateTime(dateTime.year,dateTime.month, 1)).toString();
    int days = DateTime(dateTime.year,dateTime.month+1, 1).difference(DateTime(dateTime.year,dateTime.month, 1)).inDays;
    lastDateOfMonth = DateFormat(dateFormatText).format(DateTime(dateTime.year,dateTime.month, days)).toString();
  }

  Widget showDailyExpensesData(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Visibility(
              visible: dateText != DateFormat(dateFormatText).format(DateTime.now()).toString(),
              replacement: commonWidgets.getIcon(Icons.arrow_back_ios_new_rounded, Colors.transparent, 15, () {}),
              child: commonWidgets.getIcon(Icons.arrow_back_ios_new_rounded, Colors.green, 15, () {
                DateTime now = DateTime.now();
                initialIncrementCountDate ++;
                DateTime changeDate = DateTime(now.year, now.month, (now.day-initialDecrementCountDate)+initialIncrementCountDate);
                dateText = DateFormat(dateFormatText).format(changeDate).toString();
                dailyExpenseModelList = fetchExpenseDetailsFromDB(context,dateText,false);
                setState(() {

                });
              }),
            ),
            commonWidgets.getNormalTextWithBold(dateText, Colors.green, 1, 15),
            commonWidgets.getIcon(Icons.arrow_forward_ios_rounded, Colors.green, 15, () {
             DateTime now = DateTime.now();
             initialDecrementCountDate ++;
             DateTime changeDate = DateTime(now.year, now.month, (now.day+initialIncrementCountDate)-initialDecrementCountDate);
             dateText = DateFormat(dateFormatText).format(changeDate).toString();
             dailyExpenseModelList = fetchExpenseDetailsFromDB(context,dateText,false);
             setState(() {

             });
            })
          ],
        ),
        Expanded(
            child: showDailyExpense())
      ],
    );
  }

  Widget showDailyExpenseDataBasedOnDate(List<DailyExpensesModel> dailyExpenseModelList){
    mapChartDataBasedOnDateChartType(dailyExpenseModelList, chartType!,dateText);
    List<String> reason = [];
    List<double> reasonAmount = [];
    double totalAmount = 0;
    for(DailyExpensesModel dailyExpenseModel in dailyExpenseModelList) {
      if(reason.contains(dailyExpenseModel.reason)){
        int count = 0;
        for(String tempReason in reason){
          if(tempReason == dailyExpenseModel.reason){
            reasonAmount[count] = (double.parse(dailyExpenseModel.amount) + reasonAmount[count]);
            totalAmount += double.parse(dailyExpenseModel.amount);
          }
          count++;
        }
      } else {
        reason.add(dailyExpenseModel.reason);
        reasonAmount.add(double.parse(dailyExpenseModel.amount));
        totalAmount += double.parse(dailyExpenseModel.amount);
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 10,bottom: 30,left: 10,right: 10),
      padding: const EdgeInsets.only(top: 10,bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 5,
        ), //Border.all
        borderRadius: BorderRadius.circular(5),
      ),
      child: SingleChildScrollView(
        child: Expanded(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.05,
                decoration: commonWidgets.getBoxDecorationWithColor(Colors.white, Colors.green, 20),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      iconSize: 20,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      iconEnabledColor: Colors.transparent,
                      onChanged: (dynamic value) {
                        setState(() {
                          chartType = value!;
                          showDailyExpenseDataBasedOnDate(dailyExpenseDataModelList);
                        });
                      },
                      hint:commonWidgets.getNormalTextWithCenterAlignment(chartType!, Colors.green, 1, 11, FontWeight.normal),
                      items: chartTypeList.map((value) => DropdownMenuItem(
                        value: value,
                        child: Center( child: commonWidgets.getNormalText(value, Colors.green, 1, 11)),
                      )).toList(),
                      value: chartType,
                      style: const TextStyle(
                          color:Colors.green, fontSize: 10),
                      isExpanded: true,
                    )),
              ),
              HighCharts(
                loader: const SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(),
                ),
                size: const Size(400, 400),
                data: currentDateChartData!,
                scripts: const [
                  "https://code.highcharts.com/highcharts.js",
                  'https://code.highcharts.com/modules/networkgraph.js',
                  'https://code.highcharts.com/modules/exporting.js',
                ],
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                      top: BorderSide(
                        color: Colors.green,
                        width: 2,
                      )
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8,20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      commonWidgets.getNormalTextWithBold("Total Expenses", Colors.black, 1, 12),
                      commonWidgets.getNormalTextWithBold("- \$$totalAmount", Colors.black, 1, 12),
                    ],
                  ),
                ),
              ),
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reason.length,
                itemBuilder: (context, innerIndex) {
                  Color sliderColor = Colors.blue;
                  if(reason[innerIndex] == "Food"){
                    sliderColor = Colors.green;
                  } else if(reason[innerIndex] == "Shopping"){
                    sliderColor = Colors.amber;
                  } else if(reason[innerIndex] == "Rent"){
                    sliderColor = Colors.redAccent;
                  } else if(reason[innerIndex] == "Travel"){
                    sliderColor = Colors.purpleAccent;
                  } else if(reason[innerIndex] == "Fun Activities"){
                    sliderColor = Colors.orange;
                  } else if(reason[innerIndex] == "Movie"){
                    sliderColor = Colors.deepPurple;
                  } else if(reason[innerIndex] == "EMI"){
                    sliderColor = Colors.pink;
                  } else if(reason[innerIndex] == "Others"){
                    sliderColor = Colors.teal;
                  }
                  return Container(
                    margin: const EdgeInsets.fromLTRB(10, 3,10, 5),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              commonWidgets.getNormalTextWithBold(reason[innerIndex], Colors.black, 1, 12),
                              commonWidgets.getNormalTextWithBold("- \$${reasonAmount[innerIndex]}", Colors.black, 1, 12),
                            ],
                          ),
                        ),
                        commonWidgets.getSlider(context,reasonAmount[innerIndex],totalAmount,sliderColor),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  mapChartDataBasedOnDateChartType(List<DailyExpensesModel> dailyExpenseModelList, String type, String date) {
    List<String> reason = [];
    List<String> reasonAmount = [];
    for(DailyExpensesModel dailyExpenseModel in dailyExpenseModelList){
      if(dailyExpenseModel.date == date){
        if(reason.contains(dailyExpenseModel.reason)){
          int count = 0;
          for(String tempReason in reason){
            if(tempReason == dailyExpenseModel.reason){
              reasonAmount[count] = (double.parse(dailyExpenseModel.amount) + double.parse(reasonAmount[count])).toString();
            }
            count++;
          }
        } else {
          reason.add(dailyExpenseModel.reason);
          reasonAmount.add(dailyExpenseModel.amount);
        }
      }

    }
    List<String> dataList = [];
    List<String> reasonList = [];
    int i = 0;
    for(String chartData in reason){
      reasonList.add("'$chartData'");
      if(type == "Line Graph"){
        dataList.add(reasonAmount[i]);
      } else {
        dataList.add('{name: '"'${reason[i]}'"','
            'y: '"${reasonAmount[i]}"','
            'color: Highcharts.getOptions().colors[${i+5}]}');
      }
      i++;
    }
    if(type == "Pie Chart"){
      currentDateChartData = '''{
          title: {
              text: "$date Pie Chart"
          },
          credits: {
              enabled: false
          }, 
          exporting: {
              enabled: false 
          },
          series: [{
          type: 'pie',
          name: 'Expense Amount \$',
          colorByPoint: true,
          data: $dataList
        }],
        }''';
    } else if(type == "Line Graph"){
      currentDateChartData = '''{
    title: {
        text: "$date Line Graph"
    },
    xAxis: {
        categories: $reasonList,
    },
    credits: {
    enabled: false
      },
      exporting: {
       enabled: false 
       },
    series: [{
        type: 'spline',
        name: 'Reason',
        data: $dataList,
        marker: {
            lineWidth: 2,
            lineColor: Highcharts.getOptions().colors[6],
            fillColor: 'white'
        }
    },]
  }''';
    } else if(type == "Bar Chart"){
      currentDateChartData = '''{
            chart: {
                type: 'column'
            },
            title: {
              text: "$date Bar Chart"
            },
            credits: {
              enabled: false
            }, exporting: {
              enabled: false 
            },
             xAxis: {
                categories: $reasonList
             },
            plotOptions: {
                series: {
                    dataLabels: {
                        enabled: true,
                        format: '{point.y:.2f}'
                    }
                }
            },
            series: [
                {
                    name: "Reason",
                    colorByPoint: true,
                    data: $dataList
                }
            ],
            }
        ''';
    }

  }

  Widget showDailyExpense() {
    Widget futureBuilder = FutureBuilder(
        future: dailyExpenseModelList,
        builder: (BuildContext context,
            AsyncSnapshot<List<DailyExpensesModel>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Row(
                children: <Widget>[
                  CommonWidgets().getNormalText(
                      "Connection State None",
                      Colors.black,1,12)
                ],
              );
            case ConnectionState.waiting:
              return Row(
                children: const <Widget>[
                  CircularProgressIndicator(
                    color: Colors.red,
                  )
                ],
              );
            case ConnectionState.active:
              return Row(
                children: <Widget>[
                  CommonWidgets().getNormalText(
                      "Connection State None",
                      Colors.black,1,12)
                ],
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Row(
                  children: <Widget>[
                    CommonWidgets().getNormalText(
                        "Connection State Error",
                        Colors.black,1,12)
                  ],
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                if(snapshot.data!.isNotEmpty){
                  dailyExpenseDataModelList = snapshot.data!;
                  return showDailyExpenseDataBasedOnDate(snapshot.data!);
                } else {
                  return errorAlertLayout("No expenses found for this selection");
                }
              } else {
                return errorAlertLayout("No expenses found for this selection");
              }
          }
        });
    return futureBuilder;
  }

  Widget showMonthlyExpense() {
    Widget futureBuilder = FutureBuilder(
        future: dailyExpenseModelMonthList,
        builder: (BuildContext context,
            AsyncSnapshot<List<DailyExpensesModel>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Row(
                children: <Widget>[
                  CommonWidgets().getNormalText(
                      "Connection State None",
                      Colors.black,1,12)
                ],
              );
            case ConnectionState.waiting:
              return Row(
                children: const <Widget>[
                  CircularProgressIndicator(
                    color: Colors.red,
                  )
                ],
              );
            case ConnectionState.active:
              return Row(
                children: <Widget>[
                  CommonWidgets().getNormalText(
                      "Connection State None",
                      Colors.black,1,12)
                ],
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Row(
                  children: <Widget>[
                    CommonWidgets().getNormalText(
                        "Connection State Error",
                        Colors.black,1,12)
                  ],
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                if(snapshot.data!.isNotEmpty){
                  monthlyExpenseDataModelList = snapshot.data!;
                  return showDailyExpenseDataBasedOnDate(snapshot.data!);
                } else {
                  return errorAlertLayout("No expenses found for this selection");
                }
              } else {
                return errorAlertLayout("No expenses found for this selection");
              }
          }
        });
    return futureBuilder;
  }

  Widget errorAlertLayout(String errorMessage){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          width: MediaQuery.of(context).size.width*0.95,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 4,
              ), //Border.all
              borderRadius: BorderRadius.circular(5),
            ),
            child: CommonWidgets().getNormalTextWithCenterAlignment(errorMessage, Colors.red,2,15, FontWeight.bold)),
      ],
    );
  }

  Future<List<DailyExpensesModel>> fetchExpenseDetailsFromDB(BuildContext context, String date, bool inBetweenDays) async {
    final database = await CommonWidgets().getAppDatabaseObject();
    try {
      final DailyExpensesDao dailyExpensesDao = database.dailyExpensesDao;

      List<DailyExpensesModel> dailyExpenseModelList = [];
      List<DailyExpensesTable>? branchTableList;
      if(inBetweenDays){
        branchTableList = await dailyExpensesDao.getExpensesBetweenDay(startDateOfMonth,lastDateOfMonth);
      } else {
        branchTableList = await dailyExpensesDao.getExpensesByDate(date);
      }

      if (branchTableList.isNotEmpty) {
        for (DailyExpensesTable branchTable in branchTableList) {
          dailyExpenseModelList.add(DailyExpensesModel(
              branchTable.dateTime,
              branchTable.date,
              branchTable.amount,
              branchTable.reason,
              branchTable.city));
        }
      }
      return dailyExpenseModelList;
    } catch (error, stackTrace) {
      return [];
    }
  }

  showExpenseDialog(BuildContext context){
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (BuildContext context) {
          return commonWidgets.addExpenseDialog(
              context,
              16,
              20,
              "Add Expenses",
              Colors.green,
              amountTextEditingController,
              dateTimeTextEditingController,
              cityTextEditingController,
                  (dynamic value) {
                setState(() {
                  dropDownValue = value!;
                });
              },
              list,
              dropDownValue,
                  () async {
                Position position1 = await _getGeoLocationPosition();
                List<Placemark> placeMarks = await placemarkFromCoordinates(
                    position1.latitude, position1.longitude);
                Placemark place = placeMarks[0];
                String address =
                    '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
                cityTextEditingController.text = "${place.locality}";
                print("addressaddressaddressaddressaddress$address");
              },
                  (date) {
                  setState(() {
                    dateTimeTextEditingController.text = DateFormat(datedMyHMaFormatText).format(date).toString();
                    selectedTime = DateFormat(datedMyHMFormatText).format(date).toString();
                    selectedDate = DateFormat(dateFormatText).format(date).toString();
                    commonWidgets.printLog("date$date");
                  });
                },
                  () async {
                if(amountTextEditingController.text.isNotEmpty && cityTextEditingController.text.isNotEmpty && dropDownValue != null && dateTimeTextEditingController.text.isNotEmpty){
                  final database = await commonWidgets.getAppDatabaseObject();
                  DailyExpensesDao userModelDao = database.dailyExpensesDao;
                  await userModelDao.insertExpenses(DailyExpensesTable(selectedTime!,selectedDate!,amountTextEditingController.text.toString(),dropDownValue!, cityTextEditingController.text.toString()));
                  amountTextEditingController.clear();
                  cityTextEditingController.clear();
                  dateTimeTextEditingController.clear();
                  dropDownValue = null;
                  dateText = DateFormat(dateFormatText).format(DateTime.now()).toString();
                  initialIncrementCountDate = 0;
                  initialDecrementCountDate = 0;
                  dailyExpenseModelList = fetchExpenseDetailsFromDB(context, dateText,false);
                  setState(() {});
                  Navigator.pop(context);
                } else {
                  commonWidgets.getToast("Please fill all fields");
                }
              },
              () {
            amountTextEditingController.clear();
            cityTextEditingController.clear();
            dropDownValue = null;
            dateTimeTextEditingController.clear();
            Navigator.pop(context);
          });
        }
    );
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location fetch error");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location denied");
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error("Location denied");
      }
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

}


class CommonWidgets{

  static Color appThemeColor = Colors.green;
  static Color boxGrey = const Color(0xFFF1F0F0);

  Widget getWillPopScopeWidget(
      BuildContext context,
      WillPopCallback? onWillPop,
      Widget bodyContainer,
      bool resizeToAvoidBottomPadding,
      GlobalKey<ScaffoldState>? formKey) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                  overlays: []);
            },
            child: bodyContainer,
          ),
          resizeToAvoidBottomInset: resizeToAvoidBottomPadding,
          key: formKey),
    );
  }

  Future<AppDatabase> getAppDatabaseObject() async {
    FloorDBViewModel floorDBViewModel = FloorDBViewModel(
        await $FloorAppDatabase.databaseBuilder('local.db').build());
    return floorDBViewModel.database;
  }

  Widget passwordTextField(
      BuildContext context,
      TextEditingController controller,
      String labelText,
      ValueChanged<String>? onValueChanged,
      ValueChanged<String>? onFieldSubmitted,
      double fontSize,
      VoidCallback onPressed,
      {bool isObscure = true}) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.done,
      obscureText: isObscure,
      decoration: InputDecoration(
        suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              isObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.black,
            ),
            onPressed: onPressed),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.pinkAccent,
          ),
        ),
        // border: InputBorder.none,
        labelText: labelText,
        labelStyle:const TextStyle(
          fontSize: 10,
          color:  Colors.black,
        ),
        isDense: false,
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      controller: controller,
    );
  }

  Padding getPadding(
      {double top = 0,
        double bottom = 0,
        double right = 0,
        double left = 0}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(left, top, right, bottom),
    );
  }

  Widget emailTextField(
      BuildContext context,
      TextEditingController controller,
      String labelText,
      ValueChanged<String>? onValueChanged,
      ValueChanged<String>? onFieldSubmitted,
      double fontSize) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        // border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.pinkAccent,
          ),
        ),
        labelText: labelText,
        labelStyle:const TextStyle(
          fontSize: 10,
          color:  Colors.black,
        ),
        isDense: false,
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      controller: controller,
    );
  }

  Widget emailTextFieldWithBackground(
      BuildContext context,
      TextEditingController controller,
      String labelText,
      ValueChanged<String>? onValueChanged,
      ValueChanged<String>? onFieldSubmitted,
      double fontSize) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        border: InputBorder.none,
        labelText: labelText,
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        labelStyle:const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color:  Colors.green,
        ),
        isDense: false,
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      cursorColor: Colors.green,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      controller: controller,
    );
  }

  Widget commonTextInputFieldWithBackground(BuildContext context,
      double fontSize,
      String fieldText,
      int maxLines,
      TextInputAction textInputAction,
      TextInputType textInputType,
      TextEditingController controller,
      ValueChanged<String> onFieldSubmitted,
      ValueChanged<String> onChanged,
      VoidCallback onTap) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        labelText: fieldText,
        labelStyle:const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color:  Colors.green,
        ),
        isDense: false,
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      cursorColor: Colors.green,
      keyboardType: textInputType,
      autocorrect: false,
      controller: controller,
    );
  }

  Widget passwordTextFieldWithBackground(
      BuildContext context,
      TextEditingController controller,
      String labelText,
      ValueChanged<String>? onValueChanged,
      ValueChanged<String>? onFieldSubmitted,
      double fontSize,
      VoidCallback onPressed,
      {bool isObscure = true}) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: TextInputAction.done,
      obscureText: isObscure,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              isObscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.green,
            ),
            onPressed: onPressed),
        labelText: labelText,
        labelStyle:const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color:  Colors.green,
        ),
        isDense: false,
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      cursorColor: Colors.green,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      controller: controller,
    );
  }


  Widget commonTextInputField(BuildContext context,
      double fontSize,
      String fieldText,
      int maxLines,
      TextInputAction textInputAction,
      TextInputType textInputType,
      TextEditingController controller,
      ValueChanged<String> onFieldSubmitted,
      ValueChanged<String> onChanged,
      VoidCallback onTap) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        labelText: fieldText,
        labelStyle:const TextStyle(
          fontSize: 10,
          color:  Colors.black,
        ),
        isDense: false,
      ),
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      keyboardType: textInputType,
      autocorrect: false,
      controller: controller,
    );
  }

  Widget commonTextInputFieldWithSuffixIcon(BuildContext context,
      double fontSize,
      String fieldText,
      int maxLines,
      TextInputAction textInputAction,
      TextInputType textInputType,
      TextEditingController controller,
      IconData suffixIcon,
      VoidCallback suffixIconOnClick) {
    return TextFormField(
      enabled: true,
      textAlign: TextAlign.start,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        suffixIcon: IconButton(
            splashRadius: 20,
            icon: Icon(
              suffixIcon,
              color: Colors.green,
            ),
            onPressed: suffixIconOnClick),
        labelText: fieldText,
        labelStyle:const TextStyle(
          fontSize: 10,
          color:  Colors.black,
        ),
        isDense: false,
      ),
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      keyboardType: textInputType,
      autocorrect: false,
      controller: controller,
    );
  }

  Widget getIconWithText(
      icon,
      Color color,
      double iconSize,
      String buttonText,
      double fontSize,
      VoidCallback onPressed
      ) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          IconButton(
              splashRadius: 20,
              icon: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
              onPressed: onPressed),
          getNormalText(buttonText, color, 1, fontSize)
        ],
      ),
    );
  }

  Widget getIcon(
      IconData icon,
      Color color,
      double iconSize,
      VoidCallback onPressed
      ) {
    return GestureDetector(
      onTap: onPressed,
      child: IconButton(
          splashRadius: 20,
          icon: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          onPressed: onPressed),
    );
  }

  Widget commonButton(
      BuildContext context,
      String buttonText,
      double fontSize,
      Color buttonBgColor,
      Color buttonBorderColor,
      Color buttonTextColor,
      EdgeInsets padding,
      VoidCallback onPressed
      ) {
    return TextButton(
        onPressed: onPressed,
        child: Container(
            padding: padding,
            margin: padding,
            decoration: BoxDecoration(
                color: buttonBgColor,
                border: Border.all(color: buttonBorderColor),
                borderRadius: BorderRadius.circular(30)
            ),
            child: getNormalText(buttonText, buttonTextColor, 1, fontSize)));
  }

  Widget commonSubmitButton(
      BuildContext context,
      String buttonText,
      double fontSize,
      Color buttonBgColor,
      Color buttonBorderColor,
      Color buttonTextColor,
      EdgeInsets padding,
      VoidCallback onPressed
      ) {
    return TextButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Expanded(
              child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                      color: buttonBgColor,
                      border: Border.all(color: buttonBorderColor),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: getNormalTextWithCenterAlignment(buttonText, buttonTextColor, 1, fontSize, FontWeight.bold)),
            ),
          ],
        ));
  }

  BoxDecoration getBoxDecorationWithColor(Color buttonBgColor, Color borderColor,double radius) {
    return BoxDecoration(
        color: buttonBgColor,
        border: Border.all(color: borderColor,width:2),
        borderRadius: BorderRadius.circular(radius)
    );
  }

  Widget getNormalText(String text, Color color, int maxLines, double fontSize) {
    return Text(text,
        maxLines: maxLines,
        style: TextStyle(fontSize: fontSize, color: color));
  }

  Widget getNormalTextWithCenterAlignment(String text, Color color, int maxLines, double fontSize, FontWeight fontWeight) {
    return Text(text,
        maxLines: maxLines,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, color: color,fontWeight: fontWeight));
  }

  Widget getSlider(BuildContext context, double sliderValue, double maximumValue,Color activeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: activeColor,
          inactiveTrackColor: Colors.grey,
          trackShape: const RectangularSliderTrackShape(),
          trackHeight: 12.0,
          thumbColor: Colors.white,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
          overlayColor: Colors.transparent,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0),
        ),
        child: Slider(
          value: sliderValue,
          max: maximumValue,
          divisions: 100,
          label: sliderValue.round().toString(),
          onChanged: (double value) {  },
        )
      ),
    );
  }

  Widget getNormalTextWithBold(String text, Color color, int maxLines, double fontSize) {
    return Text(text,
        maxLines: maxLines,
        style: TextStyle(fontSize: fontSize, color: color,fontWeight: FontWeight.bold));
  }

  Widget commonAppBar(double fontSize,String name,VoidCallback onclick,VoidCallback secondryIconClick,{IconData icon = Icons.person_outline, IconData secondryIcon = Icons.logout}) {
    return Container(
      height: 70,
      color: Colors.indigo,
      child: Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            getIcon(icon, Colors.white, 30, onclick),
            getNormalText(name, Colors.white, 1, fontSize),
            getIcon(secondryIcon, Colors.white, 30, secondryIconClick),
          ],
        ),
      ),
    );
  }

  commonDialog(
      BuildContext context,
      double fontSize,
      double iconSize,
      String dialogTitleText,
      Color dialogTitleTextColor,
      Widget widget, VoidCallback onClickCancelButton) {
    return AlertDialog(
      insetPadding: const EdgeInsets.fromLTRB(10,0,10,0),
      titlePadding: const EdgeInsets.fromLTRB(10,0,10,0),
      contentPadding: const EdgeInsets.fromLTRB(10,0,10,0),
      backgroundColor:Colors.white,
      shape: const RoundedRectangleBorder(),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getNormalText(dialogTitleText, dialogTitleTextColor, 1, fontSize),
          getIcon(Icons.cancel, Colors.red, iconSize, onClickCancelButton)
        ],
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10,0,10,0),
        child: widget,
      ),
    );
  }

  addExpenseDialog(
      BuildContext context,
      double fontSize,
      double iconSize,
      String dialogTitleText,
      Color dialogTitleTextColor,
      TextEditingController amountTextEditingController,
      TextEditingController dateTimeTextEditingController,
      TextEditingController cityTextEditingController,
      ValueChanged reasonDropdownOnChanged,
      List<String> list,
      String? dropDownValue,
      VoidCallback pickLocation,
      dynamic pickDate,
      VoidCallback submitButtonClick,
      VoidCallback onClickCancelButton) {
    return AlertDialog(
      insetPadding: const EdgeInsets.fromLTRB(10,0,10,0),
      titlePadding: const EdgeInsets.fromLTRB(15,0,10,0),
      contentPadding: const EdgeInsets.fromLTRB(10,0,10,0),
      backgroundColor:Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getNormalTextWithBold(dialogTitleText, dialogTitleTextColor, 1, fontSize),
          getIcon(Icons.cancel, Colors.black, iconSize, onClickCancelButton)
        ],
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10,0,10,0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: getBoxDecorationWithColor(Colors.white,Colors.green, 15),
              child: commonTextInputField(
                  context,
                  12,
                  "Expense Amount",
                  1,
                  TextInputAction.next,
                  TextInputType.number,
                  amountTextEditingController,
                      (value) { },
                      (value) { },
                      () { }),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: getBoxDecorationWithColor(Colors.white,Colors.green, 15),
              child: commonTextInputFieldWithSuffixIcon(
                  context,
                  12,
                  "Expense Time",
                  1,
                  TextInputAction.next,
                  TextInputType.datetime,
                  dateTimeTextEditingController,
                  Icons.access_time_filled_sharp,
                      () {
                    DatePicker.showDateTimePicker(
                      context,
                      minTime: DateTime(2000, 01, 01, 00, 00),
                      maxTime: DateTime.now(),
                      theme: const DatePickerTheme(
                          headerColor: Colors.green,
                          backgroundColor: Colors.white,
                          itemStyle: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          cancelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12),
                          doneStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12)),
                      onConfirm: pickDate,
                    );
                  }),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: getBoxDecorationWithColor(Colors.white,Colors.green, 15),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    iconSize: 20,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    iconEnabledColor: Colors.green,
                    onChanged: reasonDropdownOnChanged ,
                    hint:Container(
                       padding: const EdgeInsets.only(left: 15),
                        child: getNormalText("Select Reason", Colors.black54, 1, 11)
                    ),
                    items: list.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    value: dropDownValue,
                    style: const TextStyle(
                        color:Colors.black, fontSize: 10),
                    isExpanded: true,
                  )),
            ),
            Container(
              decoration: getBoxDecorationWithColor(Colors.white,Colors.green, 15),
              child: commonTextInputFieldWithSuffixIcon(
                  context,
                  12,
                  "Expense Place",
                  1,
                  TextInputAction.next,
                  TextInputType.text,
                  cityTextEditingController,
                  Icons.location_on_sharp,pickLocation
                  ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: commonSubmitButton(
                          context,
                          "Add",
                          14,
                          Colors.green,
                          Colors.white,
                          Colors.white,
                          const EdgeInsets.symmetric(vertical: 10,horizontal: 20),submitButtonClick
                          )
                  ),
                  Expanded(
                      child: commonSubmitButton(
                          context,
                          "Cancel",
                          14,
                          Colors.white,
                          Colors.green,
                          Colors.green,
                          const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
                              onClickCancelButton
                          )
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }


  Future<bool?> getToast(String text) {
    return Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.pink,
        textColor: Colors.white,
        fontSize: 14);
  }

  launchPage(BuildContext context, Widget builder) async {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => builder));
  }

  Widget topTabBar(
      BuildContext context,
      int length,
      String title1,
      String title2,
      Color color,
      double fontSize,
      tabController,
      Widget title1Page,
      Widget title2Page) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 48,
              width: MediaQuery.of(context).size.width,
              color: Colors.grey,
            ),
            TabBar(
              indicator: const BoxDecoration(color: Colors.deepOrangeAccent),
              tabs: [
                Container(
                  alignment: Alignment.center,
                  child: Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title1)
                      ],
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title2)
                      ],
                    ),
                  ),
                ),
              ],
              controller: tabController,
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [title1Page, title2Page],
          ),
        )
      ],
    );
  }

  void printLog(String text){
    print("object$text");
  }
}
