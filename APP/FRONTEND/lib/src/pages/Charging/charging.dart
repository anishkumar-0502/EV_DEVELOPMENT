import 'dart:convert';
import 'package:flutter/material.dart';
import '../home.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import './Settings/stop_charger.dart';
import '../../utilities/Alert/alert_banner.dart';

String formatTimestamp(DateTime originalTimestamp) {
  return DateFormat('MM/dd/yyyy, hh:mm:ss a').format(originalTimestamp.toLocal());
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.2, // Adjust this to change the overall height of the divider
      child: CustomPaint(
        painter: GradientPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.75), // Darker black shade
          Color.fromRGBO(0, 128, 0, 0.75), // Darker green for blending
          Colors.green, // Green color in the middle
        ],
        end: Alignment.center,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.0)
      ..quadraticBezierTo(size.width / 3, 0, size.width, size.height * 0.99)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Charging extends StatefulWidget {
  final String username; // Make the username parameter nullable
  final String searchChargerID;
  final int? connector_id;
  final int? userId;
  final int? connector_type;
  final String email;
    final Map<String, dynamic>? selectedLocation; // Accept the selected location



  const Charging({
    Key? key,
    required this.searchChargerID,
    required this.username,
    required this.connector_id,
    required this.userId,
    required this.connector_type, required this.email, this.selectedLocation,
  }) : super(key: key);

  @override
  State<Charging> createState() => _ChargingPageState();
}

class _ChargingPageState extends State<Charging> with SingleTickerProviderStateMixin {
  String activeTab = 'home';
  late WebSocketChannel channel;
  late AnimationController _controller;
  bool showMeterValuesContainer = false; // Declare this in your state class

  String chargerStatus = '';
  String TagIDStatus = '';
  bool NoResponseFromCharger = false;
  String timestamp = '';
  String chargerCapacity = '';
  bool isTimeoutRunning = false;
  bool isStarted = false;
  bool checkFault = false;
  bool isErrorVisible = false;
  bool isThresholdVisible = false;
  bool isBatteryScreenVisible = false;
  bool showVoltageCurrentContainer = false;
  bool showAlertLoading = false;
  List<Map<String, dynamic>> history = [];
  String voltage = '';
  String current = '';
  String power = '';
  String energy = '';
  String frequency = '';
  String temperature = '';



  // State for voltage and current of three phases
  String voltageV1 = '';
  String voltageV2 = '';
  String voltageV3 = '';
  String currentA1 = '';
  String currentA2 = '';
  String currentA3 = '';
  String powerActiveL1 = '';
  String powerActiveL2 = '';
  String powerActiveL3 = '';

  late double _currentTemperature;

  final ScrollController _scrollController = ScrollController();
  bool isStartButtonEnabled = true; // Initial state
  bool isStopButtonEnabled = false;
  bool charging = false;
  String chargerID = '';
  String username = '';
  String errorCode = '';

  void seterrorCode(String errorCode) {
    setState(() {
      this.errorCode = errorCode;
    });
  }

bool _isStopLoading = false;
  bool showSuccessAlert = false;
  bool showErrorAlert = false;
  bool showAlert = false;
  Map<String, dynamic> chargingSession = {};
  Map<String, dynamic> updatedUser = {};

