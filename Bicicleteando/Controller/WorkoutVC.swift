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
// iOS SDK versions 5.0 and greater supports Bluetooth Smart. Due to the energy management built into the Core Bluetooth API, running a continuous scan will often result in intermittent reception of data. The best approach for working with iOS is to toggle the scan after the receipt of a packet from the targeted equipment, or on a regular interval when receiving from multiple pieces of equipment.



import UIKit
import CoreBluetooth
import HealthKit

//----------------------------------------------------------------------------
// MARK -- View controller
//----------------------------------------------------------------------------

class WorkoutVC: UIViewController {

    // Outlets
    @IBOutlet weak var cadence: UILabel!
    @IBOutlet weak var heartRate: UILabel!
    @IBOutlet weak var power: UILabel!
    @IBOutlet weak var caloricBurn: UILabel!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var gear: UILabel!
    @IBOutlet weak var connectBtn: UIBarButtonItem!
    
    // Core Bluetooth central manager declaration
    private var centralManager: CBCentralManager!
    
    // bike data
    var bike : Bike?
    
    // workout in on progress (can be paused)
    var workoutOnProgress  = false
    var numberOfWorkoutDataSamples : Double = 0
    var timer = Timer()

    //----------------------------------------------------------------------------
    // View did load
    //----------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get health kit authorization
        HealthKitManager.authorizeHealthKit()
        
        // Init bluetooth central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //----------------------------------------------------------------------------
    // MARK -- getHeartRate method
    //----------------------------------------------------------------------------
    public func getHeartRate(){
        
        guard let heartRateSampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else {
          print("Heart Rate Sample Type is no longer available in HealthKit")
          return
        }
        
        HealthKitManager.getMostRecentSample(for: heartRateSampleType) { (sample, error) in
        
            guard let sample = sample else {
                print("error getting heart rate sample")
                return
            }
       
            self.heartRate.text = String(format:"%02.0f",sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))) + " bpm"
        }
    }
    
    //----------------------------------------------------------------------------
    // MARK -- start/pause and finish buttons action
    //----------------------------------------------------------------------------
    
    @IBAction func connectBtnPressed(_ sender: UIBarButtonItem) {
        // pause button pressed
        if workoutOnProgress {
            connectBtn.title = "Start"
            timer.invalidate()
            
        // start button pressed
        } else {
            connectBtn.title = "Pause"
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(scheduleBLEPeripheralScan), userInfo: nil, repeats: true)
        }
        workoutOnProgress = !workoutOnProgress
    }
    
    // while we are cycling the timer run this function each second.
    // this function scan BLE peripherals
    // the scanning is stopped when a valid sample is found
    @objc func scheduleBLEPeripheralScan()
    {
        // Update workout duration (add one second)
        let duration = String(format:"%02.0f",numberOfWorkoutDataSamples / 60) + ":" + String(format:"%02.0f",numberOfWorkoutDataSamples.truncatingRemainder(dividingBy: 60) )

        durationLbl.text = duration
        numberOfWorkoutDataSamples = numberOfWorkoutDataSamples + 1
        
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    @IBAction func finishBtnPressed(_ sender: Any) {
        //centralManager.stopScan()
    }
}

//----------------------------------------------------------------------------
// MARK -- Central manager delegate
//----------------------------------------------------------------------------

extension WorkoutVC: CBCentralManagerDelegate {
    
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
    //  Read advertisments data from peripheral
    //----------------------------------------------------------------------------
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
        
        // parser manufacturer Data
        let keiserM3iData = KeiserM3iDataParser(manufactureData: manufacturerData as! Data)
        
        //connectBtn.titleLabel?.text = String(keiserM3iData.equipmentID)
        if workoutOnProgress {
                    
            // Update data on screen
            cadence.text = String(keiserM3iData.cadence!) + " rpm"
            power.text = String(keiserM3iData.power!) + " W"
            caloricBurn.text = String(keiserM3iData.caloricBurn!) + " kCal"
            distance.text = String(format:"%.1f",keiserM3iData.tripDistance!) + " Km"
            gear.text = String(keiserM3iData.gear!)
         
            getHeartRate()
        
        }
        
        centralManager.stopScan()
    }
}

    


