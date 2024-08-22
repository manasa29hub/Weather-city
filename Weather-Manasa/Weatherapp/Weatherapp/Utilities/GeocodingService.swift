//
//  GeocodingService.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import Foundation


// A class to handle geocoding tasks.
class GeocodingService {
    // API key to authenticate requests. Replace the string with your actual OpenWeatherMap API key.
    let apiKey = "32dcb258b4bb508d1fb3baaff59c3f96"
    // Shared URL session for making HTTP requests.
    let session = URLSession.shared

    // Retrieves the geographical coordinates (latitude and longitude) for a given city name.
    func getCoordinates(forCity city: String, completion: @escaping (Coordinate?) -> Void) {
        // Construct the URL for geocoding the city name.
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(city)&limit=1&appid=\(apiKey)"
        // Ensure the URL is properly encoded and valid.
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(nil)  // Call completion with nil if URL is not valid.
            return
        }

        // Start a data task with the URL.
        session.dataTask(with: url) { data, response, error in
            // Ensure there is no error and data is received.
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            // Attempt to decode the JSON response into an array of GeocodingData.
            if let json = try? JSONDecoder().decode([GeocodingData].self, from: data), let firstResult = json.first {
                // If successful, extract the first result and use it to create a Coordinate instance.
                let coordinate = Coordinate(lat: firstResult.lat, lon: firstResult.lon)
                completion(coordinate)  // Pass the coordinate to the completion handler.
            } else {
                completion(nil)  // If decoding fails, pass nil.
            }
        }.resume()  // Resume the task; necessary to start the network call.
    }

    // Retrieves city information from geographic coordinates.
    func getCity(fromCoordinates coordinates: Coordinate, completion: @escaping (CityInfo?) -> Void) {
        // Construct the URL for reverse geocoding.
        let urlString = "https://api.openweathermap.org/geo/1.0/reverse?lat=\(coordinates.lat)&lon=\(coordinates.lon)&limit=1&appid=\(apiKey)"
        // Ensure the URL is valid.
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Start a data task with the URL.
        session.dataTask(with: url) { data, response, error in
            // Ensure there is no error and data is received.
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            // Attempt to decode the JSON response into an array of GeocodingData.
            if let json = try? JSONDecoder().decode([GeocodingData].self, from: data), let firstResult = json.first {
                // If successful, extract the first result and use it to create a CityInfo instance.
                let cityInfo = CityInfo(name: firstResult.name, state: firstResult.state, country: firstResult.country)
                completion(cityInfo)  // Pass the city information to the completion handler.
            } else {
                completion(nil)  // If decoding fails, pass nil.
            }
        }.resume()  // Resume the task; necessary to start the network call.
    }
}

