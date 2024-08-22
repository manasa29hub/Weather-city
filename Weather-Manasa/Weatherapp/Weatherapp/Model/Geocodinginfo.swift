//
//  Coordinate.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import Foundation

// Codable structure to parse the JSON data from the API.
struct GeocodingData: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}

// Define a simple structure to hold latitude and longitude.
struct Coordinate {
    let lat: Double
    let lon: Double
}

// Define a structure to hold basic city information.
struct CityInfo {
    let name: String
    let state: String?
    let country: String
}