  void setApiData(Map<String, dynamic> chargerSession, Map<String, dynamic> userValue) {
    setState(() {
      chargingSession = chargerSession;
      updatedUser = userValue;
      showAlert = true;
    });
  }

Widget _buildLoadingIndicator() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.black.withOpacity(0.7), // Transparent black background
    child: const Center(
      child: Icon(
        Icons.bolt, // Use a charging icon like 'bolt' or 'electric_car'
        color: Colors.yellow, // Set the icon color
        size: 300, // Adjust the size as needed
      ),
    ),
  );
}


  void handleCloseAlert() async {
    bool checkFault = false; // Example value, set it based on your logic
    if (!checkFault) {
      Navigator.of(context).pop();
    }
    setState(() {
      showAlert = false;
    });
  }

  void showSuccess() {
    setState(() {
      showSuccessAlert = true;
    });
  }

  void closeSuccess() {
    setState(() {
      showSuccessAlert = false;
    });
  }

  void showError() {
    setState(() {
      showErrorAlert = true;
    });
  }

  void closeError() {
    setState(() {
      showErrorAlert = false;
    });
  }

  void handleLoadingStart() {
    setState(() {
      showAlertLoading = true;
    });
  }

  void handleLoadingStop() {
    setState(() {
      showAlertLoading = false;
    });
  }

  void setIsStarted(bool value) {
    setState(() {
      isStarted = value;
    });
  }

  void setCheckFault(bool value) {
    setState(() {
      checkFault = value;
    });
  }

  void startTimeout() {
    setState(() {
      isTimeoutRunning = true;
    });
  }

  void stopTimeout() {
    setState(() {
      isTimeoutRunning = false;
    });
  }

  bool isLoading = false; // Track loading state

  void handleAlertLoadingStart(BuildContext context) {
    setState(() {
      showAlertLoading = true;
    });
  }

  void showNoResponseAlert() {
  setState(() {
    NoResponseFromCharger = true;
  });

  // Automatically hide the alert after 3 seconds
  Timer(const Duration(seconds: 3), () {
    setState(() {
      NoResponseFromCharger = false;
    });
  });
}

  Future<void> endChargingSession(String chargerID, int? connectorId) async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/endChargingSession'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'charger_id': chargerID, 'connector_id': connectorId}),
      );

        final data = jsonDecode(response.body);
        print("endChargingSession $data");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Charging session ended: $data');
      } else {
        print('Failed to end charging session. Status code: ${response.statusCode}');
      }
      dispose();
    } catch (error) {
      print('Error ending charging session: $error');
    }
  }

  Future<void> updateSessionPriceToUser(int? connectorId) async {
    try {
      handleAlertLoadingStart(context);

    // Introduce a 3-second delay before sending the request
    await Future.delayed(const Duration(seconds: 4));

      var url = Uri.parse('http://122.166.210.142:4444/charging/getUpdatedCharingDetails');
      var body = {
        'chargerID': chargerID,
        'user': username,
        "connectorId": connectorId,
      };
      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await http.post(url, headers: headers, body: jsonEncode(body));


      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        showAlertLoading = false;
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var chargingSession = data['value']['chargingSession'];
        var updatedUser = data['value']['user'];

        print('Charging Session: $chargingSession');
        print('Updated User: $updatedUser');

        Future<void> handleCloseButton() async {
          handleLoadingStop();  // Stop loading when the button is clicked
          if (chargerStatus == "Faulted" || chargerStatus == 'Unavailable') {
            Navigator.pop(context);
          } else {
            await endChargingSession(chargerID, widget.connector_id);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(username: username,userId: widget.userId, email: widget.email,),
              ),
            );
          }
        }

        Future<void> showCustomAlertDialog(BuildContext context, Map<String, dynamic> chargingSession, Map<String, dynamic> updatedUser) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return ChargingCompleteModal(
                chargingSession: chargingSession,
                updatedUser: updatedUser,
                onClose: () {
                  // Your close button logic here
                  handleCloseButton();
                },
              );
            },
          );
        }

        showCustomAlertDialog(context, chargingSession, updatedUser);
      } else {
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text('Error'),
        //     content: const Text('Updation unsuccessful!'),
        //     actions: [
        //       TextButton(
        //         onPressed: () => Navigator.pop(context),
        //         child: const Text('OK'),
        //       ),
        //     ],
        //   ),
        // );
        const AlertBanner(
          message:'Updation unsuccessful!' ,
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      setState(() {
        showAlertLoading = false;
      });

      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: const Text('Error'),
      //     content: Text('Failed to update charging details: $error'),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.pop(context),
      //         child: const Text('OK'),
      //       ),
      //     ],
      //   ),
      // );
      const AlertBanner(
        message:'Failed to update charging details' ,
        backgroundColor: Colors.red,
      );

      print('Error updating charging details: $error');
    }
  }

  void handleAlertLoadingStop() {
    setState(() {
      showAlertLoading = false;
    });
  }

  void setVoltage(String value) {
    setState(() {
      voltage = value;
    });
  }

  void setCurrent(String value) {
    setState(() {
      current = value;
    });
  }

  void setPower(String value) {
    setState(() {
      power = value;
    });
  }

  void setEnergy(String value) {
    setState(() {
      energy = value;
    });
  }

  void setFrequency(String value) {
    setState(() {
      frequency = value;
    });
  }

  void setTemperature(String value) {
    setState(() {
      temperature = value;
    });
  }

  void setHistory(Map<String, dynamic> entry) {
    setState(() {
      history.add(entry);
    });
    print("entry $entry");
  }

  void setChargerStatus(String value) {
    setState(() {
      chargerStatus = value;
    });
  }

  void setchargerCapacity(String value){
    setState(() {
      chargerCapacity = value;
    });
  }

  void setTimestamp(String currentTime) {
    setState(() {
      timestamp = currentTime;
    });
  }

  void appendStatusTime(String status, String currentTime) {
    setState(() {
      chargerStatus = status;
      timestamp = currentTime;
    });
  }

  String getCurrentTime() {
    DateTime currentDate = DateTime.now();
    String currentTime = currentDate.toIso8601String();
    return formatTimestamp(currentTime as DateTime);
  }

  Map<String, dynamic> convertToFormattedJson(List<dynamic> measurandArray) {
    Map<String, dynamic> formattedJson = {};
    for (var measurandObj in measurandArray) {
      String key = measurandObj['measurand'];
      dynamic value = measurandObj['value'];
      formattedJson[key] = value;
    }
    return formattedJson;
  }

  Future<void> fetchLastStatus(String chargerID, int? connectorId) async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/FetchLaststatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': chargerID, 'connector_id': connectorId, 'connector_type': widget.connector_type}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("data $responseData");

        // Access the 'data' field
        final data = responseData['data'];

        // Extract necessary fields from 'data'
        final status = data['charger_status'];
        final timestamp = data['timestamp'];

        // Extract UnitPrice and ChargerCapacity
        final unitPrice = responseData['UnitPrice'];
        final chargerCapacity = responseData['ChargerCapacity'];
        print('ChargerCapacity: $chargerCapacity');
        // setState((value) {
        //   chargerCapacity = value(),
        // });

        // Format the timestamp
        final formattedTimestamp = formatTimestamp(DateTime.parse(timestamp));

        // Process the status
        if (status == 'Available' || status == 'Unavailable') {
          startTimeout();
        } else if (status == 'Charging') {
          setIsStarted(true);
          setState(() {
            charging = true;
          });
          if(showMeterValuesContainer){
          toggleBatteryScreen();
          }
        }

        appendStatusTime(status, formattedTimestamp);

        // Optionally, you can use unitPrice and chargerCapacity here
        print('UnitPrice: $unitPrice');
        setchargerCapacity(chargerCapacity.toString());

      } else {
        print('Failed to fetch status. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error while fetching status: $error');
    }
  }


