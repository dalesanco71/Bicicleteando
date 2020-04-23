//
//  HealthKit.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 22/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.


import Foundation
import HealthKit


class HealthKitManager: NSObject {

    static let healthKitStore = HKHealthStore()
    
    //------------------------------------------------------------------------------------
    //  This method requires authorization to access Hart Rate data of the Health Kit
    //------------------------------------------------------------------------------------
    static func authorizeHealthKit() {

        //1. Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health kit notAvailable On Device")
            return
        }
    
        // Define the healthKit data we want to access (Heart Rate) and requires authorization
        let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
    
        healthKitStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    
    //------------------------------------------------------------------------------------
    //  This method get the most recent sample of the Heart Rate data
    //------------------------------------------------------------------------------------
    
    static func getMostRecentSample(for sampleType: HKSampleType, completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
      
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                          end: Date(),
                                                          options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                          ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                    predicate: mostRecentPredicate,
                                    limit: limit,
                                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        
        //2. Always dispatch to the main thread when complete.
        DispatchQueue.main.async {
            
          guard let samples = samples,
                let mostRecentSample = samples.first as? HKQuantitySample else {
                    
                completion(nil, error)
                return
          }
            
          completion(mostRecentSample, nil)
        }
      }
     
    HKHealthStore().execute(sampleQuery)
    }

}

