//
//  WeatherManager.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import Foundation
import CoreLocation
import UIKit

// Define the WeatherManager class to handle weather data fetching and icon retrieval.
class WeatherService {
    // Singleton instance to allow easy and centralized access to the manager throughout the app.
    static let shared = WeatherService()
    
    // NSCache instance to store and retrieve weather icons efficiently.
    private var imageCache = NSCache<NSString, UIImage>()
    
    // Base URL for the OpenWeatherMap API.
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather?"
    
    // API key to authenticate requests (below API key can be found in website after signup).
    private let apiKey = "32dcb258b4bb508d1fb3baaff59c3f96"
    
    // Property to keep track of the ongoing network task.
    private var currentTask: URLSessionDataTask?
    
    // URLSessionProtocol allows for dependency injection of URL session for easier testing.
    var urlSession: URLSessionProtocol
    
    // Initializer that allows injection of a specific URLSessionProtocol, defaulting to URLSession.shared.
    init(session: URLSessionProtocol = URLSession.shared) {
        self.urlSession = session
    }
       
    // Method to fetch weather data for a specific city.
    func fetchWeather(for city: String, completion: @escaping (Result<ResponseBody, Error>) -> Void) {
        // Cancel any ongoing request before starting a new one.
        currentTask?.cancel()
        
        // Construct the query URL with city and API key.
        let query = "q=\(city)&appid=\(apiKey)&units=metric"
        
        // Add percent encoding to the query string to handle spaces and other special characters.
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: baseURL + encodedQuery) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        // Start the data task to fetch weather data.
        currentTask = urlSession.dataTask(with: url) { [weak self] data, response, error in
            // Ensure `self` is still available, if not, exit early
            guard self != nil else { return }
            
            // Check for network errors
            if let error = error {
                // If the error is due to cancellation, don't handle it as an actual error.
                if (error as NSError).code != NSURLErrorCancelled {
                    completion(.failure(error))
                }
                return
            }
            
            // Verify the response status code
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: nil)))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Status code is 200 OK, proceed to decode the data
                guard let data = data else {
                    completion(.failure(NSError(domain: "No Data", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                    let weatherData = try JSONDecoder().decode(ResponseBody.self, from: data)
                    completion(.success(weatherData))
                } catch {
                    completion(.failure(error))
                }
                
            case 400...499:
                // Handle client-side errors (e.g., 400 Bad Request, 404 Not Found)
                let errorMessage = "Client error with status code: \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                
            case 500...599:
                // Handle server-side errors (e.g., 500 Internal Server Error)
                let errorMessage = "Server error with status code: \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                
            default:
                // Handle other unexpected status codes
                let errorMessage = "Unexpected status code: \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
            }
        }
        
        currentTask?.resume()
    }
        
    
    // Method to fetch and cache weather icons.
    func fetchIcon(with iconName: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache for an existing image.
        if let cachedImage = imageCache.object(forKey: NSString(string: iconName)) {
            completion(cachedImage)
            return
        }
        
        // URL for the weather icon.
        let iconURL = "https://openweathermap.org/img/wn/\(iconName)@2x.png"
        guard let url = URL(string: iconURL) else {
            completion(nil)
            return
        }
        
        // Fetch the icon from the internet.
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            // Store the fetched image in cache.
            self.imageCache.setObject(image, forKey: NSString(string: iconName))
            // Return the fetched image.
            completion(image)
        }.resume()
    }
}

