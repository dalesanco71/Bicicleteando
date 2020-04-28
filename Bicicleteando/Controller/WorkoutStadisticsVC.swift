//
//  WorkoutStadisticsControllerVC.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 28/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

import UIKit

class WorkoutStadisticsVC: UIViewController {

    @IBOutlet weak var cadenceMediaLbl: UILabel!
    @IBOutlet weak var hearRateMediaLbl: UILabel!
    @IBOutlet weak var powerMediaLbl: UILabel!
    @IBOutlet weak var caloriesMediaLbl: UILabel!
    @IBOutlet weak var totalDistanceLbl: UILabel!
    @IBOutlet weak var workoutTimeLbl: UILabel!
    
    //workout data
     var workoutData = [WorkoutSampleData]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // calculate cadenceMedia
        var cadenceMedia = 0
        for  i in 0...workoutData.count - 1 {
            cadenceMedia = cadenceMedia + workoutData[i].cadence!
        }
        cadenceMedia = cadenceMedia / workoutData.count
        cadenceMediaLbl.text = String(cadenceMedia) + " rpm"
        
        // calculate hearRateMedia
        var hearRateMedia = 0
        for  i in 0...workoutData.count - 1 {
            hearRateMedia = hearRateMedia + workoutData[i].heartRate!
        }
        hearRateMedia = hearRateMedia / workoutData.count
        hearRateMediaLbl.text = String(hearRateMedia)
           
        // calculate powerMedia
        var powerMedia = 0
        for  i in 0...workoutData.count - 1 {
            powerMedia = powerMedia + workoutData[i].power!
        }
        powerMedia = powerMedia / workoutData.count
        powerMediaLbl.text = String(powerMedia) + " W"
         
        // calculate caloriesMedia
        var totalCalories = 0
        totalCalories  =    workoutData.last?.caloricBurn! as! Int
        caloriesMediaLbl.text = String(totalCalories) + " kCal"
         
        // calculate totalDistance
        let totalDistance = workoutData.last?.tripDistance!
        totalDistanceLbl.text = String(format:"%.1f",totalDistance as! CVarArg) + " Km"
        
        
        // Update workout duration (add one second for each workout sample)
        let workoutDuration = workoutData.last!.timeInSeconds
        let workoutMinutes = workoutDuration! / 60
        let workoutSeconds = workoutDuration! - (workoutMinutes*60)
        let duration = String(format:"%02d",workoutMinutes) + ":" + String(format:"%02d",workoutSeconds)
        
        workoutTimeLbl.text  = duration

    }
    

    
}