void RcdMsg(Map<String, dynamic> parsedMessage) async {
  final String chargerID = widget.searchChargerID;

  if (parsedMessage['DeviceID'] != chargerID) return;

  final List<dynamic> message = parsedMessage['message'];

  if (message.length < 4 || message[3] == null) return;
if (message[2] == 'MeterValues') {
  final meterValues = message[3]['meterValue'] ?? [];
  
  // Reset all values initially
  voltageV1 = '';
  voltageV2 = '';
  voltageV3 = '';
  currentA1 = '';
  currentA2 = '';
  currentA3 = '';
  powerActiveL1 = '';
  powerActiveL2 = '';
  powerActiveL3 = '';
  temperature = '';
  frequency = '';

  if (meterValues.isNotEmpty && !isBatteryScreenVisible) {
    for (var meterValue in meterValues) {
      final sampledValues = meterValue['sampledValue'] ?? [];

      for (var value in sampledValues) {
        final measurand = value['measurand'] ?? '';
        final phase = value['phase'] ?? '';
        final unit = value['unit'] ?? '';
        final val = value['value'] ?? '';

        switch (measurand) {
          case 'Voltage':
            if (phase == 'L1') voltageV1 = '$val $unit';
            if (phase == 'L2') voltageV2 = '$val $unit';
            if (phase == 'L3') voltageV3 = '$val $unit';
            break;
          case 'Current.Import':
            if (phase == 'L1') currentA1 = '$val $unit';
            if (phase == 'L2') currentA2 = '$val $unit';
            if (phase == 'L3') currentA3 = '$val $unit';
            break;
          case 'Power.Active.Import':
            if (phase == 'L1') powerActiveL1 = '$val $unit';
            if (phase == 'L2') powerActiveL2 = '$val $unit';
            if (phase == 'L3') powerActiveL3 = '$val $unit';
            break;
          case 'Temperature':
            temperature = '$val $unit';
            break;
          case 'Frequency':
            frequency = '$val Hz';
            break;
          default:
            // Handle additional measurands if needed
            break;
        }
      }
    }
    
    // Determine whether to show meter values container
    setState(() {
      showMeterValuesContainer = voltageV1.isNotEmpty || currentA1.isNotEmpty;
      showVoltageCurrentContainer = showMeterValuesContainer;
    });
  }
}
  String chargerStatus = '';
  String currentTime = '';
  String vendorErrorCode = '';
  int? connectorIds = message[3]['connectorId']; // Extract connectorId
  String msg = message[2]; // Extract msg

  if (parsedMessage['DeviceID'] == chargerID && connectorIds == widget.connector_id && msg.isNotEmpty) {
    print('Received message: $parsedMessage');
    switch (message[2]) {
      case 'StatusNotification':
        vendorErrorCode = message[3]['vendorErrorCode'] ?? '';
        chargerStatus = message[3]['status'] ?? '';
        TagIDStatus = message[3]['TagIDStatus'] ?? '';
        currentTime = formatTimestamp(DateTime.tryParse(message[3]['timestamp'] ?? DateTime.now().toString()) ?? DateTime.now());
        errorCode = message[3]['errorCode'] ?? '';


        if (chargerStatus == 'Preparing') {
          setState(() {
            charging = false;
          });
          toggleBatteryScreen();
          stopTimeout();
          setIsStarted(false);
          isStartButtonEnabled = true;
        } else if (TagIDStatus == 'Invalid') {
          setState(() {
            TagIDStatus = 'Invalid';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'Blocked') {
          setState(() {
            TagIDStatus = 'Blocked';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'Expired') {
          setState(() {
            TagIDStatus = 'Expired';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'ConcurrentTx') {
          setState(() {
            TagIDStatus = 'ConcurrentTx';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (chargerStatus == 'Available' || chargerStatus == 'Unavailable') {
          setState(() {
            charging = false;
          });
          toggleBatteryScreen();
          startTimeout();
          setIsStarted(false);
        } else if (chargerStatus == 'Charging') {
          setState(() {
            charging = true;
            isLoading = false; // Stop loading when charging starts
          });
          setIsStarted(true);
        } else if (chargerStatus == 'Finishing') {
          setIsStarted(false);
          setState(() {
            charging = false;
            isLoading = false; // Stop loading if it was still running
          });
          handleLoadingStop();
          toggleBatteryScreen();
          await updateSessionPriceToUser(widget.connector_id);
        } else if (chargerStatus == 'Faulted' || chargerStatus ==  'SuspendedEV' ) {
          setIsStarted(false);
          setState(() async {
            charging = false;
            isLoading = false; // Stop loading if it was still running
            toggleBatteryScreen();
            print("checkout: $checkFault");
            if (!checkFault) {
              showErrorDialog(context);
              setCheckFault(true);
            }
          });

               // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () async {
                await updateSessionPriceToUser(widget.connector_id);

          });
          print("checkout: $checkFault");
        } else if (chargerStatus == 'Unavailable') {
          setIsStarted(false);
          setState(() {
            charging = false;
            isLoading = false; // Stop loading if it was still running
            toggleBatteryScreen();
            if (!checkFault) {
              showErrorDialog(context);
            }
          });
        }

        if (errorCode != 'NoError') {
          Map<String, dynamic> entry = {
            'serialNumber': history.length + 1,
            'currentTime': currentTime,
            'chargerStatus': chargerStatus,
            'errorCode': errorCode != 'InternalError' ? errorCode : vendorErrorCode,
          };

          setState(() {
            history.add(entry);
            checkFault = true;
          });
        } else {
          setState(() {
            checkFault = false;
          });
        }
        seterrorCode(errorCode);
        break;

      case 'Heartbeat':
        currentTime = formatTimestamp(DateTime.now());
        setState(() {
          timestamp = currentTime;
        });
        print("chargerStatus: $chargerStatus $errorCode");
        break;

      case 'MeterValues':
        if(!showMeterValuesContainer){

          final meterValues = message[3]['meterValue'] ?? [];
          print(meterValues);
          final sampledValue = meterValues.isNotEmpty ? meterValues[0]['sampledValue'] : [];


          Map<String, dynamic> formattedJson = convertToFormattedJson(sampledValue);
          currentTime = formatTimestamp(DateTime.now());

          setState(() {
            // charging = true;
            setChargerStatus('Charging');
            setTimestamp(currentTime);
            setVoltage((formattedJson['Voltage'] ?? '').toString());
            setCurrent((formattedJson['Current.Import'] ?? '').toString());
            setPower((formattedJson['Power.Active.Import'] ?? '').toString());
            setEnergy((formattedJson['Energy.Active.Import.Register'] ?? '').toString());
            setFrequency((formattedJson['Frequency'] ?? '').toString());
            setTemperature((formattedJson['Temperature'] ?? '').toString());
          });

          print('{ "V": ${formattedJson['Voltage']},"A": ${formattedJson['Current.Import']},"W": ${formattedJson['Power.Active.Import']},"Wh": ${formattedJson['Energy.Active.Import.Register']},"Hz": ${formattedJson['Frequency']},"Kelvin": ${formattedJson['Temperature']}}');
      
        }   
        break;

      case 'Authorize':
        print("errorCode: $errorCode");
        chargerStatus = (errorCode == 'NoError' || errorCode.isEmpty) ? 'Authorize' : 'Faulted';
        currentTime = formatTimestamp(DateTime.now());
        break;

      case 'FirmwareStatusNotification':
        chargerStatus = message[3]['status']?.toUpperCase() ?? '';
        currentTime = formatTimestamp(DateTime.now());
        break;

      case 'StopTransaction':
        setIsStarted(false);
        setState(() {
          charging = false;
          //isLoading = false; // Stop loading if it was still running
        });
        currentTime = formatTimestamp(DateTime.now());
        print("StopTransaction");
        break;

      case 'Accepted':
        chargerStatus = 'ChargerAccepted';
        currentTime = formatTimestamp(DateTime.now());
        break;

      default:
        break;
    }
  }

  if (chargerStatus.isNotEmpty) {
    appendStatusTime(chargerStatus, currentTime);
  }
}


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _currentTemperature = double.tryParse(temperature) ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.searchChargerID.isNotEmpty) {
        fetchLastStatus(widget.searchChargerID, widget.connector_id);
      }
    });
    initializeWebSocket();
    chargerID = widget.searchChargerID;
    username = widget.username;
    print('Initialized chargerID: $chargerID');
    print('Initialized username: $username');
  }



  void initializeWebSocket() {
    channel = WebSocketChannel.connect(
      // Uri.parse('ws://122.166.210.142:8566'),
      Uri.parse('ws://122.166.210.142:7002'),
        // Uri.parse('ws://192.168.1.7:7050'),

    );

    channel.stream.listen(
          (message) {
        final parsedMessage = jsonDecode(message);
        if (mounted) {
          RcdMsg(parsedMessage);
        }
      },
      onDone: () async {
        if (mounted) {
          setState(() {
            charging = false;
          });
          setIsStarted(false);
          await endChargingSession(widget.searchChargerID, widget.connector_id
          );
          print('WebSocket connection closed');
        }
      },
      onError: (error) {
        if (mounted) {
          print('WebSocket error: $error');
        }
      },
      cancelOnError: true,
    );
  }

 @override
  void dispose() {
    _controller.dispose();
    channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }
  
  void toggleErrorVisibility() {
    print("isErrorVisible: $isErrorVisible");
    setState(() {
      if (isErrorVisible) {
        isErrorVisible = !isErrorVisible;
        isErrorVisible = false;
      } else {
        isThresholdVisible = false;
        isErrorVisible = !isErrorVisible;
        isErrorVisible = true;
      }
    });
  }

void toggleBatteryScreen() {
  print("Charging toggleBatteryScreen $charging");

  if (charging) {
    setState(() {
      // Show the battery screen and hide the meter values container
      if (!isBatteryScreenVisible) {
        isBatteryScreenVisible = true;
        showMeterValuesContainer = false;
      } else {
        // Show the meter values container and hide the battery screen
        showMeterValuesContainer = true;
        isBatteryScreenVisible = false;
      }
      
      isStartButtonEnabled = !isStartButtonEnabled;
      isStopButtonEnabled = !isStopButtonEnabled;
    });
  } else {
    setState(() {
      // Ensure both are hidden when not charging
      isBatteryScreenVisible = false;
      showMeterValuesContainer = false;
      isStopButtonEnabled = false;
    });
  }
}


  void toggleThresholdVisibility() {
    setState(() {
      if (!isThresholdVisible) {
        isErrorVisible = false;
      }
      isThresholdVisible = !isThresholdVisible;
    });
  }

  // This function starts the transaction and checks for a response
  void handleStartTransaction() async {
    String chargerID = widget.searchChargerID;
    final int? connectorId = widget.connector_id;

    try {
      setState(() {
      isLoading = true;
      NoResponseFromCharger = false;  // Reset the flag before starting
    });

    // Start a timer that will automatically stop loading after 10 seconds if no status is received
    Timer(const Duration(seconds: 10), () {
      if (isLoading) { // If still loading after 10 seconds
        setState(() {
          isLoading = false;  // Stop loading
          NoResponseFromCharger = true;  // Set the flag to show the alert banner
        });

        // Automatically hide the alert after 3 seconds
        Timer(const Duration(seconds: 3), () {
          setState(() {
            NoResponseFromCharger = false;  // Hide the alert
          });
        });
      }
    });

      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/start'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': chargerID,
          'user_id': widget.userId,
          'connector_id': connectorId,
          'connector_type': widget.connector_type,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ChargerStartInitiated');
        print(data['message']);
      } else {
        print('Failed to start charging: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  void startButtonPressed() {
    print("startButtonPressed");
    handleStartTransaction();
  }
void handleStopTransaction() async {
  String chargerID = widget.searchChargerID;
  final int? connectorId = widget.connector_id;
  print("handleStopTransaction");
  try {
    setState(() {
      isLoading = true;
      _isStopLoading = true;
      NoResponseFromCharger = false;  // Reset the flag before starting
    });

    // Start a timer that will automatically stop loading after 10 seconds if no status is received
    Timer(const Duration(seconds: 10), () {
      if (isLoading) {
        setState(() {
          isLoading = false;
          _isStopLoading = false;
        });
        showNoResponseAlert();  // Show the "No response from charger" alert
      }
    });

    final response = await http.post(
      Uri.parse('http://122.166.210.142:4444/charging/stop'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'id': chargerID,
        'connectorId': connectorId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('ChargerStopInitiated');
      print(data['message']);
      // await updateSessionPriceToUser(connectorId);
    } else {
      print('Failed to stop charging: ${response.reasonPhrase}');
    }
  } catch (error) {
    print('Error: $error');
  } finally {
    // setState(() {
    //   isLoading = false;
    //   _isStopLoading = false;
    // });
  }
}

  void stopButtonPressed() {
    print("stopButtonPressed handleStopTransaction");
    handleStopTransaction();
  }

  Color _getTemperatureColor() {
    if (_currentTemperature < 30) {
      return Colors.green;
    } else if (_currentTemperature < 50) {
      return const Color.fromARGB(255, 209, 99, 16);
    } else {
      return Colors.red;
    }
  }
Widget _buildAnimatedTempColorCircle() {
  // Get screen dimensions
  final screenWidth = MediaQuery.of(context).size.width;

  // Adjust based on screen size
  final isSmallScreen = screenWidth < 400;

  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15), // Adjust border radius for small screens
        ),
        child: Container(
          width: isSmallScreen ? 200 : 225, // Adjust width for small screens
          height: isSmallScreen ? 90 : 102, // Adjust height for small screens
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16.0), // Adjust padding for small screens
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15), // Adjust border radius for small screens
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current t°',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    // '${_currentTemperature.toInt()} °C' ,
                    '33.5 °C',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(width: 20), // Add some space between the circle and the text
              Container(
                width: isSmallScreen ? 80 : 90, // Adjust circle size for small screens
                height: isSmallScreen ? 80 : 90, // Adjust circle size for small screens
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _getTemperatureColor().withOpacity(0.6),
                      _getTemperatureColor(),
                      _getTemperatureColor().withOpacity(0.6),
                    ],
                    stops: [0.0, _controller.value, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '33.5 ',
                            style: TextStyle(color: _getTemperatureColor(), fontSize: isSmallScreen ? 12 : 15), // Adjust font size
                          ),
                          Text(
                            '°C',
                            style: TextStyle(color: _getTemperatureColor(), fontSize: isSmallScreen ? 11 : 14), // Adjust font size
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void thresholdlevel() {
  // Set the current based on chargerCapacity
  String overCurrent = chargerCapacity == 3.5
      ? 'Over Current - 17A'
      : 'Over Current - 33A';
  print("chargerCapacity $chargerCapacity");
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.black,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.black,
          height: MediaQuery.of(context).size.height * 0.7, // Adjusted height for better fit
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Static Header with Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'THRESHOLD LEVEL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              CustomGradientDivider(),
              const SizedBox(height: 8),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: double.infinity, // Make container take up full width
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          // Voltage Level
                          _buildInfoCard('Voltage Level:', [
                            'Input under voltage - 175V and below.',
                            'Input over voltage - 270V and below.'
                          ]),

                          // Current (Conditional)
                          _buildInfoCard('Current:', [
                            overCurrent,
                          ]),

                          // Frequency
                          _buildInfoCard('Frequency:', [
                            'Under Frequency - 47HZ',
                            'Over Frequency - 53HZ',
                          ]),

                          // Temperature
                          _buildInfoCard('Temperature:', [
                            'Low Temperature - 0°C.',
                            'High Temperature - 58°C.',
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper method to build each info card
Widget _buildInfoCard(String title, List<String> content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Container(
      width: double.infinity, // Ensure that all cards have the same width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          for (var text in content)
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
              ),
            ),
        ],
      ),
    ),
  );
}




  void showErrorDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, 
          child: ErrorDialog(isErrorVisible: isErrorVisible, history: history));
      },
    );
  }

  void chargerStopSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, 
          child:  StopCharger(userId: widget.userId));
      },
    );
  }

  void navigateToHomePage(BuildContext context, String username) {
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => HomePage(username: username,userId: widget.userId, email: widget.email),
    //   ),
    // );
    Navigator.pop(context);

    endChargingSession(chargerID, widget.connector_id);
  }

  void _scrollToNext() {
    _scrollController.animateTo(
      _scrollController.position.pixels + 800, // Adjust the value as needed
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }
  
  void _scrollToPrevious() {
    _scrollController.animateTo(
      _scrollController.position.pixels - 400, // Adjust the value as needed
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

@override
Widget build(BuildContext context) {
  String? ChargerID = widget.searchChargerID;
  int? connectorId = widget.connector_id;
  int? connectorType = widget.connector_type;
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

  // Adjust based on screen width
  final isSmallScreen = screenWidth < 400;

  String displayText;
  switch (connectorType) {
    case 1:
      displayText = 'Socket';
      break;
    case 2:
      displayText = 'Gun';
      break;
    default:
      displayText = 'Unknown'; // or some default value
      break;
  }

  return WillPopScope(
    onWillPop: () async {
      Navigator.pop(context);
      return false; // Return false to prevent the default back behavior
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        showAlertLoading: showAlertLoading || isLoading, // Combine both loading states
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
Padding(
    padding: EdgeInsets.only(
      top: isSmallScreen ? 30.0 : 40.0,  // Adjust top padding based on screen size
      bottom: isSmallScreen ? 15.0 : 23.0, // Adjust bottom padding
      left: isSmallScreen ? 10.0 : 12.0,  // Adjust left padding
      right: isSmallScreen ? 10.0 : 12.0, // Adjust right padding
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Icon
        GestureDetector(
          onTap: () {
            navigateToHomePage(context, username);
          },
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isSmallScreen ? 25 : 30, // Adjust size based on screen size
            ),
          ),
        ),
        const Spacer(), // Adds space between the settings icons and the back icon
        // Settings Icon
        Padding(
          padding: EdgeInsets.only(top: isSmallScreen ? 5 : 0), // Adjust top padding
          child: IconButton(
            onPressed: chargerStopSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            iconSize: isSmallScreen ? 22 : 24, // Adjust size based on screen size
          ),
        ),
        // Power Icon
        Padding(
          padding: EdgeInsets.only(top: isSmallScreen ? 5 : 0), // Adjust top padding
          child: IconButton(
            onPressed: thresholdlevel,
            icon: const Icon(Icons.power_outlined, color: Colors.green),
            iconSize: isSmallScreen ? 22 : 24, // Adjust size based on screen size
          ),
        ),
        // Info Icon
        Padding(
          padding: EdgeInsets.only(top: isSmallScreen ? 5 : 0), // Adjust top padding
          child: IconButton(
            onPressed: () => showErrorDialog(context),
            icon: const Icon(Icons.info_outline, color: Colors.red),
            iconSize: isSmallScreen ? 22 : 24, // Adjust size based on screen size
          ),
        ),
      ],
    ),
  ),
      Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12.0 : 20.0,  // Adjust padding based on screen size
    ),
    child: Container(
      height: isSmallScreen ? 50 : 65, // Adjust height for smaller screens
      width: screenWidth * 0.9, // Adjust width based on screen size (90% of screen width)
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              const Icon(
                Icons.charging_station,
                color: Colors.green,
                size: 25,
              ),
              const SizedBox(width: 15),
              Text(
                ChargerID,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 20, // Adjust text size for small screens
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Text(
            '||',
            style: TextStyle(
              fontSize: 30,
              color: Colors.white, // Adjust the color for visibility
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.ev_station,
                color: Colors.red,
                size: 25,
              ),
              const SizedBox(width: 15),
              Text(
                displayText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 20, // Adjust text size for small screens
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
              Image.asset(
                        'assets/Image/Car.png',
    height: isSmallScreen ? screenHeight * 0.3 : 300,  // Adjust height based on screen size
                      ),
Padding(
    padding: EdgeInsets.only(left: isSmallScreen ? 8.0 : 13.0, bottom: isSmallScreen ? 10 : 15),
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 18.0),
      child: Row(
        children: [
          // Column for status and timestamp aligned to the left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
            children: [
              Text(
                chargerStatus,
                style: TextStyle(
                  color: chargerStatus == 'Faulted' ? Colors.red : Colors.green,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.white60),
              ),
            ],
          ),
          // Spacer to push the connectorId to the right
          const Spacer(),
          Column(
            children: [
              Row(
                children: [
                  if (connectorId != null)
                    Text(
                      '$connectorId',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  const SizedBox(width: 20),
                  const Icon(Icons.ev_station_outlined, color: Colors.red),
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$chargerCapacity ',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const TextSpan(
                          text: 'kwh',
                          style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  ),
Padding(
    padding: EdgeInsets.only(top: isSmallScreen ? 10 : 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (chargerStatus == 'Preparing')
          StartButton(
            chargerStatus: chargerStatus,
            isStartButtonEnabled: isStartButtonEnabled,
            onPressed: startButtonPressed,
          )
        else if (chargerStatus == 'Available' || chargerStatus == 'Finishing' || chargerStatus == 'Faulted' || chargerStatus == "SuspendedEV")
          const DisableButton()
        else if (chargerStatus == 'Charging')
          StopButton(
            isStopButtonEnabled: true,
            isStopLoading: _isStopLoading, // Pass the loading state here
            onPressed: stopButtonPressed,
          ),
        const SizedBox(width: 6),
        _buildAnimatedTempColorCircle(),
      ],
    ),
  ),               if (!showMeterValuesContainer && charging)
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15, left: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            energy.isNotEmpty ? energy : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Energy',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                current.isNotEmpty ? current : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltage.isNotEmpty ? voltage : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToNext,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 35.0),
                                          child: Container(
                                            width: 280,
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, right: 0),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: 300, // Reduced width
                                                  height: 87, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            frequency.isNotEmpty ? frequency : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Frequency',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 300, // Reduced width
                                                  height: 87, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            power.isNotEmpty ? power : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Power',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToPrevious,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (showMeterValuesContainer) // Check if the meter values container should be shown
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15, left: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            currentA1.isNotEmpty ? currentA1 : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Current 1',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                currentA2.isNotEmpty ? currentA2 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current 2',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                currentA3.isNotEmpty ? currentA3 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current 3',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToNext,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            voltageV1.isNotEmpty ? voltageV1 : '0',                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Voltage 1',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltageV2.isNotEmpty ? voltageV2: '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage 2',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltageV3.isNotEmpty ? voltageV3 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage 3',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToPrevious,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            energy.isNotEmpty ? energy : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Energy',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                frequency.isNotEmpty ? frequency : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Frequency',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                power.isNotEmpty ? power : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Power',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (TagIDStatus == 'Invalid')
              const AlertBanner(
                message: 'Invalid NFC Card',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'blocked')
              const AlertBanner(
                message: 'Your account is blocked',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'expired')
              const AlertBanner(
                message: 'Your NFC Card has expired',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'Concurrent')
              const AlertBanner(
                message: 'Concurrent transaction in progress',
                backgroundColor: Colors.red,
              ),
              if (NoResponseFromCharger)
                const AlertBanner(
                message:'No response from the charger. Please try again!' ,
                backgroundColor: Colors.red,
              ),
          ],
        ),
      ),
    ),
  );
}

}

class BatteryChargeScreen extends StatefulWidget {
  @override
  _BatteryChargeScreenState createState() => _BatteryChargeScreenState();
}

class _BatteryChargeScreenState extends State<BatteryChargeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _animation = Tween<double>(begin: 0, end: 100).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: BatteryPainter(_animation.value),
        child: const SizedBox(
          width: 200,
          height: 70,
        ),
      ),
    );
  }
}

