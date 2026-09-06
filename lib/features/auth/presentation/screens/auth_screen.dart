// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isSignUp = false;

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _nameController = TextEditingController();
//   final _ageController = TextEditingController();
//   final _weightController = TextEditingController();
//   String _fitnessGoal = 'Weight Loss';

//   final List<String> _goals = ['Weight Loss', 'Muscle Gain', 'Maintenance'];

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _nameController.dispose();
//     _ageController.dispose();
//     _weightController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     try {
//       if (_isSignUp) {
//         await authProvider.signUp(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//           name: _nameController.text.trim(),
//           age: int.tryParse(_ageController.text.trim()),
//           weight: double.tryParse(_weightController.text.trim()),
//           fitnessGoal: _fitnessGoal,
//         );
//       } else {
//         await authProvider.login(
//           _emailController.text.trim(),
//           _passwordController.text.trim(),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString().replaceAll('Exception: ', '')),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isSignUp ? 'Create Account' : 'Welcome Back'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               if (_isSignUp) ...[
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(labelText: 'Full Name'),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Enter your name' : null,
//                 ),
//                 const SizedBox(height: 12),
//               ],
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email Address'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (val) => val == null || !val.contains('@')
//                     ? 'Enter a valid email'
//                     : null,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//                 validator: (val) => val == null || val.length < 6
//                     ? 'Password must be at least 6 characters'
//                     : null,
//               ),
//               if (_isSignUp) ...[
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextFormField(
//                         controller: _ageController,
//                         decoration: const InputDecoration(labelText: 'Age'),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: TextFormField(
//                         controller: _weightController,
//                         decoration:
//                             const InputDecoration(labelText: 'Weight (kg)'),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField<String>(
//                   initialValue: _fitnessGoal,
//                   decoration: const InputDecoration(labelText: 'Fitness Goal'),
//                   items: _goals
//                       .map((goal) => DropdownMenuItem(
//                             value: goal,
//                             child: Text(goal),
//                           ))
//                       .toList(),
//                   onChanged: (val) {
//                     if (val != null) setState(() => _fitnessGoal = val);
//                   },
//                 ),
//               ],
//               const SizedBox(height: 24),
//               authProvider.isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : ElevatedButton(
//                       onPressed: _submit,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       child: Text(_isSignUp ? 'Sign Up' : 'Log In'),
//                     ),
//               TextButton(
//                 onPressed: () => setState(() => _isSignUp = !_isSignUp),
//                 child: Text(
//                   _isSignUp
//                       ? 'Already have an account? Log In'
//                       : "Don't have an account? Sign Up",
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//update :

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String _fitnessGoal = 'Weight Loss';

  final List<String> _goals = ['Weight Loss', 'Muscle Gain', 'Maintenance'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isSignUp) {
        await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          weight: double.tryParse(_weightController.text.trim()),
          fitnessGoal: _fitnessGoal,
        );
      } else {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Welcome Back'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),

              // Custom Password Field with Visibility Toggle Icon
              PasswordTextField(
                controller: _passwordController,
                label: 'Password',
              ),

              if (_isSignUp) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.scale),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _fitnessGoal,
                  decoration: const InputDecoration(
                    labelText: 'Fitness Goal',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  items: _goals
                      .map((goal) => DropdownMenuItem(
                            value: goal,
                            child: Text(goal),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fitnessGoal = val);
                  },
                ),
              ],
              const SizedBox(height: 24),
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_isSignUp ? 'Sign Up' : 'Log In'),
                    ),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Log In'
                      : "Don't have an account? Sign Up",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateful Widget handling password visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: (val) => val == null || val.length < 6
          ? 'Password must be at least 6 characters'
          : null,
    );
  }
}
