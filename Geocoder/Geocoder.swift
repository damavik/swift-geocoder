//
// Created by Vital Vinahradau on 3/7/18.
// Copyright (c) 2018 ___VITAL___. All rights reserved.
//

import Foundation

public protocol Requester {
    func performRequest(url: URL, callback: (_: Int, _: String?) -> Void)
}

public final class Geocoder {
    private let apiKey: String
    private let baseUrl: String
    private let language: Language
    private let requester: Requester

    public init(apiKey: String, language: Language = .en, requester: Requester) {
        self.apiKey = apiKey
        self.baseUrl = "https://maps.googleapis.com/maps/api/geocode/json"
        self.language = language
        self.requester = requester
    }

    public func geocode(address: String,
                        viewPort: Geometry.ViewPort? = nil,
                        callback: (_: Response) -> Void) {
        var urlComponents = URLComponents(string: self.baseUrl)!

        urlComponents.queryItems = [
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "key", value: self.apiKey),
            URLQueryItem(name: "language", value: self.language.rawValue)
        ]

        if let viewPort = viewPort {
            let value = "\(viewPort.northEast.latitude),\(viewPort.northEast.longitude)|\(viewPort.southWest.latitude),\(viewPort.southWest.longitude)"
            urlComponents.queryItems?.append(URLQueryItem(name: "bounds", value: value))
        }

        guard let url = urlComponents.url else {
            return callback(Response.init(results: nil, statusCode: StatusCode.unknown, errorMessage: nil))
        }

        self.performRequest(url: url, callback: callback)
    }

    public func geocode(placeId: String,
                        callback: (_: Response) -> Void) {
        var urlComponents = URLComponents(string: self.baseUrl)!

        urlComponents.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "key", value: self.apiKey),
            URLQueryItem(name: "language", value: self.language.rawValue)
        ]

        guard let url = urlComponents.url else {
            return callback(Response.init(results: nil, statusCode: StatusCode.unknown, errorMessage: nil))
        }

        self.performRequest(url: url, callback: callback)
    }

    public func reverseGeocode(coordinate: Geometry.Coordinate,
                               resultType: [AddressType] = [],
                               locationType: [LocationType] = [],
                               callback: (_: Response) -> Void) {
        var urlComponents = URLComponents(string: self.baseUrl)!

        urlComponents.queryItems = [
            URLQueryItem(name: "latlng", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "key", value: self.apiKey),
            URLQueryItem(name: "language", value: self.language.rawValue)
        ]

        if resultType.count > 0 {
            let typesString = resultType.map({ $0.rawValue }).joined(separator: "|")
            urlComponents.queryItems?.append(URLQueryItem(name: "result_type", value: typesString))
        }

        if locationType.count > 0 {
            let typesString = locationType.map({ $0.rawValue }).joined(separator: "|")
            urlComponents.queryItems?.append(URLQueryItem(name: "location_type", value: typesString))
        }

        guard let url = urlComponents.url else {
            return callback(Response.init(results: nil, statusCode: StatusCode.unknown, errorMessage: nil))
        }

        self.performRequest(url: url, callback: callback)
    }

    private func performRequest(url: URL, callback: (_: Response) -> Void) {
        self.requester.performRequest(url: url) { (statusCode, payload) in
            var emptyResponse: Response {
                return Response.init(results: nil, statusCode: StatusCode.unknown, errorMessage: nil)
            }

            guard statusCode == 200 else {
                return callback(emptyResponse)
            }

            guard let payload = payload else {
                return callback(emptyResponse)
            }

            guard let response = Response.init(from: payload) else {
                return callback(emptyResponse)
            }

            return callback(response)
        }
    }
}
