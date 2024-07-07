import 'package:flutter/material.dart';
import 'package:capstone2024_svb/main.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;

late String leagueID;
late String userID;

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371e3; // Earth's radius in meters
  final double phi1 = lat1 * math.pi / 180;
  final double phi2 = lat2 * math.pi / 180;
  final double deltaPhi = (lat2 - lat1) * math.pi / 180;
  final double deltaLambda = (lon2 - lon1) * math.pi / 180;

  final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(deltaLambda / 2) *
          math.sin(deltaLambda / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  final double distance = R * c;
  return distance / 1000; // Return distance in kilometers
}

class ShowResultPage extends StatefulWidget {
  final String leagueName;
  final String leagueID;
  final String userID;

  final int teamCount;
  final List<Map<String, String>> teamNames;

  ShowResultPage({
    required this.leagueName,
    required this.leagueID,
    required this.teamCount,
    required this.teamNames,
    required this.userID,
  });

  @override
  _ShowResultPageState createState() => _ShowResultPageState();
}

class _ShowResultPageState extends State<ShowResultPage> {
  late String leagueName;
  late int teamCount;
  late List<Map<String, String>> teamNames;
  late int fixtureCount;
  late int weekCount;
  late List<String> weekList = <String>[];
  late String dropdownValue;
  late List<Map<String, dynamic>> fixtures = [];

  @override
  void initState() {
    super.initState();
    leagueName = widget.leagueName;
    leagueID = widget.leagueID;
    userID = widget.userID;
    teamCount = widget.teamCount;
    teamNames = widget.teamNames;
    fixtureCount = (teamCount / 2).toInt();
    weekCount = (2 * (teamCount - 1)).toInt();
    for (int i = 1; i <= weekCount; i++) {
      weekList.add("Week " + i.toString());
    }
    dropdownValue = weekList.first;

    fetchFixtures().then((value) {
      setState(() {
        fixtures = value;
      });
    });
  }

  Future<double> fetchTravelDistance(
      List<String> homeTeamID, List<String> awayTeamID) async {
    // Fetch CITY info
    List<String> result7 = await database.sendListQuery(
        "SELECT CITY FROM TEAM_INFO WHERE TEAM_ID = ${homeTeamID[0]}");
    List<String> result8 = await database.sendListQuery(
        "SELECT CITY FROM TEAM_INFO WHERE TEAM_ID = ${awayTeamID[0]}");

    final homeCityLat = await database.sendQuery(
        "SELECT lat FROM COUNTRY_CITIES WHERE city = '${result7[0]}'");
    final homeCityLng = await database.sendQuery(
        "SELECT lng FROM COUNTRY_CITIES WHERE city = '${result7[0]}'");
    final awayCityLat = await database.sendQuery(
        "SELECT lat FROM COUNTRY_CITIES WHERE city = '${result8[0]}'");
    final awayCityLng = await database.sendQuery(
        "SELECT lng FROM COUNTRY_CITIES WHERE city = '${result8[0]}'");

    final homeLat = double.parse(homeCityLat);
    final homeLng = double.parse(homeCityLng);
    final awayLat = double.parse(awayCityLat);
    final awayLng = double.parse(awayCityLng);

    final travelDistance =
        calculateDistance(homeLat, homeLng, awayLat, awayLng);

    return travelDistance;
  }

  Future<List<Map<String, dynamic>>> fetchBreak() async {
    // Fetch break info
    List<String> result5 = await database.sendListQuery(
        "SELECT TEAM_ID FROM BREAK_TEAM_INFO WHERE LEAGUE_ID = $leagueID");
    List<String> result6 = await database.sendListQuery(
        "SELECT WEEK_INFO FROM BREAK_TEAM_INFO WHERE LEAGUE_ID = $leagueID");
    List<Map<String, dynamic>> breakResults = [];
    for (int i = 0; i < result5.length; i++) {
      breakResults.add({
        'TEAM_ID': result5[i],
        'WEEK_INFO': result6[i],
      });
    }

    return breakResults;
  }