class BatteryPainter extends CustomPainter {
  final double chargeLevel;

  BatteryPainter(this.chargeLevel);

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerRadius = 3.0;
    const double tipWidth = 20.0;
    final double batteryWidth = size.width - tipWidth - 2 * cornerRadius;

    final double chargeWidth = batteryWidth * (chargeLevel / 100);
    final Paint dotPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    const double dotRadius = 10.0;
    const double dotSpacing = 29.0;
    double center = size.width / 2;
    double currentX = center;
    double maxDistance = chargeWidth / 2;

    while (currentX > center - maxDistance) {
      canvas.drawCircle(Offset(currentX, size.height / 2), dotRadius, dotPaint);
      currentX -= dotSpacing;
    }

    currentX = center + dotSpacing;

    while (currentX < center + maxDistance) {
      canvas.drawCircle(Offset(currentX, size.height / 2), dotRadius, dotPaint);
      currentX += dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class StartButton extends StatefulWidget {
  final String chargerStatus;
  final bool isStartButtonEnabled;
  final VoidCallback? onPressed;

  const StartButton({
    required this.chargerStatus,
    required this.isStartButtonEnabled,
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _PowerButtonWidgetState createState() => _PowerButtonWidgetState();
}


class _PowerButtonWidgetState extends State<StartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.green.shade700,
      end: Colors.lightGreen,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  // Get screen dimensions
  final screenWidth = MediaQuery.of(context).size.width;

  // Adjust based on screen size
  final isSmallScreen = screenWidth < 400;

  return Card(
    elevation: 5,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15), // Adjust border radius for small screens
    ),
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20.0), // Adjust padding for small screens
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: isSmallScreen ? 60 : 70, // Adjust size for small screens
        height: isSmallScreen ? 60 : 70, // Adjust size for small screens
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Colors.green, _colorAnimation.value!, Colors.lightGreen],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 32),
              onPressed: widget.chargerStatus == 'Preparing' && widget.isStartButtonEnabled ? widget.onPressed : null,
            ),
          ),
        ),
      ),
    ),
  );
}

}
class StopButton extends StatefulWidget {
  final bool isStopButtonEnabled;
  final bool isStopLoading; // New parameter for loading state
  final VoidCallback? onPressed;

