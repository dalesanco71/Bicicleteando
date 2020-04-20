//
//  ViewController.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 20/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//


// Note 1: Keiser M3i bluetooth communication mode
// The transmission from the equipment is a non-connectable advertisement packet
 
// Note 2: Keiser M3i transmission period
// The advertisement packet is transmmited every 318.75 miliseconds

// Note3: communication between Keiser M3i and IOS
//iOS SDK versions 5.0 and greater supports Bluetooth Smart. Due to the energy management built into the Core Bluetooth API, running a continuous scan will often result in intermittent reception of data. The best approach for working with iOS is to toggle the scan after the receipt of a packet from the targeted equipment, or on a regular interval when receiving from multiple pieces of equipment.



import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    // Outlets
    @IBOutlet weak var bikeId: UILabel!
    @IBOutlet weak var cadence: UILabel!
    @IBOutlet weak var heartRate: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var caloricBurn: UILabel!
    @IBOutlet weak var durationMinutes: UILabel!
    @IBOutlet weak var durationSeconds: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var gear: UILabel!
    
    // Properties
    private var m3iPeripheral:  CBPeripheral!
    private var centralManager: CBCentralManager!
    
    // bike struct
    var bikeName: String?
    var bikeRSSI : Int = 0
    var bikePeripheral: CBPeripheral?
    var bikeUUID : UUID?
    
    // 
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Init bluetooth central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
              case .unknown:
                print("central.state is .unknown")
              case .resetting:
                print("central.state is .resetting")
              case .unsupported:
                print("central.state is .unsupported")
              case .unauthorized:
                print("central.state is .unauthorized")
              case .poweredOff:
                print("central.state is .poweredOff")
              case .poweredOn:
                print("central.state is .poweredOn")

                centralManager.scanForPeripherals(withServices: nil)
        @unknown default:
            print("central.state is fatal error")
        }

    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // We only care about the M3 peripherals
        if(peripheral.name != "M3") {
            return
        }
        
        // We only care about advertisment data with DataManufacturerData
        if advertisementData[CBAdvertisementDataManufacturerDataKey] == nil {
            print("Advertisement Data does not contain Manufacturer Data.")
            return
        }
        
        // now that we know that there is a manufacturerData we read it
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey]!
        
        let keiserM3iDataBroadcast = KeiserM3iDataBroadcast(manufactureData: manufacturerData as! Data)
        
        bikeId.text = String(keiserM3iDataBroadcast.ordinalId)
        cadence.text = String(keiserM3iDataBroadcast.cadence!)
        heartRate.text = String(keiserM3iDataBroadcast.heartRate!)
        power.text = String(keiserM3iDataBroadcast.power!)
        caloricBurn.text = String(keiserM3iDataBroadcast.caloricBurn!)
        durationMinutes.text = String(keiserM3iDataBroadcast.duration!)
        durationSeconds.text = String(keiserM3iDataBroadcast.duration!)
        distance.text = String(keiserM3iDataBroadcast.tripDistance!)
        gear.text = String(keiserM3iDataBroadcast.gear!)
       
        
        bikeRSSI = RSSI.intValue
        bikeName = peripheral.name
        bikePeripheral = peripheral
        bikeUUID = peripheral.identifier
        

            print("=============================")
            print(manufacturerData)
    }
}

    


