import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';

class ServerConnectScreen extends StatefulWidget {
  const ServerConnectScreen({super.key});

  @override
  State<ServerConnectScreen> createState() => _ServerConnectScreenState();
}

class _ServerConnectScreenState extends State<ServerConnectScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Try to load last used server
    _urlController.text = 'http://192.168.1.100:8000';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Runner Race Timer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to your race server',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 48),

                // Server URL Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Server',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Server URL',
                            hintText: 'http://192.168.x.x:8000',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _connect,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_done),
                            label: Text(_isLoading ? 'Connecting...' : 'Connect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _login,
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Help text
                Text(
                  'Enter your race server URL to connect,\nor login with your credentials',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        throw Exception('Please enter a server URL');
      }

      // Test connection first
      final testResponse = await http.get(Uri.parse('$url/health'));
      if (testResponse.statusCode != 200) {
        throw Exception('Server not responding (status: ${testResponse.statusCode})');
      }

      // Just connect, don't login yet
      await context.read<AppState>().connectToServer(url);

      if (context.mounted) {
        // Show success, user needs to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected! Now please login with your credentials'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Focus on username field
        FocusScope.of(context).requestFocus(_usernameFocus);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect: ${e.toString()}\n\nMake sure:\n• Server is running\n• URL is correct (http://IP:8000)\n• You\'re on the same network';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        throw Exception('Please enter a server URL first');
      }

      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        throw Exception('Please enter username and password');
      }

      // Test connection first
      final testResponse = await http.get(Uri.parse('$url/health'));
      if (testResponse.statusCode != 200) {
        throw Exception('Server not responding');
      }

      // Connect if not already connected
      final appState = context.read<AppState>();
      if (!appState.isConnectedToServer || appState.serverUrl != url) {
        await appState.connectToServer(url);
      }
      
      // Login
      await appState.login(username, password);

      if (context.mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: ${e.toString()}\n\nCheck:\n• Username/password correct\n• Server is running\n• Same network';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