  const StopButton({
    required this.isStopButtonEnabled,
    required this.isStopLoading, // Pass the loading state
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _StopButtonWidgetState createState() => _StopButtonWidgetState();
}

class _StopButtonWidgetState extends State<StopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.orange,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  // Get screen dimensions
  final screenWidth = MediaQuery.of(context).size.width;

  // Adjust based on screen size
  final isSmallScreen = screenWidth < 400;

  return Card(
    elevation: 5,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15), // Adjust border radius for small screens
    ),
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20.0), // Adjust padding for small screens
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: isSmallScreen ? 60 : 70, // Adjust size for small screens
        height: isSmallScreen ? 60 : 70, // Adjust size for small screens
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Colors.red, _colorAnimation.value!, Colors.redAccent],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.stop, color: Colors.white, size: 32),
              onPressed: widget.isStopButtonEnabled ? widget.onPressed : null,
            ),
          ),
        ),
      ),
    ),
  );
}

}


class DisableButton extends StatefulWidget {

  const DisableButton({
    Key? key,
  }) : super(key: key);

  @override
  _DisableButtonWidgetState createState() => _DisableButtonWidgetState();
}

class _DisableButtonWidgetState extends State<DisableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.black,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  // Get screen dimensions
  final screenWidth = MediaQuery.of(context).size.width;

  // Adjust based on screen size
  final isSmallScreen = screenWidth < 400;

  return Card(
    elevation: 5,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15), // Adjust border radius for small screens
    ),
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20.0), // Adjust padding for small screens
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: isSmallScreen ? 60 : 70, // Adjust width for small screens
        height: isSmallScreen ? 60 : 70, // Adjust height for small screens
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Colors.grey, _colorAnimation.value!, Colors.white10],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.power_off, color: Colors.white, size: 32),
              onPressed: () {
                // Add your onPressed functionality here
              },
            ),
          ),
        ),
      ),
    ),
  );
}
    }
    
