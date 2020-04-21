//
//  KeiserM3iParser.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 20/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

import Foundation

public class KeiserM3iDataParser: NSObject {
//    public var name = ""
//    public var address = ""
    public var versionMayor: Int?
    public var versionMinor: Int?
    public var dataType: Int?
    public var equipmentID: Int = 0
    public var cadence: Int?
    public var heartRate: Int?
    public var power: Int?
    public var caloricBurn: Int?
    public var duration: TimeInterval?
    public var tripDistance: Double?
    public var gear: Int?
    
    public var interval: Int?
    public var realTime = false
    
    
    // parseamos los datos recibidos via broadcast
    // eliminamos los dos primeros bytes "prefix bits"
    public init(manufactureData: Data) {
        var data = manufactureData
        if (data.count > 17){
            data = data.subdata(in: Range(uncheckedBounds: (lower: 2, upper: data.count)))
        }

        var tempDistance: Int32?  // this value can be in kilometers or in miles

        for (index, byte) in data.enumerated(){
            switch index {
            case 0: versionMayor = Int(byte)
            case 1: versionMinor = Int(byte)
            case 2: dataType = Int(byte)
            case 3: equipmentID = Int(byte)
            case 4: cadence = Int(byte)
            case 5: cadence = Int(UInt16(byte) << 8 | UInt16(cadence!))
            case 6: heartRate = Int(byte)
            case 7: heartRate = Int(UInt16(byte) << 8 | UInt16(heartRate!))
            case 8: power = Int(byte)
            case 9: power = Int(UInt16(byte) << 8 | UInt16(power!))
            case 10: caloricBurn = Int(byte)
            case 11: caloricBurn = Int(UInt16(byte) << 8 | UInt16(caloricBurn!))
            case 12: duration = Double(byte) * 60
            case 13: duration = duration! + Double(byte)
            case 14: tempDistance = Int32(byte)
            case 15: tempDistance = Int32(UInt16(byte) << 8 | UInt16(tempDistance!))
            case 16: gear = Int(byte)
            default: break
                
            }
        }

        cadence = cadence!/10       // cadence has one decimal
        heartRate = heartRate!/10   // heart rate has one decimal

        super.init()

        // dataType parser. Get values for internal and realTime
        // The data type integer contains information regarding the interval and whether data transmitted is real time (real time mode) or review values (review mode).
        // A data type value of 0, or 128 to 227 indicates that the data being received is real time.
        // A data type value of 255, or 1 to 99 indicates the data being received are review values.

        // The data type values 0 and 255 correspond to the main interval values (both real time and review accordingly).
        // The data type values 1 to 99 correspond to the review values for intervals 1 to 99.
        // The data type values 128 to 227 correspond to the real time values for 1 to 99 offset by 127.
        
        if (dataType! == 0 || dataType! == 255) {
            interval = 0
        }
        else if (dataType! > 0 && dataType! < 128) {
            interval = dataType!
        }
        else if (dataType! > 128 && dataType! < 255) {
            interval = dataType! - 128
        }

        realTime = dataType! == 0 || (dataType! > 128 && dataType! < 255)
        
        // Converts tripDistance to miles depending on the miles/kilometer bit.
        // bit 16 = 1 for kilometers and 0 for miles
        if tempDistance! & 32768 != 0 {
            tripDistance = (Double(tempDistance! & 32767) * 0.62137119) / 10.0
        }
        else {
            tripDistance = Double(tempDistance!) / 10.0
        }
    }
    
/*=================================================================
    // Don't know what is this method for

    public var scanResult: String {
        get {
            return "scanResult"
        }
    }
    
    // Don't know what is this method for
     public var isValid: Bool {
        get {
            return name.count > 0 && equipmentID > 0
        }
    }
    
    //============================================================*/
}
