import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';
import 'test_harness.dart';
import 'results_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SDK on app launch
  try {
    await VerisoulSdk.configure(
      projectId: '<PROJECT_ID>',
      environment: VerisoulEnvironment.sandbox,
    );
    print('Verisoul SDK configured successfully');
  } catch (error) {
    print('Failed to configure Verisoul SDK: $error');
  }

  runApp(VerisoulWrapper(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: const Color(0xFF007AFF),
      ),
      home: const TestSuiteScreen(),
    );
  }
}

class TestSuiteScreen extends StatefulWidget {
  const TestSuiteScreen({Key? key}) : super(key: key);

  @override
  State<TestSuiteScreen> createState() => _TestSuiteScreenState();
}

class _TestSuiteScreenState extends State<TestSuiteScreen> {
  // Test state
  bool _showResults = false;
  TestResults? _testResults;
  String _testType = '';
  bool _isRunning = false;

  // Repeat Test Config
  final TextEditingController _repeatRoundsController =
      TextEditingController(text: '10');
  final TextEditingController _reinitMultipleController =
      TextEditingController(text: '3');
  bool _parallelMode = false;

  // Chaos Test Config
  final TextEditingController _chaosRoundsController =
      TextEditingController(text: '40');

  @override
  void dispose() {
    _repeatRoundsController.dispose();
    _reinitMultipleController.dispose();
    _chaosRoundsController.dispose();
    super.dispose();
  }

  Future<void> _handleRepeatTest() async {
    setState(() {
      _isRunning = true;
      _testType =
          _parallelMode ? 'Repeat Test (Parallel)' : 'Repeat Test (Sequential)';
    });

    final results = await runRepeatTest(
      int.tryParse(_repeatRoundsController.text) ?? 10,
      reinitMultiple: int.tryParse(_reinitMultipleController.text) ?? 3,
      parallel: _parallelMode,
    );

    setState(() {
      _testResults = results;
      _isRunning = false;
      _showResults = true;
    });
  }

  Future<void> _handleChaosTest() async {
    setState(() {
      _isRunning = true;
      _testType = 'Chaos Test';
    });

    final results = await runChaosTest(
      int.tryParse(_chaosRoundsController.text) ?? 40,
      concurrency: 8,
    );

    setState(() {
      _testResults = results;
      _isRunning = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const Divider(height: 40, color: Color(0xFFDDDDDD)),
                  // Repeat Test Section
                  _buildRepeatTestSection(),
                  const Divider(height: 40, color: Color(0xFFDDDDDD)),
                  // Chaos Test Section
                  _buildChaosTestSection(),
                  if (_isRunning) ...[
                    const SizedBox(height: 20),
                    _buildLoadingIndicator(),
                  ],
                ],
              ),
            ),
            if (_showResults && _testResults != null)
              ResultsView(
                results: _testResults!,
                testType: _testType,
                onDismiss: () {
                  setState(() {
                    _showResults = false;
                    _testResults = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          '🛡️',
          style: TextStyle(fontSize: 60),
        ),
        const SizedBox(height: 10),
        const Text(
          'Verisoul SDK Test Suite',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRepeatTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Test',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildInputRow(
                label: 'Number of Rounds:',
                controller: _repeatRoundsController,
                placeholder: '10',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Reinitialize Every:',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _reinitMultipleController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '3',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'rounds',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Parallel Mode (Fire All at Once)',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  Switch(
                    value: _parallelMode,
                    onChanged: (value) {
                      setState(() {
                        _parallelMode = value;
                      });
                    },
                    activeColor: const Color(0xFF007AFF),
                    activeTrackColor: const Color(0xFF81b0ff),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _parallelMode
                    ? '⚡ All requests fire simultaneously'
                    : '📝 Requests run sequentially',
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isRunning ? null : _handleRepeatTest,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isRunning ? const Color(0xFF999999) : const Color(0xFF007AFF),
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '🔁 Run Repeat Test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChaosTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chaos Test',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildInputRow(
                label: 'Number of Rounds:',
                controller: _chaosRoundsController,
                placeholder: '40',
              ),
              const SizedBox(height: 10),
              const Text(
                'Runs 8 concurrent workers with random delays',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isRunning ? null : _handleChaosTest,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isRunning ? const Color(0xFF999999) : const Color(0xFFFF9500),
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '🌪️ Run Chaos Test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: const [
        CircularProgressIndicator(
          color: Color(0xFF007AFF),
        ),
        SizedBox(height: 10),
        Text(
          'Running test...',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}
