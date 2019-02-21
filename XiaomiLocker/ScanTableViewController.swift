//
//  ScanTableViewController.swift
//  XiaomiLocker
//
//  Created by Oscar Blanco on 13/02/2019.
//  Copyright © 2019 Oscar Blanco. All rights reserved.
//

import UIKit
import CoreBluetooth
import AudioToolbox.AudioServices

struct ScooterContainer: Hashable {
    let scooter: CBPeripheral
    let lastRSSI: NSNumber
    let isConnectable: Bool
    
    var hashValue: Int { return scooter.hashValue }

    static func == (lhs: ScooterContainer, rhs: ScooterContainer) -> Bool {
        return lhs.scooter == rhs.scooter
    }
}

class ScanTableViewController: UITableViewController {
    
//  CONSTANTS
    private let characteristicWrite = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    
//  APP
    @IBOutlet weak var payloadBarButton: UIBarButtonItem!
    @IBOutlet weak var scanBarButton: UIBarButtonItem!
    @IBOutlet weak var cleanBarButton: UIBarButtonItem!
    @IBOutlet weak var statusBarButton: UIBarButtonItem!
    
    private var centralManager: CBCentralManager!
    private var scooters = Set<ScooterContainer>()
    private var selectedScooter: ScooterContainer?
    private var selectedPayload = "Lock"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        payloadBarButton.title = "Payload: \(selectedPayload)"
        scanBarButton.title = "Scan"
        cleanBarButton.title = "Clean"
        statusBarButton.title = "Disconnected"
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scooters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scooterCell", for: indexPath)
        
        let scooterContainer = Array(scooters)[indexPath.row]
        
        cell.textLabel?.text = scooterContainer.scooter.name
        cell.detailTextLabel?.text = "\(scooterContainer.lastRSSI)dB - Connectable: \(scooterContainer.isConnectable)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedScooter = Array(scooters)[indexPath.row]
        statusBarButton.title = "Connecting..."
        centralManager.connect((selectedScooter?.scooter)!, options: nil)
    }

    private func startScanning() {
        self.title = "Scanning..."
        self.scanBarButton.title = "Stop"
        
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    private func stopScanning() {
        self.title = "\(scooters.count) Devices Found"
        self.scanBarButton.title = "Scan"
        
        centralManager?.stopScan()
    }
    
    private func clean() {
        stopScanning()
        
        scooters.removeAll()
        tableView.reloadData()

        if (selectedScooter != nil) {
            centralManager.cancelPeripheralConnection((selectedScooter?.scooter)!)
            selectedScooter = nil
        }
        
        self.title = "\(scooters.count) Devices Found"
    }
    
    private func setPayload(alert: UIAlertAction!) {
        selectedPayload = alert.title!
        self.payloadBarButton.title = "Payload: \(selectedPayload)"
    }
    
    @IBAction func scanBarButtonAction(_ sender: Any) {
        if centralManager.isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @IBAction func payloadBarButtonAction(_ sender: Any) {
        let alert = UIAlertController(title: "Payload", message: "", preferredStyle: .alert)
        
        for (name, _) in payloads {
             alert.addAction(UIAlertAction(title: name, style: .default, handler: setPayload))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cleanBarButtonAction(_ sender: Any) {
        clean()
    }

    @IBAction func doRefresh(_ sender: UIRefreshControl) {
        sender.beginRefreshing()
        if centralManager.isScanning {
            centralManager?.stopScan()
        }
        sender.attributedTitle = NSAttributedString(string: "Scanning...")
        startScanning()
        sender.endRefreshing()
    }
}

extension ScanTableViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        if (central.state == .poweredOn){
            scanBarButton.isEnabled = true
            startScanning()
        }else{
            self.title = "Bluetooth Disabled"
            scanBarButton.isEnabled = false
            scooters.removeAll()
            tableView.reloadData()
            
            let alert = UIAlertController(title: "Bluetooth Unavailable", message: "Please turn bluetooth on", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
        var isScooter = false
        if let name = peripheral.name {
            isScooter = name.contains("MIScooter")
        }
        
        if isScooter {
            let scooterContainer = ScooterContainer(scooter: peripheral, lastRSSI: RSSI, isConnectable: isConnectable)
            
            if !scooters.contains(scooterContainer) {
                scooters.insert(scooterContainer)
                tableView.reloadData()
                UIDevice.vibrate()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusBarButton.title = "Connected"
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusBarButton.title = "Disconnected"
        selectedScooter = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let alert = UIAlertController(title: "Could not connect", message: self.selectedScooter?.scooter.name, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var msg = "Everything is OK"
        
        if error != nil {
            msg = error!.localizedDescription
        }
        
        let alert = UIAlertController(title: "Payload sent", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}

extension ScanTableViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicWrite {
                // Send payload
                peripheral.writeValue(payloads[selectedPayload]!, for: characteristic, type: .withoutResponse)
                
                // Notification
                let alert = UIAlertController(title: "Characteristic found", message: "Payload sent", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                break
            }
        }
    }
}

extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
