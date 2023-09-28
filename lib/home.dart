/*
Applicazione di controllo di un ESP32 tramite protocollo Bluetooth Low Energy (BLE)
Dev: Phoenix
*/

//librerie flutter
import 'package:ble_home_control/ble_logic.dart';
import 'package:ble_home_control/connection_status.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


final BLEController bleController = BLEController();
ValueNotifier<BLEConnectionStatus> connectionStatus = ValueNotifier<BLEConnectionStatus>(BLEConnectionStatus.unknown);
ValueNotifier<double> desiredLightLevel = ValueNotifier<double>(125.0);
const double buttonWidth = 270;


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    bleController.scanAndConnectionStream().listen((event) { 
      connectionStatus.value = event;
      
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    //code to execute at dispose
    bleController.disconnectDevice();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  /*
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        //put here code to execute when resuming the use of the app
        bleController.scanAndConnectToDevice()
          .whenComplete(() {
            connectionStatus.value = bleController.getStatus();
          });
        break;
      case AppLifecycleState.paused:
        //put here code to execute when putting the app in the background
        bleController.disconnectDevice();
        break;
      default:
        break;
    }
  }
  */

  BoxDecoration buttonDecoration() {
    return BoxDecoration(
          color: Colors.deepOrange[900],
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(5, 5), // changes position of shadow
            ),
          ],
        );
  }


  Widget commandButton(void Function() command, IconData icon) {
    return InkWell(
      onTap: command,
      
      child: Container(
        decoration: buttonDecoration(),
        height: 100,
        width: buttonWidth,
        child: Center(
          child: Icon(
            icon,
            color: Colors.deepPurple,
          ),
        )
      ),
    );
  }


  Widget lightManualSlider(ValueNotifier<double> desiredLightValue, void Function(int) func) {
    return ValueListenableBuilder(
      valueListenable: desiredLightValue,
      builder: (BuildContext context, double value, Widget? child) {
        return Container(
          decoration: buttonDecoration(),
          height: 100,
          width: buttonWidth,
          child: Center(
            child: Slider(
              activeColor: Colors.deepPurple,
              thumbColor: Colors.deepPurple,
              value: desiredLightValue.value,
              max: 255.0,
              divisions: 255,
              label: desiredLightValue.value.round().toString(),
              onChanged: (double value) {
                desiredLightValue.value = value;
              },
              onChangeEnd: (double value) {
                desiredLightValue.value = value;
                func(value.round());
              },
            )
          )
        );
      },
    );
    
  }


  Widget appBody(ValueNotifier<BLEConnectionStatus> connectionStatus) {
    return ValueListenableBuilder(
          valueListenable: connectionStatus,
          builder: (BuildContext context, BLEConnectionStatus value, Widget? child) {
            switch(connectionStatus.value) {
              case BLEConnectionStatus.connected:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      commandButton(bleController.powerOnLed, Icons.lightbulb),
                      const SizedBox(height: 20),
                      commandButton(bleController.powerOffLed, Icons.lightbulb_outline),
                      const SizedBox(height: 20),
                      lightManualSlider(desiredLightLevel, bleController.manualLedValue),
                      const SizedBox(height: 20),
                      commandButton(bleController.disconnectDevice, Icons.bluetooth_disabled),
                    ],
                  ),
                );
              case BLEConnectionStatus.scanfail:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        color: Colors.blueGrey,
                        size: 200,
                      ),
                      InkWell(
                        onTap: (){
                          connectionStatus.value = BLEConnectionStatus.scanning;
                          bleController.scanAndConnectionStream().listen((event) { 
                            connectionStatus.value = event;
                          });
                        },
                        child: Container(
                          decoration: buttonDecoration(),
                          height: 50,
                          width: buttonWidth,
                          child: const Center(
                            child: Text(
                              "Connection failed, tap to retry",
                              textAlign: TextAlign.center,
                              style: TextStyle(                     
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "Roboto",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              case BLEConnectionStatus.connecting:
                return Center(
                  child: LoadingAnimationWidget.halfTriangleDot(
                    color: Colors.deepOrange,
                    size: 200,
                  ),
                );
              default:
                return Center(
                  child: LoadingAnimationWidget.dotsTriangle(
                    color: Colors.deepOrange,
                    size: 200,
                  ),
                );
            }
          },
    );
    
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: Colors.blueGrey[800],
      appBar: AppBar( 
        backgroundColor: Colors.deepOrange[900],
        title: const Text(
          "Phoenix Home Control",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: "Roboto",
          ),
        ),
      ),
      body: appBody(connectionStatus), 

      
		);
  }


}