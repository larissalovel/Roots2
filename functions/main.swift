//
//  main.swift
//  test
//
//  Created by checkoutuser on 2/8/20.
//  Copyright © 2020 checkoutuser. All rights reserved.
//

import Foundation

func calculate_gas(fuel_economy: Double, mileage: Double) -> Double{
    return mileage / fuel_economy
}

print(((calculate_gas(fuel_economy: 25, mileage: 60) * 19.4 * (100/95))*10).rounded()/10, "lbs of C02")

print(((calculate_gas(fuel_economy: 25, mileage: 60)*3.5)*10).rounded()/10, "dollars for gass")

