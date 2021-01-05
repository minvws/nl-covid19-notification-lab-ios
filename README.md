# Apple Exposure Notification 'Lab Test' implementation

## Disclaimer
This repository contains a bare bones, technical implementation of the Google/Apple Exposure Notification protocol. It is intended to validate the technical underpinnings of the protocol and to conduct experiments and tests to test the accuracy of the protocol and/or the Bluetooth Low Energy readings.

It is NOT intended for end users and does NOT implement any security or privacy measures. In fact, to be able to analyze the protocol, the apps may exchange TEK keys at will. TEKs in this app have no relationship to COVID testing.

Although we always welcome contributions in the project, note that we consider this app a 'disposable' and it will not be actively maintained. (A separate repository will be published with the actual proof of concept app for the Dutch exposure notification implementation).

Keep in mind that the Apple Exposure Notification API is only accessible by verified health
authorities. Other devices trying to access the API using the code in this repository will fail
to do so.

## How to use the app

### Performing a testscenario with the app
1. Install the app on 2 devices
2. Make sure your exposure logs are empty by going to Settings >> Exposure Notifications >> State  and removing the exposure log file
3. Make sure bluetooth is enabled on both devices
4. Open the app
5. Fill in a test scenario ID in both phones
6. Take the 2 devices to a location where you want to test the range and functionality of the EN framework (for instance with a certain distance between the devices)
7. Enable the exposure notification framework with the toggle in the app and keep the devices in place
9. Turn the EN framework off on both devices with the toggle in the app

### Extracting testresults from the app
1. Make sure the EN framework is turned off on both devices
2. Choose "Share TEK" on the device that should act as the "Affected user", follow the instructions and make sure you end up with a QR code being shown on the screen
3. On the other devices, scan the QR Code
4. The device will now indicate wether there were detected exposures to the affected user's device
5. You can export the testresult data with the share button within the app



## Impression of experiment
![Performing an experiment on a field using two phones](lab-test.jpg)
