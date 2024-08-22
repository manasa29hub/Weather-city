//
//  WeatherappTests.swift
//  WeatherappTests
//
//  Created by Manasa Parchuri  on 8/14/24.
//
import CoreLocation
import XCTest
import SwiftUI
@testable import Weatherapp

final class WeatherViewModelTests: XCTestCase {

    var viewModel: WeatherViewModel!
    var mockGeocodingService: MockGeocodingService!
    var mockWeatherService: MockWeatherService!
    
    //for location manager
    var locationManager: LocationManager!
    var mockLocationManager: MockCLLocationManager!
    
    //
    var weatherService: WeatherService!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        // Initialize mock services
        mockGeocodingService = MockGeocodingService()
        mockWeatherService = MockWeatherService()
        // Initialize the ViewModel with mock services
        viewModel = WeatherViewModel(geocodingService: mockGeocodingService, weatherService: mockWeatherService)
        
        mockLocationManager = MockCLLocationManager()
        locationManager = LocationManager()
        locationManager.locatioManager = mockLocationManager // Inject the mock
        
        mockSession = MockURLSession()
        weatherService = WeatherService(session: mockSession)
        
    }

    override func tearDown() {
        // Cleanup
        viewModel = nil
        mockGeocodingService = nil
        mockWeatherService = nil
        super.tearDown()
    }
    // MARK: - fetchWeather Tests
     
     func testFetchWeather_SuccessResponse() {
         // Given
         let cityName = "New York"
         let expectedWeatherData = ResponseBody(
             coord: ResponseBody.CoordinatesResponse(lon: -74.0060, lat: 40.7128),
             weather: [ResponseBody.WeatherResponse(id: 800, main: "Clear", description: "Clear sky", icon: "01d")],
             main: ResponseBody.MainResponse(temp: 25.0, feels_like: 26.0, temp_min: 22.0, temp_max: 27.0, pressure: 1013, humidity: 60),
             name: cityName,
             wind: ResponseBody.WindResponse(speed: 5.0, deg: 180)
         )
         let jsonData = try! JSONEncoder().encode(expectedWeatherData)
         
         mockSession.nextData = jsonData
         mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://api.openweathermap.org")!,
                                                    statusCode: 200, httpVersion: nil, headerFields: nil)
         
         let expectation = self.expectation(description: "Weather data fetched")
         
         // When
         weatherService.fetchWeather(for: cityName) { result in
             switch result {
             case .success(let weatherData):
                 XCTAssertEqual(weatherData.name, expectedWeatherData.name)
                 XCTAssertEqual(weatherData.main.temp, expectedWeatherData.main.temp)
             case .failure(let error):
                 XCTFail("Expected success but got failure with error: \(error)")
             }
             expectation.fulfill()
         }
         
         // Then
         waitForExpectations(timeout: 1, handler: nil)
     }
     
     func testFetchWeather_Failure_InvalidResponse() {
         // Given
         mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://api.openweathermap.org")!,
                                                    statusCode: 404, httpVersion: nil, headerFields: nil)
         mockSession.nextData = nil
         
         let expectation = self.expectation(description: "Weather data fetch failed")
         
         // When
         weatherService.fetchWeather(for: "InvalidCity") { result in
             switch result {
             case .success:
                 XCTFail("Expected failure but got success")
             case .failure(let error as NSError):
                 XCTAssertEqual(error.domain, "Client error with status code: 404")
             }
             expectation.fulfill()
         }
         
         // Then
         waitForExpectations(timeout: 1, handler: nil)
     }
     
     func testFetchWeather_Failure_InvalidData() {
         // Given
         mockSession.nextData = "Invalid Data".data(using: .utf8)
         mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://api.openweathermap.org")!,
                                                    statusCode: 200, httpVersion: nil, headerFields: nil)
         
         let expectation = self.expectation(description: "Weather data fetch failed due to invalid data")
         
         // When
         weatherService.fetchWeather(for: "New York") { result in
             switch result {
             case .success:
                 XCTFail("Expected failure but got success")
             case .failure:
                 break // Expected failure
             }
             expectation.fulfill()
         }
         
         // Then
         waitForExpectations(timeout: 1, handler: nil)
     }
     
     // MARK: - fetchIcon Tests
     
     func testFetchIcon_Success() {
         // Given
         let iconName = "01d"
         let expectedImage = UIImage(systemName: "sun.max.fill")!
         mockSession.nextData = expectedImage.pngData()
         let expectation = self.expectation(description: "Weather icon fetched")
         
         // When
         weatherService.fetchIcon(with: iconName) { image in
             XCTAssertNotNil(image, "Image should not be nil")
             expectation.fulfill()
         }
         
         // Then
         waitForExpectations(timeout: 1, handler: nil)
     }
     
     
     func testFetchIcon_Failure() {
         // Given
         let iconName = "invalidIcon"
         mockSession.nextData = nil
         
         let expectation = self.expectation(description: "Weather icon fetch failed")
         
         // When
         weatherService.fetchIcon(with: iconName) { image in
             XCTAssertNil(image, "Image should be nil for an invalid icon")
             expectation.fulfill()
         }
         
         // Then
         waitForExpectations(timeout: 1, handler: nil)
     }

    func testFetchCoordinates_Success() {
        // Given
        let cityName = "New York"
        let expectedCoordinate = Coordinate(lat: 40.7128, lon: -74.0060)
        mockGeocodingService.mockCoordinate = expectedCoordinate
        
        // Create an expectation for the asynchronous code to complete
        let expectation = self.expectation(description: "Fetch coordinates")

        // When
        viewModel.fetchCoordinates(forCity: cityName)
        
        // Use DispatchQueue.main.async to wait for the viewModel to update
        DispatchQueue.main.async {
            // Then
            XCTAssertEqual(self.viewModel.coordinates, "Coordinates of \(cityName): \(expectedCoordinate.lat), \(expectedCoordinate.lon)")
            expectation.fulfill() // Mark the expectation as fulfilled
        }
        
        // Wait for the expectation to be fulfilled, with a timeout
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testFetchCoordinates_Failure() {
        // Given
        let cityName = "New York"
        mockGeocodingService.mockCoordinate = nil

        // When
        viewModel.fetchCoordinates(forCity: cityName)

        // Then
        XCTAssertNotEqual(viewModel.coordinates, "Could not find coordinates for \(cityName)")
    }

    func testReverseGeocode_Success() {
        // Given
        let coordinate = Coordinate(lat: 40.7128, lon: -74.0060)
        let expectedCityInfo = CityInfo(name: "New York", state: "", country: "USA")
        mockGeocodingService.mockCityInfo = expectedCityInfo

        viewModel.reverseGeocode(coordinate: coordinate)

        XCTAssertEqual(viewModel.cityName, "\(expectedCityInfo.name)")
    }

    func testReverseGeocode_Failure() {
        // Given
        let coordinate = Coordinate(lat: 40.7128, lon: -74.0060)
        mockGeocodingService.mockCityInfo = nil

        viewModel.reverseGeocode(coordinate: coordinate)

        XCTAssertEqual(viewModel.cityName, "New York")
    }

    func testFetchWeather_Success() {
        let cityName = "New York"
        viewModel.cityName = cityName
        
        let expectedWeatherData = ResponseBody(
            coord: ResponseBody.CoordinatesResponse(lon: -74.0060, lat: 40.7128),
            weather: [ResponseBody.WeatherResponse(id: 800, main: "Clear", description: "Clear sky", icon: "01d")],
            main: ResponseBody.MainResponse(temp: 25.0, feels_like: 26.0, temp_min: 22.0, temp_max: 27.0, pressure: 1013, humidity: 60),
            name: cityName,
            wind: ResponseBody.WindResponse(speed: 5.0, deg: 180)
        )
        mockWeatherService.mockWeatherData = .success(expectedWeatherData)
        
        let expectation = self.expectation(description: "Weather data loaded")
        
        viewModel.fetchWeather()
        
        // Asynchronous wait to check the value of viewModel.weatherData
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.weatherData?.name, expectedWeatherData.name)
            XCTAssertEqual(self.viewModel.weatherData?.main.temp, expectedWeatherData.main.temp)
            XCTAssertNil(self.viewModel.errorMessage)
            expectation.fulfill() // Mark the expectation as fulfilled
        }
        
        // Wait for the expectation to be fulfilled with a timeout
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchWeather_Failure() {
        // Given
        let cityName = "New York"
        viewModel.cityName = cityName
        let expectedError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network Error"])
        mockWeatherService.mockWeatherData = .failure(expectedError)

        viewModel.fetchWeather()

        XCTAssertNil(viewModel.weatherData)
    }

    func testLoadWeatherIcon() {
        // Given
        let iconName = "01d"
        let weatherResponse = ResponseBody.WeatherResponse(
            id: 800,
            main: "Clear",
            description: "Clear sky",
            icon: iconName
        )
        viewModel.weatherData = ResponseBody(
            coord: ResponseBody.CoordinatesResponse(lon: -74.0060, lat: 40.7128),
            weather: [weatherResponse],
            main: ResponseBody.MainResponse(temp: 25.0, feels_like: 26.0, temp_min: 22.0, temp_max: 27.0, pressure: 1013, humidity: 60),
            name: "New York",
            wind: ResponseBody.WindResponse(speed: 5.0, deg: 180)
        )
        
        // Mock expected image
        let expectedImage = UIImage(systemName: "sun.max.fill")
        mockWeatherService.mockIconImage = expectedImage
        
        // Create an expectation for the asynchronous fetchIcon method
        let expectation = self.expectation(description: "Weather icon loaded")
        
        viewModel.loadWeatherIcon()
        
        // Asynchronous wait to check the value of viewModel.weatherIcon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.weatherIcon, expectedImage, "The weather icon should match the expected image.")
            expectation.fulfill() // Mark the expectation as fulfilled
        }
        
        // Wait for the expectation to be fulfilled with a timeout
        waitForExpectations(timeout: 1, handler: nil)
    }


    func testSaveAndLoadLastSearchedCity() {
        // Given
        let cityName = "New York"
        viewModel.cityName = cityName

        viewModel.saveLastSearchedCity()
        viewModel.cityName = ""  // Clear the city name
        viewModel.loadLastSearchedCity()

        XCTAssertEqual(viewModel.cityName, cityName)
    }
    
    func testRequestLocation_StartsUpdatingLocation() {
            // Given
            let locationExpectation = expectation(description: "Location request starts")
            
            // Set up a mock location
            mockLocationManager.mockLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
            
            // When
            locationManager.requestLocation()
            
            // Then
            XCTAssertTrue(locationManager.isLoading)
            
            // Simulate location update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                locationExpectation.fulfill()
            }
            
            waitForExpectations(timeout: 1, handler: nil)
        }
        
    func testLocationManager_DidUpdateLocations() {
        // Given
        let locationExpectation = expectation(description: "Location update")
        let testLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
        mockLocationManager.mockLocation = testLocation
        
        // When
        locationManager.requestLocation()
        mockLocationManager.simulateLocationUpdate() // Trigger the delegate callback
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            locationExpectation.fulfill() // Mark the expectation as fulfilled
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

        
    func testLocationManager_DidFailWithError() {
        // Given
        let locationExpectation = expectation(description: "Location failure")
        let testError = NSError(domain: "TestErrorDomain", code: 1, userInfo: nil)
        mockLocationManager.mockError = testError
        
        // When
        locationManager.requestLocation()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(self.locationManager.location)
            locationExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}



// Mock Services

class MockGeocodingService: GeocodingService {
    var mockCoordinate: Coordinate?
    var mockCityInfo: CityInfo?

    override func getCoordinates(forCity city: String, completion: @escaping (Coordinate?) -> Void) {
        completion(mockCoordinate)
    }

    override func getCity(fromCoordinates coordinate: Coordinate, completion: @escaping (CityInfo?) -> Void) {
        completion(mockCityInfo)
    }
}

class MockWeatherService: WeatherService {
    var mockWeatherData: Result<ResponseBody, Error>?
    var mockIconImage: UIImage?

    override func fetchWeather(for city: String, completion: @escaping (Result<ResponseBody, Error>) -> Void) {
        if let mockWeatherData = mockWeatherData {
            completion(mockWeatherData)
        }
    }

    override func fetchIcon(with iconName: String, completion: @escaping (UIImage?) -> Void) {
        completion(mockIconImage)
    }
}

// Mock CLLocationManager for testing
class MockCLLocationManager: CLLocationManager {
    var mockLocation: CLLocation?
    var mockError: Error?
    
    override func startUpdatingLocation() {
        if let location = mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [location])
        }
        if let error = mockError {
            delegate?.locationManager?(self, didFailWithError: error)
        }
    }
    
    override func requestWhenInUseAuthorization() {
        // Simulate the behavior if needed
    }
    
    // Add this method to simulate location updates
    func simulateLocationUpdate() {
        if let location = mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [location])
        }
        if let error = mockError {
            delegate?.locationManager?(self, didFailWithError: error)
        }
    }
}

// MockURLSession conforms to URLSessionProtocol and mimics the behavior of a real URLSession.
class MockURLSession: URLSessionProtocol {
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?
    
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockURLSessionDataTask {
            completionHandler(self.nextData, self.nextResponse, self.nextError)
        }
    }
}

// MockURLSessionDataTask mimics the behavior of a real URLSessionDataTask.
class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void
    
    // Store the completion closure and call it in the resume method.
    init(closure: @escaping () -> Void) {
        self.closure = closure
    }
    
    // Override the resume method to invoke the closure.
    override func resume() {
        closure()
    }
    
    // Ensure we correctly handle the task cancellation if needed.
    override func cancel() {
    }
}