  Future<List<Map<String, dynamic>>> fetchBreakCounts() async {
    List<String> teams = await database.sendListQuery(
        "SELECT DISTINCT TEAM_ID FROM BREAK_TEAM_INFO WHERE LEAGUE_ID = $leagueID");
    Map<String, int> breakCounts = {};

    for (String team in teams) {
      int count = int.parse(await database.sendQuery(
          "SELECT COUNT(*) FROM BREAK_TEAM_INFO WHERE TEAM_ID = $team AND LEAGUE_ID = $leagueID"));
      breakCounts[team] = count;
    }

    List<Map<String, dynamic>> breakCountsList = [];
    for (String team in breakCounts.keys) {
      String teamName = await getTeamName(team);
      breakCountsList.add({
        'teamId': team,
        'teamName': teamName,
        'breakCount': breakCounts[team],
      });
    }

    // Sort the break counts in descending order
    breakCountsList.sort((a, b) => b['breakCount'].compareTo(a['breakCount']));

    return breakCountsList;
  }

  Future<List<Map<String, dynamic>>> fetchFixtures() async {
    List<String> result1 = await database.sendListQuery(
        "SELECT MATCH_ID FROM MATCH_INFO WHERE LEAGUE_ID = $leagueID order by MATCH_ID");
    List<String> result2 = await database.sendListQuery(
        "SELECT HOMETEAM_ID FROM MATCH_INFO WHERE LEAGUE_ID = $leagueID order by MATCH_ID");
    List<String> result3 = await database.sendListQuery(
        "SELECT AWAYTEAM_ID FROM MATCH_INFO WHERE LEAGUE_ID = $leagueID order by MATCH_ID");
    List<String> result4 = await database.sendListQuery(
        "SELECT MATCH_WEEK FROM MATCH_INFO WHERE LEAGUE_ID = $leagueID order by MATCH_ID");

    List<Map<String, dynamic>> breakResults = await fetchBreak();

    List<Map<String, dynamic>> fixtures = [];
    for (int i = 0; i < result1.length; i++) {
      final travelDistance =
          await fetchTravelDistance([result2[i]], [result3[i]]);
      // Check if the team has a break in this week
      if (breakResults.any((element) =>
          element['TEAM_ID'] == result2[i] &&
          element['WEEK_INFO'] == result4[i] &&
          breakResults.any((element) =>
              element['TEAM_ID'] == result3[i] &&
              element['WEEK_INFO'] == result4[i]))) {
        fixtures.add({
          'matchId': result1[i],
          'homeTeamId': result2[i],
          'homeTeamName': await getTeamName(result2[i]),
          'isHomeBreak': true,
          'awayTeamId': result3[i],
          'awayTeamName': await getTeamName(result3[i]),
          'isAwayBreak': true,
          'matchWeek': result4[i],
          'travelDistance': travelDistance,
        });
      } else if (breakResults.any((element) =>
          element['TEAM_ID'] == result2[i] &&
          element['WEEK_INFO'] == result4[i])) {
        fixtures.add({
          'matchId': result1[i],
          'homeTeamId': result2[i],
          'homeTeamName': await getTeamName(result2[i]),
          'isHomeBreak': true,
          'awayTeamId': result3[i],
          'awayTeamName': await getTeamName(result3[i]),
          'isAwayBreak': false,
          'matchWeek': result4[i],
          'travelDistance': travelDistance,
        });
      } else if (breakResults.any((element) =>
          element['TEAM_ID'] == result3[i] &&
          element['WEEK_INFO'] == result4[i])) {
        fixtures.add({
          'matchId': result1[i],
          'homeTeamId': result2[i],
          'homeTeamName': await getTeamName(result2[i]),
          'isHomeBreak': false,
          'awayTeamId': result3[i],
          'awayTeamName': await getTeamName(result3[i]),
          'isAwayBreak': true,
          'matchWeek': result4[i],
          'travelDistance': travelDistance,
        });
      } else {
        fixtures.add({
          'matchId': result1[i],
          'homeTeamId': result2[i],
          'homeTeamName': await getTeamName(result2[i]),
          'isHomeBreak': false,
          'awayTeamId': result3[i],
          'awayTeamName': await getTeamName(result3[i]),
          'isAwayBreak': false,
          'matchWeek': result4[i],
          'travelDistance': travelDistance,
        });
      }
    }

    return fixtures;
  }

