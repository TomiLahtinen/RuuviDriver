# iOS SceneKit + RuuviTag Demo
Demo app that connects to a RuuviTag running Espruino and provided custom code flashed to it

## Requirements
- iOS Device
- RuuviTag
- Xcode
- CocoaPods

## Installation - iOS
- Clone this repo
- run `pod install`
- open workspace
- Change variable beaconUID `let beaconUID = "AA...123"` to your RuuviTag's UID 
- Compile and run project on device
- As a little bonus there's and AudioKit oscillator. To enable it, uncomment line that initializes oscillator. Oscillator changes frequency and amplitude values according to pitch and roll.

## Installation - RuuviTag
- [Flash RuuviTag with Espruino](https://www.espruino.com/Ruuvitag) firmware (v. 1.99 or later)
- Head over to [Espruino Web IDE](https://www.espruino.com/ide/)
- Connect to RuuviTag
- Paste contents of `HighresAccelerationBLE.js` file into editor screen
- Send to Espruino
- type `save()` and hit enter to left-hand side console to flash the software
- Disconnect

Once these steps are done, iOS software _should_ find the RuuviTag and start rotating pitch and roll directions. First you'll see couple of seconds of latency in motion, but by pressing RuuviTag's button labeled 'B' you can turn on higres mode, green LED also lights up to indicate mode change. Please note that Espruino + highres mode drastically reduce battery life of RuuviTag.