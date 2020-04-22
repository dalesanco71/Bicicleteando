//
//  HealthKit.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 22/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitManager: NSObject {

  static let healthKitStore = HKHealthStore()

  static func authorizeHealthKit() {

    //1. Check to see if HealthKit Is Available on this device
    guard HKHealthStore.isHealthDataAvailable() else {
      print("Health kit notAvailable On Device")
      return
    }
    
    // 
    let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!    ]
    
    healthKitStore.requestAuthorization(toShare: healthKitTypes,
                                        read: healthKitTypes) { _, _ in }
  }
}

