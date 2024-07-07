import 'package:capstone2024_svb/SignupPage.dart';
import 'package:capstone2024_svb/main.dart';
import 'package:capstone2024_svb/PasswordResetPage.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _userID;
  late String _eMail;
  late String _password;

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
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
          body: Container(
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _header(context),
                _inputField(context),
                _forgotPassword(context),
                _signup(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[100],
          ),
        ),
        Text(
          "Enter your credential to login",
          style: TextStyle(fontSize: 16, color: Colors.deepPurple[100]),
        ),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: "E-Mail",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.deepPurple[100],
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
          onChanged: (value) {
            _eMail = value;
          },
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.deepPurple[100],
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
          onChanged: (value) {
            _password = value;
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            String hashedPassword = hashPassword(_password);
            if ((await database.sendQuery(
                "SELECT COUNT(*) FROM USER_AUTHENTICATION WHERE Email = '$_eMail' AND USERPASS = '$hashedPassword';")).toString().characters.first != "0") {
              _userID = (await database.sendQuery(
                  "SELECT USER_ID FROM USER_AUTHENTICATION WHERE Email = '$_eMail' AND USERPASS = '$hashedPassword';")).toString();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage(_userID)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User Authentication Failed!'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.teal[700],
          ),
          child: Text(
            "Login",
            style: TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
          ),
        ),
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PasswordResetPage()),
        );
      },
      child: Text(
        "Forgot password?",
        style: TextStyle(fontSize: 18, color: Colors.teal[400]),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(fontSize: 16, color: Colors.deepPurple[100]),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            );
          },
          child: Text(
            "Sign Up",
            style: TextStyle(fontSize: 20, color: Colors.teal[400]),
          ),
        ),
      ],
    );
  }
}