class ErrorDialog extends StatelessWidget {
  final bool isErrorVisible;
  final List<Map<String, dynamic>> history;
  
  const ErrorDialog({
    Key? key,
    required this.isErrorVisible,
    required this.history,
  }) : super(key: key);
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Error History', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      automaticallyImplyLeading: false, // Hides the default back arrow
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            CustomGradientDivider(),
            const SizedBox(height: 25),
            history.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: const Center(
                      child: Text(
                        'History not found.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true, // This ensures the ListView takes only the required space
                          itemCount: history.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> transaction = history[index];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction['chargerStatus'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              (() {
                                                final timeString = transaction['currentTime'];
                                                if (timeString != null && timeString.isNotEmpty) {
                                                  return timeString;
                                                }
                                                return 'N/A';
                                              })(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        transaction['errorCode'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index != history.length - 1)  CustomGradientDivider(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}
}

class ChargingCompleteModal extends StatelessWidget {
  final Map<String, dynamic> chargingSession;
  final Map<String, dynamic> updatedUser;
  final VoidCallback onClose;

  const ChargingCompleteModal({
    super.key,
    required this.chargingSession,
    required this.updatedUser,
    required this.onClose,
  });

  String _getConnectorTypeName(int? connectorType) {
    switch (connectorType) {
      case 1:
        return 'Socket';
      case 2:
        return 'Gun';

      default:
        return 'Unknown';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency, // This ensures that Material features like elevation work
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView( // Prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Charging Complete',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomGradientDivider(),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.ev_station, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Charger ID',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  '${chargingSession['charger_id']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.numbers, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Connector Id',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  '${chargingSession['connector_id']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.numbers, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Connector Type',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                  subtitle: Text(
                    _getConnectorTypeName(chargingSession['connector_type']),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.access_time, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Start Time',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  chargingSession['start_time'] != null
                      ? formatTimestamp(chargingSession['start_time'])
                      : "N/A",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.stop, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Stop Time',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  chargingSession['stop_time'] != null
                      ? formatTimestamp(chargingSession['stop_time'])
                      : "N/A",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.electric_car, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Units Consumed',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  '${chargingSession['unit_consummed']} Kwh',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Text(
                    '\u20B9', // Indian Rupee symbol
                    style: TextStyle(color: Colors.white, fontSize: 24), // Customize size as needed
                  ),
                ),
                title: const Text(
                  'Charging Price',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  'Rs. ${chargingSession['price']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Available Balance',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  '${updatedUser['wallet_bal']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(timestamp).toLocal());
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool showAlertLoading;
  final Widget child;

  LoadingOverlay({required this.showAlertLoading, required this.child});

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // color: Colors.black.withOpacity(0.75), // Transparent black background
      color: Colors.black.withOpacity(0.90), // Transparent black background
      child: Center(
        child: _AnimatedChargingIcon(), // Use the animated charging icon
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // The main content
        if (showAlertLoading)
          _buildLoadingIndicator(), // Use the animated loading indicator
      ],
    );
  }
}

class _AnimatedChargingIcon extends StatefulWidget {
  @override
  __AnimatedChargingIconState createState() => __AnimatedChargingIconState();
}

class __AnimatedChargingIconState extends State<_AnimatedChargingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward(); // Start the animation

    // Slide animation for moving the bolt icon vertically downwards
    _slideAnimation = Tween<double>(begin: -130.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Opacity animation for smooth fading in and out
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the animation to start from the top when it reaches the bottom
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value), // Move vertically
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.bolt_sharp, // Charging icon
        color: Colors.green, // Set the icon color
        size: 200, // Adjust the size as needed
      ),
    );
  }
}
