//
//  GameViewController.swift
//  RuuviDriver
//
//  Created by Tomi Lahtinen on 21/05/2018.
//  Copyright © 2018 Tomi Lahtinen. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreBluetooth
import SwiftBytes

class RuuviTagViewController: UIViewController, CBCentralManagerDelegate {
    
    let beaconUID = "AD35924D-7F82-4AFE-35B0-84B472502345"
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var tagNode: SCNNode!
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var pollTimer: Timer!
    var oscillator: Oscillator?
    var xCharacteristic: CBCharacteristic?
    var yCharacteristic: CBCharacteristic?
    var zCharacteristic: CBCharacteristic?
    
    let dataKey = "kCBAdvDataManufacturerData"
    
    let xUID = "ABCD"
    let yUID = "BCDE"
    let zUID = "CDEF"
    
    
    var xValue: Double? {
        didSet {
            updateAngles()
            oscillator?.set(amplitude: xValue!)
        }
    }
    
    var yValue: Double? {
        didSet {
            updateAngles()
            oscillator?.set(frequency: yValue!)
        }
    }
    
    var zValue: Double? {
        didSet {
            updateAngles()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupTag()
        
        xValue = 1
        yValue = 1
        zValue = 1
        
        // If you want some noice. Uncomment next line
        // setupOscillator()
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = UIColor.black
        scnView.scene = scnScene
        
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 8);
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func setupTag() {
        let geometry = SCNCylinder(radius: 1.0, height: 0.4)
        tagNode = SCNNode(geometry: geometry)
        scnScene.rootNode.addChildNode(tagNode)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "logomerkki.png")
        
        let translation = SCNMatrix4MakeScale(1, -1, 1)
        let rotation = SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1)
        let transform = SCNMatrix4Mult(translation, rotation)
        material.diffuse.contentsTransform = transform
        material.diffuse.wrapT = SCNWrapMode.mirror
        let filler = SCNMaterial()
        filler.diffuse.contents = UIColor.white
        tagNode.geometry?.materials = [filler, material]
        tagNode.geometry?.firstMaterial = filler
     
        /*
         tagNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: CGFloat(Double.pi), y: CGFloat(Double.pi / 2), z: CGFloat(Double.pi / 4), duration: 5.0)))
        */
    }
    
    func setupOscillator() {
        oscillator = Oscillator()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        debugPrint("Did update state", central.state.rawValue)
        if(central.state == .poweredOn) {
            debugPrint("Scan for peripherals")
            central.scanForPeripherals(withServices: nil /*serviceUUID.map { CBUUID(string: $0) }*/, options: nil)
            debugPrint("Central scanning", central.isScanning)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.identifier.uuidString == beaconUID {
            debugPrint("My Ruuvi <3")
            if self.peripheral == nil {
                self.peripheral = peripheral
            }
            
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugPrint("Did connect", peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat(Double.pi) / 180
    }
    
    func roundToTens(x : Double) -> Int {
        return 10 * Int(round(x / 10.0))
    }
    
    private func updateAngles() {
        guard let xValue = self.xValue,
              let yValue = self.yValue,
              let zValue = self.zValue else {
                return
        }
        let pitch = atan(xValue / sqrt(pow(yValue, 2) + pow(zValue, 2)))
        let roll = -atan(yValue / sqrt(pow(xValue, 2) + pow(zValue, 2)))
        tagNode.runAction(SCNAction.rotateTo(x: CGFloat(pitch), y: CGFloat(0.0), z: CGFloat(roll), duration: 0.05, usesShortestUnitArc: false))
    }

}

extension RuuviTagViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let _ = error {
            fatalError(error?.localizedDescription ?? "Error :/")
        }
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach { characteristic in
            debugPrint("Map for ", characteristic.uuid.uuidString)
            switch characteristic.uuid.uuidString {
            case xUID:
                self.xCharacteristic = characteristic
            case yUID:
                self.yCharacteristic = characteristic
            case zUID:
                self.zCharacteristic = characteristic
            default:
                debugPrint("Unmapped characteristic", characteristic)
            }
        }
        
        if let _ = xCharacteristic,
           let _ = yCharacteristic,
           let _ = zCharacteristic {
            debugPrint("Start polling")
            pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
               
                peripheral.readValue(for: self.xCharacteristic!)
                peripheral.readValue(for: self.yCharacteristic!)
                peripheral.readValue(for: self.zCharacteristic!)
            }
            pollTimer.fire()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value?.bytes else {
            debugPrint("No can do without data :/")
            return
        }
        if data.count != 2 {
            debugPrint("Wrong data length", data.count)
            return
        }
        
        let value = Double(signed(concatenateBytes(data[0], data[1]))) / 1000
        switch characteristic.uuid.uuidString {
        case xUID:
            xValue = value
        case yUID:
            yValue = value
        case zUID:
            zValue = value
        default:
            debugPrint("No can do either")
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        debugPrint("Did update value for descriptor", descriptor)
    }
}
