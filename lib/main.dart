import 'package:capstone2024_svb/LoginPage.dart';
import 'package:capstone2024_svb/TeamInputScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'DbHelper.dart';
import 'package:capstone2024_svb/ShowResultPage.dart';


late Database database;
const informationText = 'League Optimizer allows you to create a new league by entering the names, cities, and values of the teams.';

void main() async{

  database = Database();
  database.connectDB();

  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Text Labels',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final String _userID;

  HomePage(this._userID, {Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {

  List<Map<String, dynamic>> _leagues = [];

  @override
  void initState() {
    super.initState();
    _fetchLeagues();
  }

  Future<void> _fetchLeagues() async {
    final leagues = await getLeaguesByUserID(userID);
    setState(() {
      _leagues = leagues;
    });
  }

  Future<List<Map<String, dynamic>>> getLeaguesByUserID(String userID) async{
    List<Map<String, dynamic>> leagues = [];
    var leagueIDs = await database.sendListQuery(
      "SELECT DISTINCT LEAGUE_ID FROM LEAGUE_INFO WHERE USER_ID = $userID;",
    );

    for (var leagueID in leagueIDs) {
      var leagueName = await database.sendQuery(
        "SELECT LEAGUE_NAME FROM LEAGUE_INFO WHERE LEAGUE_ID = $leagueID;",
      );

      var teamCount = int.parse(await database.sendQuery(
        "SELECT COUNT(*) FROM TEAM_INFO WHERE LEAGUE_ID = $leagueID;",
      ));

      List<Map<String, String>> teamNames = await getTeamNamesByLeagueID(leagueID);

      leagues.add({
        'LEAGUE_ID': leagueID,
        'LEAGUE_NAME': leagueName,
        'TEAM_COUNT': teamCount,
        'TEAM_NAMES': teamNames,
      });
    }

    return leagues;
  }

  Future<List<Map<String, String>>> getTeamNamesByLeagueID(String leagueID) async {
    List<Map<String, String>> teamNames = [];
    var teamIDs = await database.sendListQuery(
      "SELECT TEAM_ID FROM TEAM_INFO WHERE LEAGUE_ID = $leagueID;",
    );

    for (var teamID in teamIDs) {
      var teamName = await database.sendQuery(
        "SELECT TEAM_NAME FROM TEAM_INFO WHERE TEAM_ID = $teamID AND LEAGUE_ID = $leagueID;",
      );

      var teamCity = await database.sendQuery(
        "SELECT CITY FROM TEAM_INFO WHERE TEAM_ID = $teamID AND LEAGUE_ID = $leagueID;",
      );

      var teamValue = await database.sendQuery(
        "SELECT TEAM_VALUE FROM TEAM_INFO WHERE TEAM_ID = $teamID AND LEAGUE_ID = $leagueID;",
      );

      teamNames.add({
        'name': teamName,
        'city': teamCity,
        'value': teamValue,
      });
    }

    return teamNames;
  }

  String get userID => widget._userID;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/uefa.jpg',),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient:  LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors:[
                Colors.black12,
                Colors.black45,
              ]
          ),
        ),
        child: MaterialApp(

          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.deepPurple[100]),
              backgroundColor: Colors.transparent,
              title:  Text('LEAGUE OPTIMIZER' , style: TextStyle(
                  fontSize: 36, color: Colors.teal[300], fontWeight: FontWeight.bold) ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_pin, color: Colors.white, size: 32.0),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(userID)),
                    );
                  },
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      //color: Colors.blue,
                    ),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 23.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home', style: TextStyle(fontSize: 15),),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage(userID)),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create New League', style: TextStyle(fontSize: 15),),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TeamInputScreen(userID)),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outlined),
                    title: const Text('Information', style: TextStyle(fontSize: 15),),
                    onTap: () {
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
                                      informationText,
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                    const SizedBox(height: 16.0),
                                    ElevatedButton(
                                      child: const Text('Exit'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ) );
                        },
                      );

                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_pin_circle_outlined),
                    title: const Text('My Profile', style: TextStyle(fontSize: 15),),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage(userID)),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),

                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:  [
                        Icon(
                          Icons.sports_soccer_outlined,
                          color: Colors.white70,
                          size: 120,
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'LEAGUE SCHEDULING SYSTEM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 70.0, // Adjusted font size
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple[100],
                              ),
                            ),
                          ),
                        ),
                        Icon(
                            Icons.sports_soccer_outlined,
                            color: Colors.white70,
                            size: 120
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.cyan[700]!),
                        alignment: Alignment.center,
                        mouseCursor: MaterialStateProperty.all<MouseCursor>(SystemMouseCursors.click),
                        minimumSize: MaterialStateProperty.all(const Size(400.0, 80.0)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TeamInputScreen(userID)),
                        );
                      },
                      child: Text('Create New League', style: TextStyle(fontSize: 32.0, color: Colors.deepPurple[100], fontWeight: FontWeight.bold)),
                    ),


                  ),

                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon:
                        Icon(Icons.info_outline, color: Colors.deepPurple[100], size: 35),
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
                                        informationText,
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                      const SizedBox(height: 16.0),
                                      ElevatedButton(
                                        child: const Text('Exit'),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'CREATED LEAGUES',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[100],
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  ..._leagues.reversed.map((league) {
                    return Container(
                      height: 55,
                      width: 500,
                      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      padding: EdgeInsets.symmetric( vertical: 1.0),
                      decoration: BoxDecoration(
                        color:Colors.teal[700],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: ListTile(
                        title: Text(
                          league['LEAGUE_NAME'],
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowResultPage(
                                leagueName: league['LEAGUE_NAME'],
                                leagueID: league['LEAGUE_ID'],
                                teamCount: league['TEAM_COUNT'],
                                teamNames: league['TEAM_NAMES'],
                                userID: userID,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {

  String _userID = '';

  ProfilePage(String userID, {super.key}) {
    _userID = userID;
  }

  String get userID => _userID;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String? _userName;
  String? _userSurname;
  String? _userPhone;
  String? _userEmail;

  Future<void> getUserInfo() async {

    var userNameResult = await database.sendQuery(
      "SELECT User_Name FROM USER_INFO WHERE USER_ID = ${widget.userID};",
    );
    _userName = userNameResult;

    var userSurnameResult = await database.sendQuery(
      "SELECT USER_SURNAME FROM USER_INFO WHERE USER_ID = ${widget.userID};",
    );
    _userSurname = userSurnameResult;

    var userPhoneResult = await database.sendQuery(
      "SELECT User_Phone FROM USER_INFO WHERE USER_ID = ${widget.userID};",
    );
    _userPhone = userPhoneResult;

    var userEmailResult = await database.sendQuery(
      "SELECT User_Email FROM USER_INFO WHERE USER_ID = ${widget.userID};",
    );
    _userEmail = userEmailResult;
  }

  @override
  void initState() {
    super.initState();
    getUserInfo().whenComplete(() => setState((){}) );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Profile'),

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const  CircleAvatar(
              radius: 75.0,
              backgroundImage: AssetImage('assets/profile.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 20),
            Text(
              "$_userName $_userSurname" ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                leading: const Icon(Icons.email),
                title: Text(_userEmail ?? ''),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: Text(_userPhone ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
