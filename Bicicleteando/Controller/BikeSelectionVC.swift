//
//  bikeConnectionVC.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 22/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

// -------------------------------------------------------------------------------
//
//  This controller scan for Keiser M3 bikes and show the results in a table
//  When the user selects a bike from this table goes to the workout view
//
// -------------------------------------------------------------------------------

import UIKit
import CoreBluetooth

class BikeSelectionVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    // Core Bluetooth central manager declaration
    private var centralManager: CBCentralManager!
    
    private var bikes: [Bike] = []
    
    private var selectedBike = 0
    
    private var firstBLEData = true // fisrt BLE Data has wrong data (equipmentID is wrong)
    
    //----------------------------------------------------------------------------
    //  View Did Load
    //----------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: nil)
        tableView.dataSource = self
        tableView.delegate   = self
        
        
    }
    
    //----------------------------------------------------------------------------
    // View Did Appear
    // Some elements as the alert window needs to be called after the view is appeared
    //----------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        let alert = UIAlertController(title: "Select Bike", message: "Start cycling to detect the bike", preferredStyle: .alert)

        self.present(alert, animated: true)
    }
    
    //----------------------------------------------------------------------------
    //  Prepare for segue shares selected bike property
    //----------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
      if segue.identifier == "bikeSelectedSegue",
         let vc = segue.destination as? WorkoutVC {
            vc.bike = bikes[selectedBike]
      }
    }
}

//----------------------------------------------------------------------------
// MARK -- table data source methods
//----------------------------------------------------------------------------
extension BikeSelectionVC: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bikes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bikeTableViewCell", for: indexPath) as! BikeTVC
        cell.bikeUserID.text = bikes[indexPath.row].bikeUserID

        // dismiss the alert window once we hace detected one bike (table with more than 0 cells)
        self.dismiss(animated: true, completion: nil)

        return cell
    }
}

//----------------------------------------------------------------------------
// MARK -- table delegate methods
//----------------------------------------------------------------------------

extension BikeSelectionVC: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Stop scanning new bikes once we have selected our bike
        centralManager.stopScan()

        // goes to the Workout view
        selectedBike =  indexPath.row
        performSegue(withIdentifier: "bikeSelectedSegue", sender: AnyObject?.self)
    }
}

//----------------------------------------------------------------------------
// MARK -- Central manager delegate
//----------------------------------------------------------------------------

extension BikeSelectionVC: CBCentralManagerDelegate {
    
    //----------------------------------------------------------------------------
    // Scan for BLE peripherals when central manager is poweredOn
    //----------------------------------------------------------------------------
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
    
    //----------------------------------------------------------------------------
    //  Scan bluetooth peripheral
    //  Read name, userID and bikeID and update bikes table
    //----------------------------------------------------------------------------
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // We only care about the M3 peripherals (Keiser M3 bikes)
        let bikeName = peripheral.name
        
        if(bikeName != "M3") {
            return
        }
        
        // We only care about advertisment data with DataManufacturerData
        if advertisementData[CBAdvertisementDataManufacturerDataKey] == nil {
            print("Advertisement Data does not contain Manufacturer Data.")
            return
        }
        
        // first BLE message is wrong. EquipmentID is not correctly setted
        if firstBLEData {
            firstBLEData = false
            return
        }
        
        // now that we know that there is a manufacturerData we read it
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey]!
        
        // parser manufacturer Data
        let keiserM3iData = WorkoutSampleData(manufactureData: manufacturerData as! Data)
        
        let bikeUserID = String(keiserM3iData.equipmentID)
        let bikeUUID   = peripheral.identifier
    
        // append new bike to table only if the UUID is not already on the table (new bike) and
        // if BLE data is not the first one (first BLE data is wrong)
        if !bikes.contains(where: { $0.bikeUserID == bikeUserID }) {
            //print("bike " + bikeUserID + " already on table ")
            bikes.append(Bike(bikeUserID: bikeUserID, bikeName: bikeName!, bikeUUID: bikeUUID))
            tableView.reloadData()
        }
        
    }
}

    
