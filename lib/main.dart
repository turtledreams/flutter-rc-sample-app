import 'dart:math';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RC App',
      home: MyHomePage(title: 'RC/AB'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static String SERVER_URL = 'https://try.count.ly';
  static String APP_KEY = 'YOUR_APP_KEY';

  Color _backgroundColor = Colors.blue;
  List<String> textList = [];
  ScrollController _textScrollController = ScrollController();
  int counter = 1;
  String _variant = "_";
  String _key = "_";
  String _value = "_";
  String _isNew = "_";
  String expToEnrollExit = "your_key";

  @override
  void initState() {
    super.initState();
    Countly.isInitialized().then((bool isInitialized) {
      if (!isInitialized) {
        CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY)
          ..enableRemoteConfigAutomaticTriggers()
          ..enableRemoteConfigValueCaching()
          ..setRequiresConsent(false)
          ..remoteConfigRegisterGlobalCallback(
              (rResult, error, fullValueUpdate, downloadedValues) {
            print("Global Callback");
          })
          ..setLoggingEnabled(true);

        Countly.initWithConfig(config).then((value) {
          Countly.start();
          remoteConfigRegisterDownloadCallback();
        }); // Initialize the countly SDK.
      } else {
        print('Countly: Already initialized.');
      }
    });
  }

  void changeIDmerge() {
    print('Clicked changeIDmerge');
    Countly.changeDeviceId('newIDmerged', true);
  }

  void changeID() {
    print('Clicked changeID');
    Countly.changeDeviceId('newID', false);
    _key = '_';
    _value = '_';
    _variant = '_';
    _isNew = '_';
  }

  void enterTemp() {
    print('Clicked enterTemp');
    Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
  }

  void removeConsent() {
    Countly.removeConsent(['remote-config']);
  }

  void giveConsent() {
    Countly.giveConsent(['remote-config']);
  }

  void downloadAllKeys() {
    print('Clicked downloadAllKeys');
    Countly.instance.remoteConfig.downloadAllKeys(null);
  }

  void downloadSpecificKeys() {
    print('Clicked downloadSpecificKeys');
    Countly.instance.remoteConfig.downloadSpecificKeys(['rc1', 'ab1'], null);
  }

  void downloadOmittingKeys() {
    print('Clicked downloadOmittingKeys');
    Countly.instance.remoteConfig.downloadOmittingKeys(['rc1', 'ab_1'], null);
  }

  void remoteConfigClearAll() {
    Countly.instance.remoteConfig.clearAll();
    showCustomToast(context, 'Cleared all RC data', null);
  }

  void remoteConfigEnrollIntoABTestsForKeys() {
    Countly.instance.remoteConfig.enrollIntoABTestsForKeys([expToEnrollExit]);
    remoteConfigGetAllValues(expToEnrollExit);
    showCustomToast(
        context, 'Enrolled into AB tests with key: $expToEnrollExit', null);
  }

  void remoteConfigExitABTestsForKeys() {
    Countly.instance.remoteConfig.exitABTestsForKeys([expToEnrollExit]);
    setState(() {
      if (_key == expToEnrollExit) {
        _key = '_';
        _value = '_';
        _variant = '_';
        _isNew = '_';
      }
    });
    showCustomToast(
        context, 'Exited AB tests with key: $expToEnrollExit', null);
  }

  Future<void> remoteConfigDownloadAllVariant() async {
    await Countly.instance.remoteConfig.testingDownloadVariantInformation(
      (rResult, error) {
        showCustomToast(context, 'Downloaded all variants', null);
      },
    );
  }

  void testingEnrollIntoVariantA() {
    Countly.instance.remoteConfig.testingEnrollIntoVariant(
        expToEnrollExit, "Variant C", (rResult, error) {
      if (rResult == RequestResult.success) {
        showCustomToast(context,
            'Successfully enrolled to Group C of key $expToEnrollExit', null);
        _variant = 'C';
        remoteConfigGetAllValues(expToEnrollExit);
      } else {
        showCustomToast(
            context,
            'Failed to enroll into Group C of key $expToEnrollExit',
            Colors.red);
      }
    });
  }

  void testingEnrollIntoVariantB() {
    Countly.instance.remoteConfig.testingEnrollIntoVariant(
        expToEnrollExit, "Variant B", (rResult, error) {
      if (rResult == RequestResult.success) {
        showCustomToast(context,
            'Successfully enrolled to Group B of key $expToEnrollExit', null);
        _variant = 'B';
        remoteConfigGetAllValues(expToEnrollExit);
      } else {
        showCustomToast(
            context,
            'Failed to enroll into Group B of key $expToEnrollExit',
            Colors.red);
      }
    });
  }

  Future<void> testingGetAllVariants() async {
    String resultString = '';
    Map<String, List<String>> result =
        await Countly.instance.remoteConfig.testingGetAllVariants();
    result.forEach((key, value) {
      resultString += '\n$key:\n';
      value.forEach((item) {
        resultString += '- $item\n';
      });
    });
    addToListView(resultString, 'Stored Variants');
  }

  void remoteConfigRegisterDownloadCallback() {
    Countly.instance.remoteConfig.registerDownloadCallback(
        (rResult, error, fullValueUpdate, downloadedValues) {
      if (rResult == RequestResult.success) {
        String resultString = '';
        showCustomToast(context, 'Downloaded values', Colors.green);
        downloadedValues.forEach((key, RCData) {
          resultString += '\nKey: [$key],';
          resultString +=
              ' Value: [${RCData.value}] (${RCData.value.runtimeType}),';
          resultString += ' isCurrentUSer: [${RCData.isCurrentUsersData}]';
        });
        addToListView(resultString, 'Downloaded Values');
      } else {
        showCustomToast(context, 'Download failed', Colors.red);
      }
    });
  }

  Future<void> remoteConfigGetAllValues([String? expectedKey]) async {
    final allValues = await Countly.instance.remoteConfig.getAllValues();
    String resultString = '';
    allValues.forEach((key, RCData) {
      if (key == expectedKey) {
        setState(() {
          _key = key;
          _value = RCData.value.toString();
          _isNew = RCData.isCurrentUsersData.toString();
        });
      }
      resultString += '\nKey: [$key],';
      resultString +=
          ' Value: [${RCData.value}] (${RCData.value.runtimeType}),';
      resultString += ' isCurrentUSer: [${RCData.isCurrentUsersData}]';
    });
    addToListView(resultString, 'Stored Values');
  }

  void showCustomToast(BuildContext context, String message, Color? color) {
    final snackBar = SnackBar(
      content: Container(
        height: 60,
        child: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      duration: Duration(seconds: 3),
      backgroundColor: color ?? Colors.green,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void addToListView(String downloadedValues, String message) {
    setState(() {
      Random random = Random();
      Color newColor = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1.0,
      );
      _backgroundColor = newColor;
      if (downloadedValues.isEmpty) {
        downloadedValues = 'No values found';
      }
      DateTime now = DateTime.now();
      String currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      String newText = '$counter) $currentTime - $message: $downloadedValues';

      textList.add(newText);
      counter++;
    });
    // Scroll to the bottom of the list.
    _textScrollController.animateTo(
      //   _textScrollController.position.maxScrollExtent,
      1000,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: Text(
            "Var: " +
                _variant +
                " , Key: " +
                _key +
                " , Val: " +
                _value +
                ", isNew: " +
                _isNew,
            style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: ListView.builder(
              controller: _textScrollController,
              itemCount: textList.length,
              itemBuilder: (context, index) {
                String text = textList[index];
                int prefixLength = text.indexOf('s:');
                String prefixText = text.substring(0, prefixLength + 2);
                String downloadedValues = text.substring(prefixLength + 2);

                return ListTile(
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: prefixText,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: downloadedValues,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              padding: EdgeInsets.all(10),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: changeIDmerge,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  child: Text(
                    'Change ID (merge)',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: changeID,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  child: Text('Change ID', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: downloadAllKeys,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.deepOrange),
                  ),
                  child: Text('Download all keys', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: remoteConfigGetAllValues,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.deepOrange),
                  ),
                  child: Text('Get all keys', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: remoteConfigEnrollIntoABTestsForKeys,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.amber),
                  ),
                  child: Text('Enroll into $expToEnrollExit',
                      textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: remoteConfigExitABTestsForKeys,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.amber),
                  ),
                  child: Text('Exit $expToEnrollExit',
                      textAlign: TextAlign.center),
                ),
                ElevatedButton(
                    onPressed: remoteConfigDownloadAllVariant,
                    child: Text('Download all variants',
                        textAlign: TextAlign.center)),
                ElevatedButton(
                    onPressed: testingEnrollIntoVariantA,
                    child: Text('Enroll into Variant C',
                        textAlign: TextAlign.center)),
                ElevatedButton(
                    onPressed: testingEnrollIntoVariantB,
                    child: Text('Enroll into Variant B',
                        textAlign: TextAlign.center)),
                ElevatedButton(
                    onPressed: testingGetAllVariants,
                    child:
                        Text('Get all variants', textAlign: TextAlign.center)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
