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


  Widget commandButton(void Function() command, IconData icon) {
    return InkWell(
      onTap: command,
      
      child: Container(
        color: Colors.deepOrange[900],
        height: 50,
        width: 150,
        child: Center(
          child: Icon(
            icon,
            color: Colors.blueGrey,
          ),
        )
      ),
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
                      commandButton(bleController.toggleLed, Icons.lightbulb),
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
                          color: Colors.deepOrange[900],
                          height: 40,
                          width: 225,
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