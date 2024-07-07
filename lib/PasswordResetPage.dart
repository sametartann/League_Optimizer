import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'main.dart';

class PasswordResetPage extends StatefulWidget {
  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  late String _eMail = '';
  late String _phoneNumber = '';
  late String _newPassword = '';

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacter =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return hasUppercase && hasLowercase && hasSpecialCharacter;
  }

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
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.deepPurple[100]),
            title: Text('Reset Password',
                style: TextStyle(color: Colors.deepPurple[100])),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[100],
                      ),
                    ),
                    Text(
                      "Please enter your e-mail and phone number to reset your password.",
                      style: TextStyle(
                          fontSize: 16, color: Colors.deepPurple[100]),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                TextField(
                  decoration: InputDecoration(
                    hintText: "E-Mail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.deepPurple[100],
                    filled: true,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  onChanged: (value) {
                    _eMail = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Phone Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.deepPurple[100],
                    filled: true,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  onChanged: (value) {
                    _phoneNumber = value;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "New Password (at least 8 characters long and include uppercase, lowercase, and special characters)",
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
                    _newPassword = value;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    if (_eMail.isEmpty || _phoneNumber.isEmpty || _newPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields!'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else
                    if (!isValidPassword(_newPassword)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Password must be at least 8 characters long and include uppercase, lowercase, and special characters.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      String hashedPassword = hashPassword(_newPassword);
                      var result = await database.sendQuery(
                        "SELECT COUNT(*) FROM USER_AUTHENTICATION T1 JOIN USER_INFO T2 ON (T1.Email = T2.USER_EMAIL AND T1.USER_ID = T2.USER_ID) WHERE T1.Email = '$_eMail'  AND T2.USER_PHONE = '$_phoneNumber'",
                      );
                      if (result.toString().characters.first != "0") {
                        await database.noReturnQuery(
                          "UPDATE USER_AUTHENTICATION SET USERPASS = '$hashedPassword' WHERE Email = '$_eMail';",
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password successfully reset!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User not found!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal[700],
                    alignment: Alignment.center,
                    fixedSize: Size(300, 50),
                  ),
                  child: Text(
                    "Reset Password",
                    style:
                        TextStyle(fontSize: 20, color: Colors.deepPurple[100]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
