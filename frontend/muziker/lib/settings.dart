import 'package:flutter/material.dart';
import 'package:muziker/theme_manager.dart';
import 'package:provider/provider.dart';
import 'generation_settings.dart';
import 'settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  final bool isOffline;

  const SettingsPage({Key? key, this.isOffline = false}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasChanges = false;
  late GenerationSettings _originalSettings;

  @override
  void initState() {
    super.initState();
    // Store the original settings when the page is opened
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _originalSettings = settingsProvider.settings.copy();
  }

  void _onSettingsChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  void _revertChanges() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.updateSettings(_originalSettings);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;
    final themeManager = Provider.of<ThemeManager>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _revertChanges();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Settings'),
                  Switch(
                    value: themeManager.isDark,
                    onChanged: (value) {
                      themeManager.toggleTheme();
                      _onSettingsChanged();
                    },
                  ),
                  if (!widget.isOffline) ...[
                    const SizedBox(height: 20),
                    const Text('Generation Settings'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Guidance Scale'),
                        Text(settings.guidanceScale.toStringAsFixed(1)),
                      ],
                    ),
                    Slider(
                      label: 'Guidance Scale',
                      min: 1,
                      max: 10,
                      divisions: 9,
                      value: settings.guidanceScale,
                      onChanged: (value) {
                        settingsProvider.updateGuidanceScale(value);
                        _onSettingsChanged();
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Max New Tokens'),
                        Text(settings.maxNewTokens.toString()),
                      ],
                    ),
                    Slider(
                      label: 'Max New Tokens',
                      min: 50,
                      max: 500,
                      divisions: 9,
                      value: settings.maxNewTokens.toDouble(),
                      onChanged: (value) {
                        settingsProvider.updateMaxNewTokens(value.toInt());
                        _onSettingsChanged();
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Do Sample'),
                        Switch(
                          value: settings.doSample,
                          onChanged: (value) {
                            settingsProvider.updateDoSample(value);
                            _onSettingsChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Temperature'),
                        Text(settings.temperature.toStringAsFixed(1)),
                      ],
                    ),
                    Slider(
                      label: 'Temperature',
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      value: settings.temperature,
                      onChanged: (value) {
                        settingsProvider.updateTemperature(value);
                        _onSettingsChanged();
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Number of Words'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (settings.numWords > 1) {
                              settingsProvider.updateNumWords(settings.numWords - 1);
                              _onSettingsChanged();
                            }
                          },
                        ),
                        Text(settings.numWords.toString()),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            settingsProvider.updateNumWords(settings.numWords + 1);
                            _onSettingsChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Weight Method'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWeightMethodButton(
                          context,
                          'Logarithmic',
                          settings.weightMethod == 'logarithmic',
                              () {
                            settingsProvider.updateWeightMethod('logarithmic');
                            _onSettingsChanged();
                          },
                        ),
                        _buildWeightMethodButton(
                          context,
                          'Exponential',
                          settings.weightMethod == 'exponential',
                              () {
                            settingsProvider.updateWeightMethod('exponential');
                            _onSettingsChanged();
                          },
                        ),
                        _buildWeightMethodButton(
                          context,
                          'Balanced',
                          settings.weightMethod == 'balanced',
                              () {
                            settingsProvider.updateWeightMethod('balanced');
                            _onSettingsChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _hasChanges
                  ? ElevatedButton(
                onPressed: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('params').doc(user.uid).update({
                      'guidanceScale': settings.guidanceScale,
                      'maxNewTokens': settings.maxNewTokens,
                      'temperature': settings.temperature,
                      'numWords': settings.numWords,
                      'weightMethod': settings.weightMethod,
                      'doSample': settings.doSample,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Settings saved')),
                    );
                    setState(() {
                      _hasChanges = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeManager.themeData.primaryColor,
                  minimumSize: Size(120, 40),
                ),
                child: Text('Save Settings'),
              )
                  : Container(),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () async {
                  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('params').get();
                  double totalGuidanceScale = 0;
                  num totalMaxNewTokens = 0;
                  double totalTemperature = 0;
                  num totalNumWords = 0;
                  int trueCount = 0;
                  int falseCount = 0;
                  Map<String, int> weightMethodCounts = {
                    'logarithmic': 0,
                    'exponential': 0,
                    'balanced': 0,
                  };
                  int count = snapshot.docs.length;

                  for (var doc in snapshot.docs) {
                    totalGuidanceScale += doc['guidanceScale'];
                    totalMaxNewTokens += doc['maxNewTokens'];
                    totalTemperature += doc['temperature'];
                    totalNumWords += doc['numWords'];
                    if (doc['doSample']) {
                      trueCount++;
                    } else {
                      falseCount++;
                    }
                    weightMethodCounts[doc['weightMethod']] =
                        (weightMethodCounts[doc['weightMethod']] ?? 0) + 1;
                  }

                  double avgGuidanceScale = totalGuidanceScale / count;
                  double avgMaxNewTokens = totalMaxNewTokens / count;
                  double avgTemperature = totalTemperature / count;
                  double avgNumWords = totalNumWords / count;

                  String mostOccurringWeightMethod = weightMethodCounts.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key;
                  bool mostOccurringDoSample = trueCount > falseCount;

                  settingsProvider.updateSettings(GenerationSettings(
                    guidanceScale: avgGuidanceScale,
                    maxNewTokens: avgMaxNewTokens.round(),
                    doSample: mostOccurringDoSample,
                    temperature: avgTemperature,
                    numWords: avgNumWords.round(),
                    weightMethod: mostOccurringWeightMethod,
                  ));

                  _onSettingsChanged();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: Size(120, 40),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 10,
                ),
                child: Text('Best Params'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMethodButton(BuildContext context, String label, bool isSelected, VoidCallback onPressed) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : themeManager.themeData.textTheme.button!.color,
        backgroundColor: isSelected ? themeManager.themeData.primaryColor : themeManager.themeData.disabledColor,
        elevation: 5,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