  Future<String> getTeamName(String teamID) async {
    String result = await database
        .sendQuery("SELECT TEAM_NAME FROM TEAM_INFO WHERE TEAM_ID = $teamID");
    return result;
  }

  List<Map<String, dynamic>> getFixturesForWeek(String week) {
    return fixtures
        .where((fixture) =>
            fixture['matchWeek'].toString() == week.replaceAll('Week ', ''))
        .toList();
  }

  List<List<Map<String, dynamic>>> groupFixturesByWeek() {
    List<List<Map<String, dynamic>>> fixturesByWeek =
        List.generate(weekCount, (_) => []);
    for (var fixture in fixtures) {
      int weekIndex = int.parse(fixture['matchWeek']) - 1;
      Map<String, dynamic> fixtureMap = {
        'matchId': fixture['matchId'],
        'homeTeamId': fixture['homeTeamId'],
        'homeTeamName': fixture['homeTeamName'],
        'isHomeBreak': fixture['isHomeBreak'],
        'awayTeamId': fixture['awayTeamId'],
        'awayTeamName': fixture['awayTeamName'],
        'isAwayBreak': fixture['isAwayBreak'],
        'matchWeek': fixture['matchWeek'],
        'travelDistance': fixture['travelDistance'].toStringAsFixed(2),
      };
      fixturesByWeek[weekIndex].add(fixtureMap);
    }
    return fixturesByWeek;
  }

