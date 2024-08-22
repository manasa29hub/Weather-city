import Foundation
import SwiftUI

// ViewModel responsible for managing the state of the WeatherView.
class WeatherViewModel: ObservableObject {
    
    // Published properties that the view observes for updates.
    @Published var cityName: String = ""          // The name of the city for which to fetch weather data.
    @Published var coordinates: String = ""       // The coordinates of the city, after geocoding.
    @Published var cityInfo: String = ""          // Information about the city, after reverse geocoding.
    @Published var weatherData: ResponseBody?     // The weather data for the specified city.
    @Published var weatherIcon: UIImage?          // The weather icon corresponding to the fetched weather data.
    @Published var errorMessage: String?          // Error message to display in case of a failure.

    // Private properties for the services used by the ViewModel.
    private var geocodingService: GeocodingService   // Service for handling geocoding and reverse geocoding.
    private var weatherService: WeatherService       // Service for handling weather data fetching and icon retrieval.

    // Initializer that accepts optional custom services, defaulting to new instances.
    init(geocodingService: GeocodingService = GeocodingService(),
         weatherService: WeatherService = WeatherService()) {
        self.geocodingService = geocodingService
        self.weatherService = weatherService
        loadLastSearchedCity()  // Load the last searched city from UserDefaults when the ViewModel is initialized.
    }

    // Fetches the weather data for the specified city using the WeatherService.
    func fetchWeather() {
        weatherService.fetchWeather(for: cityName) { [weak self] result in
            // Ensure that UI updates are made on the main thread.
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.weatherData = data              // Store the fetched weather data.
                    self?.weatherIcon = nil               // Clear any previous weather icon.
                    self?.errorMessage = nil              // Clear any previous error message.
                    self?.saveLastSearchedCity()          // Save the current city name to UserDefaults.
                    self?.loadWeatherIcon()               // Load the corresponding weather icon.
                case .failure(let error):
                    self?.weatherData = nil               // Clear any previous weather data.
                    self?.weatherIcon = nil               // Clear any previous weather icon.
                    self?.errorMessage = error.localizedDescription  // Store the error message for UI display.
                }
            }
        }
    }

    // Fetches the weather icon based on the icon name in the weather data.
    func loadWeatherIcon() {
        guard let iconName = weatherData?.weather.first?.icon else { return }  // Ensure there is an icon name.
        weatherService.fetchIcon(with: iconName) { [weak self] image in
            // Ensure that UI updates are made on the main thread.
            DispatchQueue.main.async {
                self?.weatherIcon = image  // Store the fetched weather icon.
            }
        }
    }

    // Saves the last searched city name to UserDefaults.
    func saveLastSearchedCity() {
        UserDefaults.standard.set(cityName, forKey: Constants.lastSearchedCityKey)
    }

    // Loads the last searched city name from UserDefaults.
    func loadLastSearchedCity() {
        cityName = UserDefaults.standard.string(forKey: Constants.lastSearchedCityKey) ?? ""  // Default to empty string if no value is found.
    }
    
    
    // Fetches the coordinates for the given city using the GeocodingService.
    func fetchCoordinates(forCity city: String) {
        geocodingService.getCoordinates(forCity: city) { [weak self] coordinate in
            // Ensure that UI updates are made on the main thread.
            DispatchQueue.main.async {
                if let coordinate = coordinate {
                    self?.coordinates = "Coordinates of \(city): \(coordinate.lat), \(coordinate.lon)"
                    self?.reverseGeocode(coordinate: coordinate)  // Fetch city info based on the coordinates.
                } else {
                    self?.coordinates = "Could not find coordinates for \(city)"  // Handle failure case.
                }
            }
        }
    }

    // Fetches the city information from the coordinates using the GeocodingService.
    func reverseGeocode(coordinate: Coordinate) {
        geocodingService.getCity(fromCoordinates: coordinate) { [weak self] cityInfo in
            // Ensure that UI updates are made on the main thread.
            DispatchQueue.main.async {
                if let cityInfo = cityInfo {
                    self?.cityInfo = "City at \(coordinate.lat), \(coordinate.lon) is \(cityInfo.name), \(cityInfo.country)"
                } else {
                    self?.cityInfo = "Could not fetch city info for coordinates (\(coordinate.lat), \(coordinate.lon))"
                }
            }
        }
    }
     
}
