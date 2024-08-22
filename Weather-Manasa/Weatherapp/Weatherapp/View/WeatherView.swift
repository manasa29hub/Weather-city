//
//  WeatherView.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        VStack {
            TextField("Enter city name", text: $viewModel.cityName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Get Weather") {
                viewModel.fetchWeather()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)  // Display error messages in red
                    .padding()
            }
            
            if let weatherData = viewModel.weatherData {
                Text("Temperature: \(weatherData.main.temp)°C")
                Text("Description: \(weatherData.weather.first?.description ?? "N/A")")
            }
            
            if let weatherIcon = viewModel.weatherIcon {
                Image(uiImage: weatherIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
