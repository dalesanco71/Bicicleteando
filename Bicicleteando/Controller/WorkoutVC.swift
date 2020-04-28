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
import Charts

// Global constant
let numberOfSamplesToShow = 300 // five minutes in seconds

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
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    // Core Bluetooth central manager declaration
    private var centralManager: CBCentralManager!
    
    // bike data
    var bike : Bike?
    
    // workout on progress (can be paused)
    var workoutOnProgress  = false
    var numberOfWorkoutDataSamples : Int = 0
    var timer = Timer()

    //workout data
    var workoutData = [WorkoutSampleData]()
    var powerData = Array(repeating: 0.0, count: numberOfSamplesToShow)

    //----------------------------------------------------------------------------
    // View did load
    //----------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // draw first chart. Timer will update chart every 1 second
        setChart()
        
        // get health kit authorization
        HealthKitManager.authorizeHealthKit()
        
        // Init bluetooth central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //----------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "workoutToStadisticsSegue",
           let vc = segue.destination as? WorkoutStadisticsVC {
              vc.workoutData = workoutData
        }
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
       
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            
            self.heartRate.text = String(format:"%02.0f",heartRate) + " bpm"
            
            self.workoutData.last?.heartRate = Int(heartRate)
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
    
    @IBAction func stadisticsBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "workoutToStadisticsSegue", sender: AnyObject?.self)

    }

    // while we are cycling the timer run this function each second.
    // this function scan BLE peripherals
    // the scanning is stopped when a valid sample is found
    @objc func scheduleBLEPeripheralScan()
    {
        // update line data chart
        setChart()

        // Update workout duration (add one second for each workout sample)
        let workoutMinutes = numberOfWorkoutDataSamples / 60
        let workoutSeconds = numberOfWorkoutDataSamples - (workoutMinutes*60)
        let duration = String(format:"%02d",workoutMinutes) + ":" + String(format:"%02d",workoutSeconds)
        durationLbl.text = duration
        workoutData.last?.timeInSeconds = numberOfWorkoutDataSamples
        numberOfWorkoutDataSamples = numberOfWorkoutDataSamples + 1
        
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    //----------------------------------------------------------------------------
     // MARK -- draw line chart
     //----------------------------------------------------------------------------
    
    @objc func setChart() {
        if let lastwWorkoutData = workoutData.last {
            powerData.append(Double(lastwWorkoutData.power!))

        }
        var dataEntries: [BarChartDataEntry] = []

        for i in 0..<numberOfSamplesToShow-1 {
            let dataEntry1 = BarChartDataEntry(x: Double(i), y: powerData[powerData.count - numberOfSamplesToShow + i])
            dataEntries.append(dataEntry1)

        }
                
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "Power")
        chartDataSet.colors = [UIColor.red]
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.lineWidth = 2.0
        chartDataSet.fillColor = UIColor.orange
        chartDataSet.drawFilledEnabled = true
        chartDataSet.drawValuesEnabled = false

        
        // Draw line limit
        let ftpLine = ChartLimitLine(limit: 10.0, label: "FTP")
        lineChartView.rightAxis.addLimitLine(ftpLine)
        
        // Show data on screen
        let chartData = LineChartData(dataSet: chartDataSet)
        lineChartView.data = chartData
        lineChartView.xAxis.enabled = false
        lineChartView.rightAxis.enabled = false
    }
    
    @IBAction func finishBtnPressed(_ sender: Any) {
        print(workoutData.count)
        print(workoutData)
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
                //print("central.state is .poweredOn")
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
        let sampleData = WorkoutSampleData(manufactureData: manufacturerData as! Data)
        
        //connectBtn.titleLabel?.text = String(keiserM3iData.equipmentID)
        if workoutOnProgress {
                    
            // Update data on screen
            cadence.text = String(sampleData.cadence!) + " rpm"
            power.text = String(sampleData.power!) + " W"
            caloricBurn.text = String(sampleData.caloricBurn!) + " kCal"
            distance.text = String(format:"%.1f",sampleData.tripDistance!) + " Km"
            gear.text = String(sampleData.gear!)
         
            getHeartRate()
        
        }
        
        centralManager.stopScan()
        
        workoutData.append(sampleData)
    }
}

    


