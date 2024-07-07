import 'package:capstone2024_svb/main.dart';
import 'package:capstone2024_svb/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // for the utf8.encode method

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _name = "";
  String _surname = "";
  String _phone = "";
  String _email = "";
  String _password1 = "";
  String _password2 = "";

  bool isValidPassword(String password) {
    if (password.length < 8) return false;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return hasUppercase && hasLowercase && hasSpecialCharacter;
  }

  bool isValidEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  bool isValidPhoneNumber(String phone) {
    String pattern = r'^\+?[0-9]{10,15}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(phone);
  }

  bool isValidName(String name) {
    String pattern = r'^[a-zA-Z]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(name);
  }

  bool isValidSurname(String surname) {
    String pattern = r'^[a-zA-Z]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(surname);
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
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
                ]
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        const SizedBox(height: 60.0),
                        Text(
                          "Sign Up",
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple[100]
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Create your account",
                          style: TextStyle(fontSize: 17, color: Colors.deepPurple[100]),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                          hintText: "Name (alphabetic characters only)",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.deepPurple[100],
                          filled: true,
                          prefixIcon: const Icon(Icons.person)),
                      onChanged: (value) {
                        _name = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                          hintText: "Surname (alphabetic characters only)",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.deepPurple[100],
                          filled: true,
                          prefixIcon: const Icon(Icons.person)),
                      onChanged: (value) {
                        _surname = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                          hintText: "Phone Number (10-15 digits)",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.deepPurple[100],
                          filled: true,
                          prefixIcon: const Icon(Icons.phone_in_talk)),
                      onChanged: (value) {
                        _phone = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                          hintText: "Email Address (e.g@gmail.com)",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.deepPurple[100],
                          filled: true,
                          prefixIcon: const Icon(Icons.email)),
                      onChanged: (value) {
                        _email = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Password (at least 8 characters long and include uppercase, lowercase, and special characters)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.deepPurple[100],
                        filled: true,
                        prefixIcon: const Icon(Icons.password),
                      ),
                      onChanged: (value) {
                        _password1 = value;
                      },
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Confirm Password (must match the password above)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.deepPurple[100],
                        filled: true,
                        prefixIcon: const Icon(Icons.password),
                      ),
                      onChanged: (value) {
                        _password2 = value;
                      },
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Already have an account?",
                          style: TextStyle(fontSize: 16, color: Colors.deepPurple[100]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(fontSize: 20, color: Colors.teal[400]),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!isValidName(_name)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Name can only contain alphabetic characters.',
                                  style: TextStyle(fontSize: 14,)),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (!isValidSurname(_surname)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Surname can only contain alphabetic characters.',
                                  style: TextStyle(fontSize: 14,)),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (!isValidPhoneNumber(_phone)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid phone number. Phone number length should be between 10-15 ',
                                  style: TextStyle(fontSize: 14,)),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (!isValidEmail(_email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid email address.',
                                  style: TextStyle(fontSize: 14,)),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }  else if ((await database.sendQuery(
                            "SELECT COUNT(*) FROM USER_INFO WHERE User_Email = '$_email';"))
                            .toString()
                            .characters
                            .first != "0") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'User with this email already exists.',
                                  style: TextStyle(fontSize: 14,)),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (!isValidPassword(_password1)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Password must be at least 8 characters long and include uppercase, lowercase, and special characters.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } else if (_password1 != _password2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          String hashedPassword = hashPassword(_password2);

                          await database.noReturnQuery(
                              "INSERT INTO USER_INFO (User_Name, User_Surname, User_Phone, User_Email) VALUES ('$_name', '$_surname', '$_phone','$_email');");
                          final userIDQueryResult = await database.sendQuery(
                              "SELECT User_ID FROM USER_INFO WHERE User_Name = '$_name' AND User_Surname = '$_surname' AND User_Phone = '$_phone' AND User_Email = '$_email';");
                          final userID = userIDQueryResult
                              .toString()
                              .characters
                              .string;

                          // Insert into USER_AUTHENTICATION table
                          await database.noReturnQuery(
                              "INSERT INTO USER_AUTHENTICATION (USER_ID, EMAIL, USERPASS) VALUES ('$userID', '$_email', '$hashedPassword');");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile Created Successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        }
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal[700],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
