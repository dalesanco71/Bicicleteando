//
//  KeiserM3iParser.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 20/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

import Foundation

public class WorkoutSampleData: NSObject {

    
    public var equipmentID: Int = 01
    public var cadence: Int?
    public var heartRate: Int?
    public var power: Int?
    public var caloricBurn: Int?
    public var timeInSeconds: Int?
    public var tripDistance: Double?
    public var gear: Int?
        
    // parser data received via broadcast
    // removes 5 fisrt bytes "Company ID, Version and DataType"
    public init(manufactureData: Data) {
        var data = manufactureData
        if (data.count > 17){
            data = data.subdata(in: Range(uncheckedBounds: (lower: 5, upper: data.count)))
        }

        var tempDistance: Int32?  // this value can be in kilometers or in miles

        for (index, byte) in data.enumerated(){
            switch index {
            
            case 0: equipmentID = Int(byte)
            case 1: cadence = Int(byte)
            case 2: cadence = Int(UInt16(byte) << 8 | UInt16(cadence!))
            case 3: heartRate = Int(byte)
            case 4: heartRate = Int(UInt16(byte) << 8 | UInt16(heartRate!))
            case 5: power = Int(byte)
            case 6: power = Int(UInt16(byte) << 8 | UInt16(power!))
            case 7: caloricBurn = Int(byte)
            case 8: caloricBurn = Int(UInt16(byte) << 8 | UInt16(caloricBurn!))
            case 9: timeInSeconds = Int(byte) * 60
            case 10: timeInSeconds = timeInSeconds! + Int(byte)
            case 11: tempDistance = Int32(byte)
            case 12: tempDistance = Int32(UInt16(byte) << 8 | UInt16(tempDistance!))
            case 13: gear = Int(byte)
            default: break
                
            }
        }

        cadence = cadence!/10       // cadence has one decimal
        heartRate = heartRate!/10   // heart rate has one decimal

        
        // Converts tripDistance to miles depending on the miles/kilometer bit.
        // bit 16 = 1 for kilometers and 0 for miles
        if tempDistance! & 32768 != 0 {
            tripDistance = (Double(tempDistance! & 32767) * 0.62137119) / 10.0
        }
        else {
            tripDistance = Double(tempDistance!) / 10.0
        }
    }
    
}
