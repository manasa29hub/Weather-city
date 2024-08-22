//
//  URLSession.swift
//  Weatherapp
//
//  Created by Manasa Parchuri  on 8/14/24.
//

import Foundation

protocol URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {
    // No need for a custom implementation here, as URLSession already has a matching method.
}
