import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'CustomerHome.dart';

class Registration extends StatefulWidget {
  const Registration({Key? key}) : super(key: key);

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isObscuredPassword = true;
  bool _isObscuredConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (passwordController.text == confirmPasswordController.text) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Create user document in Firestore (upon successful registration)
        if (userCredential.user != null) {
          final uid = userCredential.user!.uid;
          final usersCollection = _firestore.collection('Users');
          await usersCollection.doc(uid).set({
            'uid': uid, // Mandatory, use the Firebase Authentication uid
            'fullName': fullNameController.text,
            'role': 'customer', // Default role is "customer"
            //'profilephoto': 'NULL'
          });

          // Navigate to CustomerHome
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerHome()),
          );
        }
      } on FirebaseAuthException catch (e) {
        _showDialog('Registration Error', e.toString());
      } catch (e) {
        print('Error registering user: $e'); // Log general errors
        _showDialog('Registration Error', 'An error occurred. Please try again.');
      }
    } else {
      _showDialog('Error', 'Passwords do not match.');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF412F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Create an account to start finding great deals!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: Color(0xFFFF412F)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person, color: Color(0xFFFF412F)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: _isObscuredPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF412F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscuredPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _isObscuredPassword = !_isObscuredPassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: _isObscuredConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF412F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscuredConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _isObscuredConfirmPassword = !_isObscuredConfirmPassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Color(0xFFFF412F),
                minimumSize: const Size(double.infinity, 50), // Make the button stretch
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
