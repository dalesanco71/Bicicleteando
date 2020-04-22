//
//  bikeConnectionVC.swift
//  Bicicleteando
//
//  Created by Daniel Alesanco on 22/04/2020.
//  Copyright © 2020 Daniel Alesanco. All rights reserved.
//

import UIKit

class BikeConnectionVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var bikes: [Bike] = [
        Bike(bikeUserID: "200", bikeName: "M3"),
        Bike(bikeUserID: "55",  bikeName: "M3")]
    
    var selectedBike = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
      if segue.identifier == "bikeSelectedSegue",
         let vc = segue.destination as? ViewController {
            vc.bike = bikes[selectedBike]
      }
    }
}

//----------------------------------------------------------------------------
// MARK -- table data source methods
//----------------------------------------------------------------------------

extension BikeConnectionVC: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bikes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bikeTableViewCell", for: indexPath) as! BikeTVC
   
        cell.bikeUserID.text = bikes[indexPath.row].bikeUserID
    
        return cell
    }
}

//----------------------------------------------------------------------------
// MARK -- table delegate methods
//----------------------------------------------------------------------------

extension BikeConnectionVC: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedBike =  indexPath.row
        performSegue(withIdentifier: "bikeSelectedSegue", sender: AnyObject?.self)
    }
    
}

