import 'package:capstone2024_svb/ShowResultPage.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:capstone2024_svb/main.dart';

class TeamInputScreen extends StatefulWidget {

  String _userID = '';

  TeamInputScreen(String userID, {super.key}) {
    _userID = userID;
  }

  String get userID => _userID;

  @override
  _TeamInputScreenState createState() => _TeamInputScreenState();
}

class _TeamInputScreenState extends State<TeamInputScreen> {
  int numTeams = 0;
  List<Map<String, String>> teams = [];
  String leagueName = "";
  bool isSingleCountryLeague = false; // Track if it's a single-country league
  String selectedCountry = ""; // Track the selected country
  List<String> countries = [];
  List<String> selectedCities = List.generate(99999, (index) => "");
  List<String> cities = [];
  late String _leagueID;
  bool allFieldsFilled = false;

  @override
  void initState() {
    super.initState();
    fetchCountries(
        "SELECT COUNTRY FROM country_cities GROUP BY COUNTRY order by COUNTRY")
        .then((value) {
      setState(() {
        countries = value;
      });
    });
    fetchCities(selectedCountry).then((value) {
      setState(() {
        cities = value;
      });
    });
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _promptLeagueType();
    });
  }

  Future<List<String>> fetchCountries(String q) async {
    // Send the query to retrieve countries
    String query = q;
    List<String> result = await database.sendListQuery(query);

    // Return the list of countries
    return result;
  }

  Future<List<String>> fetchCities(String country) async {
    // Send the query to retrieve cities for the selected country
    String query;
    if (isSingleCountryLeague) {
      query =
      "SELECT CITY FROM country_cities WHERE COUNTRY = '$country' GROUP BY CITY ORDER BY CITY";
    } else {
      query = "SELECT CITY FROM country_cities GROUP BY CITY ORDER BY CITY";
    }

    List<String> result = await database.sendListQuery(query);

    // Return the list of cities
    return result;
  }

  // Method to handle country selection
  void _onCountrySelected(String country) async{
    setState(() {

    });
    // Fetch cities for the selected country
    fetchCities(country).then((value) {
      setState(() {
        cities = value;
      });
    });
  }

  // Prompt the user to select league type
  Future<void> _promptLeagueType() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select League Type"),
          content: Text(
              "Do you want to create a single-country or multi-country league?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isSingleCountryLeague = true;
                });
                Navigator.of(context).pop();
              },
              child: Text('Single-Country'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isSingleCountryLeague = false;
                });
                Navigator.of(context).pop();
              },
              child: Text('Multi-Country'),
            ),
          ],
        );
      },
    );
  }

  void addTeamInputs(int num) {
    setState(() {
      numTeams = num;
      teams = List.generate(num, (i) => {"name": "", "city": "", "value": ""});
    });
  }

  void updateTeamInfo(int index, String name, String city, String value) {
    setState(() {
      teams[index]["name"] = name;
      teams[index]["city"] = city;
      teams[index]["value"] = value;
    });
  }

  String getTeamDataJson() {
    return jsonEncode(_leagueID);
  }

  Future<bool> _sendDataToAPI() async {
    String jsonData = getTeamDataJson();

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/league'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData,
    );

    if (response.statusCode == 200) {
      print('Response: ${response.body}');
      return true;
    } else {
      print('Failed to send data. Error: ${response.statusCode}');
      return false;
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Sending data..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {

    allFieldsFilled = leagueName.isNotEmpty &&
        numTeams > 0 &&
        teams.every((team) =>
        team["name"]!.isNotEmpty &&
            team["city"]!.isNotEmpty &&
            team["value"]!.isNotEmpty);

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
            backgroundColor: Colors.transparent,
            title: Text(
              "Team Information",
              style: TextStyle(color: Colors.deepPurple[100]),
            ),
            actionsIconTheme: IconThemeData(color: Colors.deepPurple[100]),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "League Name",
                            filled: true,
                            fillColor: Colors.deepPurple[100],
                          ),
                          onChanged: (value) {
                            leagueName = value;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Number of Teams",
                            hintText: 'Enter a number',
                            filled: true,
                            fillColor: Colors.deepPurple[100],
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isEmpty) {
                              addTeamInputs(0);
                              return;
                            }
                            addTeamInputs(
                                (int.parse(value)) < 1 ? 0 : int.parse(value) > 100 ? 100 : int.parse(value) );
                            int.parse(value) > 100 ? ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maximum number of teams is 100. Team count set to 100.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            ) : null;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(
                                8.0), // Adjust the border radius as needed
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DropdownButton<String>(
                            value:
                            selectedCountry.isEmpty ? null : selectedCountry,
                            dropdownColor: Colors.deepPurple[100],
                            focusColor: Colors.deepPurple[100],
                            items: countries.map((String country) {
                              return DropdownMenuItem<String>(
                                value: country,
                                child: Text(country),
                              );
                            }).toList(),
                            onChanged: isSingleCountryLeague
                                ? (String? newValue) {
                              setState(() {
                                selectedCountry = newValue!;
                                // Logic to send query to database based on the selected country
                                selectedCities = List.generate(99999, (index) => "");
                                _onCountrySelected(selectedCountry);
                              });
                            }
                                : null,
                            // Disable the dropdown if not a single-country league
                            hint: Text("Select Country"),
                            isExpanded: true,
                            disabledHint: Text("X  Single-country league only  X",
                                style: TextStyle(color: Colors.red[900])),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),


                if (numTeams > 0 &&
                    (selectedCountry.isNotEmpty || !isSingleCountryLeague)) ...[
                  titles(),
                  Column(
                    children: List.generate(
                        numTeams, (index) => buildTeamInput(index)),
                  ),
                ],


                if (numTeams > 0 &&
                    (selectedCountry.isNotEmpty || !isSingleCountryLeague))
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: allFieldsFilled ? () async {
                        try {
                          // Execute the INSERT query
                          (await database.noReturnQuery(
                              "INSERT INTO LEAGUE_INFO (LEAGUE_NAME, COUNTRY, TEAM_COUNT, USER_ID) VALUES "
                                  "('$leagueName', '$selectedCountry', '$numTeams', '${widget.userID}');")
                          );

                          // Retrieve the last inserted ID
                          var results = await database.sendQuery('SELECT LAST_INSERT_ID()');
                          _leagueID = results;

                          print('Inserted row with LEAGUE_ID: $_leagueID');
                        } catch (e) {
                          print('Error inserting user authentication: $e');
                        } finally {
                          // Insert the team data
                          for (int i = 0; i < numTeams; i++) {
                            try {
                              // Execute the INSERT query
                              (await database.noReturnQuery(
                                  "INSERT INTO TEAM_INFO (TEAM_NAME, CITY, TEAM_VALUE, LEAGUE_ID) VALUES "
                                      "('${teams[i]["name"]}', '${teams[i]["city"]}', '${teams[i]["value"]}', $_leagueID);")
                              );
                            } catch (e) {
                              print('Error inserting team data: $e');
                            }
                          }
                        }

                        _showLoadingDialog();

                        Future<bool> respond = _sendDataToAPI();
                        if (await respond) {
                          _hideLoadingDialog();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Team data sent successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShowResultPage(
                                  leagueName: leagueName,
                                  teamCount: numTeams,
                                  teamNames: teams,
                                  leagueID: _leagueID,
                                  userID: widget.userID,
                                )),
                          );
                        } else {
                          _hideLoadingDialog();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to send team data. Please try again.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                      ),
                      child: Text(
                        "Create League",
                        key: Key("createLeagueButton"),
                        style: TextStyle(color: Colors.deepPurple[100]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget titles(){
    return Padding(padding: const EdgeInsets.symmetric(horizontal:16.0 , vertical: 0.0),
      child: Row(
        children:[

          Expanded(
              child:Text("Team Names" , style: TextStyle(color: Colors.deepPurple[100]))
          ),
          const SizedBox(width: 35.0),
          Expanded(
              child:Text("Team Values" , style: TextStyle(color: Colors.deepPurple[100]))
          ),
          const SizedBox(width: 35.0),
          Expanded(
              child:Text("Team Cities" , style: TextStyle(color: Colors.deepPurple[100]))
          ),
        ],
      ),
    );
  }


  Widget buildTeamInput(int index) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children:[
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                  hintText: "Team ${index + 1} Name",
                  //helperText: "Team ${index + 1} Name",
                  helperStyle: TextStyle(color: Colors.deepPurple[100]),
                  filled: true,
                  fillColor: Colors.white70),
              onChanged: (value) {
                updateTeamInfo(index, value, teams[index]["city"]!,
                    teams[index]["value"]!);
              },
            ),
          ),


          SizedBox(width: 35.0),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                //helperText: "Team ${index + 1} Value",
                  helperStyle: TextStyle(color: Colors.deepPurple[100]),
                  hintText: 'Team ${index + 1} Value',
                  suffixText: '\$',
                  filled: true,
                  fillColor: Colors.white70),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                updateTeamInfo(
                    index, teams[index]["name"]!, teams[index]["city"]!, value);
              },
            ),
          ),
          const SizedBox(width: 35.0 ),
          Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0 , vertical: 0.0),
                child:
                DropdownButton<String>(
                  value: selectedCities.elementAt(index).isEmpty ? null : selectedCities.elementAt(index),
                  selectedItemBuilder: (BuildContext context) => cities
                      .map<Widget>((String item) => Text(item, style: TextStyle(color: Colors.black, fontSize: 15)))
                      .toList(),
                  dropdownColor: Colors.white,
                  items: cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city, style: TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCities[index] = value!;
                    });

                    updateTeamInfo(index, teams[index]["name"]!, value!,
                        teams[index]["value"]!);
                  },
                  hint: Text("Select City"),
                  isExpanded: true,
                ),
              )
          ),
        ],
      ),
    );
  }
}