  Future<void> createExcel() async {
    List<Map<String, dynamic>> breakResults = await fetchBreak();
    var status = await Permission.storage.request();
    if (status.isGranted) {
      var excel = Excel.createExcel();

      Sheet sheet1 = excel['Week by Week League Fixture'];
      sheet1.appendRow(['Week', 'Home Team', 'Away Team', 'Travel Distance']);
      for (int i = 0; i < fixtures.length; i++) {
        sheet1.appendRow([
          'Week ${fixtures[i]['matchWeek']}',
          fixtures[i]['homeTeamName'],
          fixtures[i]['awayTeamName'],
          fixtures[i]['travelDistance']
        ]);
      }

      // Add and populate 'Break Info' sheet
      Sheet sheet2 = excel['Break Info'];
      sheet2.appendRow(['Week', 'Team']);
      for (int i = 0; i < breakResults.length; i++) {
        sheet2.appendRow([
          'Week ${breakResults[i]['WEEK_INFO']}',
          await getTeamName(breakResults[i]['TEAM_ID'])
        ]);
      }

      excel.setDefaultSheet(sheet1.sheetName);
      String? directory = await FilePicker.platform.getDirectoryPath();

      if (directory != null) {
        var file = File('$directory/$leagueName.xlsx');
        file.writeAsBytesSync(excel.encode()!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file created: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No directory selected')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission Denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/uefa.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black12,
              Colors.black45,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              'League Fixture (Week by week)',
              style: TextStyle(color: Colors.deepPurple[100]),
            ),
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _fullFixtureAction(context),
                  _teamFixtureAction(context),
                  _travelDistanceAction(context),
                  _breakReportAction(context),
                  _swapAction(context),
                  _excelAction(context),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${widget.leagueName}',
                    style: TextStyle(
                        color: Colors.teal[300],
                        fontSize: 55,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                _weekDropDown(context),
                _weekMatchInfo(context),
                _information(),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation
              .endFloat, // Added for FloatingActionButton
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.teal[700],
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(widget.userID)),
                (Route<dynamic> route) => false,
              );
            },
            label: Text(
              'Back to Main Page',
              style: TextStyle(color: Colors.deepPurple[100]),
            ),
            icon: Icon(Icons.home, color: Colors.deepPurple[100], size: 25),
          ),
        ),
      ),
    );
  }

  _excelAction(context){
    return Tooltip(
      message: 'Download Fixtures as Excel',
      child: IconButton(
        onPressed: () {
          createExcel();
        },
        icon: Icon(Icons.arrow_circle_down),
        iconSize: 45,
      ),
    );
  }

  _swapAction(context){
    return Tooltip(
      message: 'Swap Matches',
      child: IconButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SwapWeeksPage(
                  weekList: weekList,
                  teamNames: teamNames,
                  leagueName: leagueName,
                  teamCount: teamCount),
            ),
          );
        },
        icon: Icon(Icons.swap_horiz),
        iconSize: 45,
      ),
    );
  }

  _breakReportAction(context){
    return Tooltip(
    message: 'View Break Report',
    child: IconButton(
      onPressed: () async {
        List<Map<String, dynamic>> breakCounts =
        await fetchBreakCounts();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BreakCountsPage(breakCounts: breakCounts),
          ),
        );
      },
      icon: Icon(Icons.assessment),
      iconSize: 45,
    ),
  );
  }

  _travelDistanceAction(context){
    return Tooltip(
      message: 'View Total Travel Distance Report',
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TravelDistancePage(fixtures: fixtures),
            ),
          );
        },
        icon: Icon(Icons.airplanemode_active),
        iconSize: 45,
      ),
    );
  }

  _teamFixtureAction(context){
    return Tooltip(
      message: "Select a team to view its Fixture",
      child: IconButton(
        onPressed: () async {
          final selectedTeam = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamSelectionPage(
                  fixturesByWeek: groupFixturesByWeek(),
                  teamNames: widget.teamNames),
            ),
          );
          if (selectedTeam != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamSchedulePage(
                  teamNames: widget.teamNames,
                  selectedTeam: selectedTeam,
                  fixturesByWeek: groupFixturesByWeek(),
                ),
              ),
            );
          }
        },
        icon: Icon(Icons.sports_soccer),
        iconSize: 45,
      ),
    );
  }

  _fullFixtureAction(context){
    return Tooltip(
      message: 'View Full Fixture',
      child: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullFixturePage(
                fixturesByWeek: groupFixturesByWeek(),
              ),
            ),
          );
        },
        icon: Icon(Icons.calendar_today),
        iconSize: 45,
      ),
    );
  }

  _information() {
    return IconButton(
      icon: Icon(Icons.info_outline, color: Colors.red[500], size: 45),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "1 - Teams written in red have a break in this week.\n2 - Back to Main Page will forward you directly to main page. You can come again from main page. If you want to save the league, download it as an excel from top right!",
                      style: TextStyle(fontSize: 14.0),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.cyan[700]!),
                        alignment: Alignment.center,
                        mouseCursor: MaterialStateProperty.all<MouseCursor>(
                            SystemMouseCursors.click),
                        minimumSize:
                            MaterialStateProperty.all(const Size(100.0, 40.0)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                      ),
                      child: Text('Exit',
                          style: TextStyle(color: Colors.deepPurple[100])),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  _weekMatchInfo(context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: getFixturesForWeek(dropdownValue).length,
        itemBuilder: (context, index) {
          final fixture = getFixturesForWeek(dropdownValue)[index];
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Match ${index + 1}',
                  style: TextStyle(fontSize: 18, color: Colors.teal[300]),
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${fixture['homeTeamName']}',
                  style: TextStyle(
                    fontSize: 24,
                    color: fixture['isHomeBreak']
                        ? Colors.red[500]
                        : Colors.deepPurple[100],
                    fontWeight: fixture['isHomeBreak']
                        ? FontWeight.bold
                        : FontWeight.normal,
                    decorationColor: Colors.red[500],
                  ),
                ),
                Text(
                  ' vs ',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.deepPurple[100],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  '${fixture['awayTeamName']}',
                  style: TextStyle(
                    fontSize: 24,
                    color: fixture['isAwayBreak']
                        ? Colors.red[500]
                        : Colors.deepPurple[100],
                    fontWeight: fixture['isAwayBreak']
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _weekDropDown(context) {
    return SizedBox(
      width: 140,
      height: 55,
      child: DropdownButtonFormField<String>(
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        iconSize: 24,
        iconDisabledColor: Colors.blue,
        iconEnabledColor: Colors.teal,
        decoration: InputDecoration(
          fillColor: Colors.deepPurple[100],
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        menuMaxHeight: 400,
        dropdownColor: Colors.deepPurple[100],
        value: dropdownValue,
        items: weekList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.teal,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            dropdownValue = value!;
          });
        },
      ),
    );
  }
}

// FullFixturePage
class FullFixturePage extends StatelessWidget {
  final List<List<Map<String, dynamic>>> fixturesByWeek;

  FullFixturePage({required this.fixturesByWeek});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/uefa.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black12,
              Colors.black45,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            backgroundColor: Colors.transparent,
            title: Text(
              'Full Fixture',
              style: TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
            ),
          ),
          body: FullFixtureList(),
        ),
      ),
    );
  }

  Widget FullFixtureList() => ListView.builder(
        itemCount: fixturesByWeek.length,
        itemBuilder: (context, weekIndex) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 2.0),
                child: Text(
                  'Week ${weekIndex + 1}',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.deepPurple[100],
                      fontWeight: FontWeight.bold),
                ),
              ),
              DataTable(
                headingRowHeight: 40,
                dataRowHeight: 40,
                columns: [
                  DataColumn(
                    label: Text(
                      'Home Team',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[500],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Away Team',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[500],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Travel Distance (km)',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[500],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: fixturesByWeek[weekIndex].map((fixture) {
                  return DataRow(cells: [
                    DataCell(
                      Text(
                        fixture['homeTeamName'] ?? '',
                        style: TextStyle(
                            fontSize: 18, color: Colors.deepPurple[100]),
                      ),
                    ),
                    DataCell(
                      Text(
                        fixture['awayTeamName'] ?? '',
                        style: TextStyle(
                            fontSize: 18, color: Colors.deepPurple[100]),
                      ),
                    ),
                    DataCell(
                      Text(
                        fixture['travelDistance'] ?? '',
                        style: TextStyle(
                            fontSize: 18, color: Colors.deepPurple[100]),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ],
          );
        },
      );
}

class TeamSchedulePage extends StatelessWidget {
  final List<Map<String, String>> teamNames;
  final String selectedTeam;
  final List<List<Map<String, dynamic>>> fixturesByWeek;
  List<String> schedule = [];

  TeamSchedulePage(
      {required this.teamNames,
      required this.selectedTeam,
      required this.fixturesByWeek});

  @override
  Widget build(BuildContext context) {

    for (var weekFixtures in fixturesByWeek) {
      for (var fixture in weekFixtures) {
        if (fixture.containsValue(selectedTeam)) {
          schedule
              .add('${fixture['homeTeamName']} vs ${fixture['awayTeamName']}');
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/uefa.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black12,
                Colors.black45,
              ]),
        ),
        child: _teamSchedule(context),
      ),
    );
  }

  _teamSchedule(context){
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.deepPurple[100]),
        backgroundColor: Colors.transparent,
        title: Text('Schedule for $selectedTeam',
            style: TextStyle(fontSize: 20, color: Colors.deepPurple[100])),
      ),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: ListTile(
                title: Center(
                  child: Text(
                    'Week ${index + 1}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[500],
                        fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Center(
                  child: Text(
                    schedule[index],
                    style: TextStyle(
                        fontSize: 20, color: Colors.deepPurple[100]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TeamSelectionPage extends StatelessWidget {
  final List<Map<String, String>> teamNames;
  final List<List<Map<String, dynamic>>> fixturesByWeek;

  TeamSelectionPage({required this.teamNames, required this.fixturesByWeek});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/uefa.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black12,
                Colors.black45,
              ]),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            backgroundColor: Colors.transparent,
            title: Text('Select Team',
                style: TextStyle(fontSize: 20, color: Colors.deepPurple[100])),
          ),
          body: ListView.builder(
            itemCount: teamNames.length,
            itemBuilder: (context, index) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Center(
                      child: Text(
                        teamNames[index]['name'] ?? '',
                        style: TextStyle(
                            fontSize: 20, color: Colors.deepPurple[100]),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, teamNames[index]['name']);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class TravelDistancePage extends StatelessWidget {
  final List<Map<String, dynamic>> fixtures;

  TravelDistancePage({required this.fixtures});

  @override
  Widget build(BuildContext context) {
    // Compute total travel distance for each team
    Map<String, double> totalTravelDistances = {};
    for (var fixture in fixtures) {
      String awayTeamName = fixture['awayTeamName'];
      double travelDistance = fixture['travelDistance'];

      if (totalTravelDistances.containsKey(awayTeamName)) {
        totalTravelDistances[awayTeamName] =
            totalTravelDistances[awayTeamName]! + travelDistance;
      } else {
        totalTravelDistances[awayTeamName] = travelDistance;
      }
    }

    // Convert map to a list of entries and sort by travel distance in descending order
    List<MapEntry<String, double>> sortedEntries = totalTravelDistances.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/uefa.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black12,
              Colors.black45,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            backgroundColor: Colors.transparent,
            title: Text('Travel Distances',
                style: TextStyle(color: Colors.deepPurple[100])),
          ),
          body: ListView.builder(
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              String teamName = sortedEntries[index].key;
              double totalDistance = sortedEntries[index].value;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Center(
                      child: Text(
                        teamName,
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[500],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: Center(
                      child: Text(
                        'Total Travel Distance: ${totalDistance.toStringAsFixed(2)} km',
                        style: TextStyle(
                            fontSize: 16, color: Colors.deepPurple[100]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class BreakCountsPage extends StatelessWidget {
  final List<Map<String, dynamic>> breakCounts;

  BreakCountsPage({required this.breakCounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/uefa.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black12,
              Colors.black45,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            backgroundColor: Colors.transparent,
            title: Text(
              'Break Counts',
              style: TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
            ),
          ),
          body: BreakCountsListWidget(),
        ),
      ),
    );
  }

  Widget BreakCountsListWidget() => ListView.builder(
        itemCount: breakCounts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 5,
                  height: 50,
                ),
                Text(
                  "${breakCounts[index]['teamName']} :\t",
                  style: TextStyle(fontSize: 24, color: Colors.deepPurple[100]),
                ),
                SizedBox(
                  width: 5,
                  height: 50,
                ),
                Text(
                  '${breakCounts[index]['breakCount']} breaks',
                  style: TextStyle(fontSize: 24, color: Colors.deepPurple[100]),
                ),
              ],
            ),
            subtitle: Center(
              // Wrap the FutureBuilder with Center widget
              child: FutureBuilder<List<String>>(
                future: fetchBreakWeeks(breakCounts[index]['teamId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Text(
                      '${snapshot.data?.join(', ')}',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[500],
                          fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
            ),
          );
        },
      );

  Future<List<String>> fetchBreakWeeks(String teamId) async {
    List<String> result = await database.sendListQuery(
        "SELECT WEEK_INFO FROM BREAK_TEAM_INFO WHERE TEAM_ID = $teamId AND LEAGUE_ID = $leagueID");
    return result.map((week) => 'Week $week').toList();
  }
}

class SwapWeeksPage extends StatefulWidget {
  List<String> weekList;
  List<Map<String, String>> teamNames;
  int teamCount;
  String leagueName;

  SwapWeeksPage(
      {required this.weekList,
      required this.teamNames,
      required this.teamCount,
      required this.leagueName});

  @override
  _SwapWeeksPageState createState() => _SwapWeeksPageState();
}

class _SwapWeeksPageState extends State<SwapWeeksPage> {
  late List<Map<String, String>> teamNames;
  late List<String> weekList;
  late String dropdownValue;
  late String dropdownValue2;
  late int swappedWeek1;
  late int swappedWeek2;

  @override
  void initState() {
    super.initState();
    teamNames = widget.teamNames;
    weekList = widget.weekList;
    dropdownValue = weekList[0];
    dropdownValue2 = weekList[1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/uefa.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black12,
                  Colors.black45,
                ]),
          ),
          child: _swapWidget(context),
        ),
      ),
    );
  }

  _swapWidget(context){
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.deepPurple[100]),
        backgroundColor: Colors.transparent,
        title: Text(
          'Swap Weeks',
          style: TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 55,
                    child: DropdownButtonFormField<String>(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      iconSize: 24,
                      iconDisabledColor: Colors.blue,
                      iconEnabledColor: Colors.teal,
                      decoration: InputDecoration(
                        fillColor: Colors.deepPurple[100],
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      menuMaxHeight: 400,
                      dropdownColor: Colors.deepPurple[100],
                      value: dropdownValue,
                      items: weekList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          dropdownValue = value!;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('SWAP',
                        style: TextStyle(
                            color: Colors.deepPurple[100],
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ),
                  SizedBox(
                    width: 140,
                    height: 55,
                    child: DropdownButtonFormField<String>(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      iconSize: 24,
                      iconDisabledColor: Colors.blue,
                      iconEnabledColor: Colors.teal,
                      decoration: InputDecoration(
                        fillColor: Colors.deepPurple[100],
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      menuMaxHeight: 400,
                      dropdownColor: Colors.deepPurple[100],
                      value: dropdownValue2,
                      items: weekList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          dropdownValue2 = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    swappedWeek1 =
                        int.parse(dropdownValue.replaceAll('Week ', ''));
                    swappedWeek2 =
                        int.parse(dropdownValue2.replaceAll('Week ', ''));
                    print(
                        "Swapped week: $swappedWeek1 with week: $swappedWeek2");
                    if (_swapWeeks()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowResultPage(
                            leagueID: leagueID,
                            teamNames: teamNames,
                            teamCount: widget.teamCount,
                            leagueName: widget.leagueName,
                            userID: userID,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Swap Weeks',
                    style: TextStyle(
                        fontSize: 18, color: Colors.deepPurple[100]),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal[700],
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                '!  IMPORTANT  !',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '        Swapping weeks may cause conflicts in breaks!\nPlease re-calculate breaks manually after swap operation',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ])),
      ),
    );
  }

  bool _swapWeeks() {
    if (swappedWeek1 == swappedWeek2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot swap the same weeks'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    database.noReturnQuery(
        "UPDATE MATCH_INFO SET MATCH_WEEK = 99999 WHERE MATCH_WEEK = $swappedWeek1 AND LEAGUE_ID = $leagueID");
    database.noReturnQuery(
        "UPDATE MATCH_INFO SET MATCH_WEEK = $swappedWeek1 WHERE MATCH_WEEK = $swappedWeek2 AND LEAGUE_ID = $leagueID");
    database.noReturnQuery(
        "UPDATE MATCH_INFO SET MATCH_WEEK = $swappedWeek2 WHERE MATCH_WEEK = 99999 AND LEAGUE_ID = $leagueID");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Weeks $swappedWeek1 and $swappedWeek2 swapped successfully'),
        backgroundColor: Colors.green,
      ),
    );
    return true;
  }
}
