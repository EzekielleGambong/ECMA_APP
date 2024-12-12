import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'welcome.dart';

class RegisterPage extends StatefulWidget {
  

  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  final _formKey = GlobalKey<FormState>();
  
  final _firestore = FirebaseFirestore.instance;
  final _fireAuth = FirebaseAuth.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

 Future<void> _register() async {
  try {
    // Check if email already exists
    final signInMethods = await _fireAuth.fetchSignInMethodsForEmail(_emailController.text);
    if (signInMethods.isNotEmpty) {
      // Email is already in use
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email already exists. Please use a different email.")),
      );
      return; // Exit the registration process
    }

    // Proceed to create a new user
    await _fireAuth.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    ).then((userCredential) async {
      final userid = userCredential.user?.uid;

 
      if (userid != null) {
        await _firestore.collection('users').doc(userid).set({
          'username': _usernameController.text,
          'email': _emailController.text,
          'profile': 'none',
        });

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.08),
                Image.asset(
                  'assets/icons/ecmalogo.png',
                  height: 100,
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                Text(
                  "Sign Up",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextFormField(
                        hint: 'Username',
                        keyboardType: TextInputType.text,
                        onSaved: (name) {
                      
                        },
                        controller: _usernameController
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        hint: 'Email',
                        keyboardType: TextInputType.text,
                        onSaved: (phone) {
                          // Save it
                        },
                        controller:_emailController,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        hint: 'Password',
                        keyboardType: TextInputType.visiblePassword,
                        onSaved: (password) {
                          // Save it
                        },
                        controller: _passwordController,
                    
                        obscureText: true,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        hint: 'Confirm Password',
                        keyboardType: TextInputType.text,
                        onSaved: (name) {
                          // Save it
                        },
                        obscureText: true,
                        controller: _confirmController
                        
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF00BF6D),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text("Sign Up"),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const LoginPage()), // Ensure LoginPage is imported
                          );
                        },
                        child: Text.rich(
                          const TextSpan(
                            text: "Already have an account? ",
                            children: [
                              TextSpan(
                                text: "Sign in",
                                style: TextStyle(color: Color(0xFF00BF6D)),
                              ),
                            ],
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .color!
                                        .withOpacity(0.64),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
  

 

  TextFormField _buildTextFormField({
    required String hint,
    required TextInputType keyboardType,
    required void Function(String?) onSaved,
    bool obscureText = false, required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5FCF9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0 * 1.5, vertical: 16.0),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
      keyboardType: keyboardType,
      onSaved: onSaved,
      obscureText: obscureText,
    );
  }
