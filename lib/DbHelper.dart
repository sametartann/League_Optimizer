import 'package:mysql1/mysql1.dart';
import 'dart:async';

class Database{

  Database();

  MySqlConnection? conn;

  Future<void> connectDB() async {
    // Open a connection (CAPSTONE_2024 db should already exist)
    conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '12345',
      db: 'CAPSTONE_2024',
      ),
    );

    // Create a connection object
    print("Database connetcion made!");
  }

  Future<String> sendQuery (String sqlQuery) async {

    final results = await conn?.query(sqlQuery);
    //print("Query sent: $sqlQuery");

    late var result;
    for (var row in results!) {
      result = row[0];
    }

    return result.toString();
  }

  Future<List<String>> sendListQuery(String sqlQuery) async {

    final results = await conn?.query(sqlQuery);
    //print("Query sent: $sqlQuery");

    if (results != null) {
      List<String> resultList = [];
      for (var row in results) {
        resultList.add(row.first.toString());
      }
      return resultList;
    } else {
      return [];
    }
  }

  Future<dynamic> noReturnQuery (String sqlQuery) async {
    // Send a query and get the results
    await conn?.query(sqlQuery);
    //print("Query sent: $sqlQuery");
  }

  Future<void> closeDB() async {
    // Close the connection
    await conn?.close();
    print("Database connection closed!");
  }

}

