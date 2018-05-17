//
//  GeocoderTests.swift
//  GeocoderTests
//
//  Created by Vital Vinahradau on 3/7/18.
//  Copyright © 2018 ___VITAL___. All rights reserved.
//

import XCTest
import VVGeocoder

// Convenience
extension GeocoderTests: Requester {
    func performRequest(url: URL, callback: (_: Int, _: String?) -> Void) {
        self.formedUrl = url
        callback(200, nil)
    }
}

extension String {
    func trimJsonFormatting() -> String {
        let encodedData = self.data(using: .utf8)!
        let encodedDictionary = try! JSONSerialization.jsonObject(with: encodedData)

        let decodedData = try! JSONSerialization.data(withJSONObject: encodedDictionary)
        return String(data: decodedData, encoding: .utf8)!
    }
}

extension URL {
    func equalsSemantically(to url: URL) -> Bool {
        if self == url {
            return true
        }

        let selfUrlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        let selfDictionary = selfUrlComponents.queryItems!.reduce([String: String?]()) { (result, queryItem) in
            var updatedResult = result
            updatedResult[queryItem.name] = queryItem.value
            return updatedResult
        }

        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let urlDictionary = urlComponents.queryItems!.reduce([String: String?]()) { (result, queryItem) in
            var updatedResult = result
            updatedResult[queryItem.name] = queryItem.value
            return updatedResult
        }

        return self.baseURL == url.baseURL
                && selfDictionary == urlDictionary
    }
}

class GeocoderTests: XCTestCase {
    var formedUrl: URL?
    var geocoder: Geocoder!

    override func setUp() {
        super.setUp()
        self.geocoder = Geocoder(apiKey: "dummy_api_key", requester: self)
    }

    override func tearDown() {
        self.formedUrl = nil
        super.tearDown()
    }

    func testSuccessfulResponseParsing() {
        let jsonString = """
               {
               "results" : [
                  {
                     "address_components" : [
                        {
                           "long_name" : "1600",
                           "short_name" : "1600",
                           "types" : [ "street_number" ]
                        },
                        {
                           "long_name" : "Amphitheatre Pkwy",
                           "short_name" : "Amphitheatre Pkwy",
                           "types" : [ "route" ]
                        },
                        {
                           "long_name" : "Mountain View",
                           "short_name" : "Mountain View",
                           "types" : [ "locality", "political" ]
                        },
                        {
                           "long_name" : "Santa Clara County",
                           "short_name" : "Santa Clara County",
                           "types" : [ "administrative_area_level_2", "political" ]
                        },
                        {
                           "long_name" : "California",
                           "short_name" : "CA",
                           "types" : [ "administrative_area_level_1", "political" ]
                        },
                        {
                           "long_name" : "United States",
                           "short_name" : "US",
                           "types" : [ "country", "political" ]
                        },
                        {
                           "long_name" : "94043",
                           "short_name" : "94043",
                           "types" : [ "postal_code" ]
                        }
                     ],
                     "formatted_address" : "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA",
                     "geometry" : {
                        "location" : {
                           "lat" : 37.4224764,
                           "lng" : -122.0842499
                        },
                        "location_type" : "ROOFTOP",
                        "viewport" : {
                           "northeast" : {
                              "lat" : 37.4238253802915,
                              "lng" : -122.0829009197085
                           },
                           "southwest" : {
                              "lat" : 37.4211274197085,
                              "lng" : -122.0855988802915
                           }
                        }
                     },
                     "place_id" : "ChIJ2eUgeAK6j4ARbn5u_wAGqWA",
                     "types" : [ "street_address" ]
                  }
               ],
               "status" : "OK"
               }
        """

        let jsonData = jsonString.data(using: .utf8)!
        guard let response = try? JSONDecoder().decode(Response.self, from: jsonData) else {
            return XCTFail("Failed to parse Response from JSON")
        }

        XCTAssertNil(response.errorMessage)
        XCTAssertEqual(response.statusCode, StatusCode.ok)
        XCTAssert(response.results?.count == 1)

        guard let address = response.results?.first else {
            return XCTFail("Response results list should not be nil")
        }
        XCTAssertEqual(address.formattedAddress, "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA")
        XCTAssertEqual(address.placeId, "ChIJ2eUgeAK6j4ARbn5u_wAGqWA")
        XCTAssertEqual(address.types, [AddressType.streetAddress])

        let geometry = address.geometry
        XCTAssertEqual(geometry.locationType, LocationType.roofTop)
        XCTAssertEqual(geometry.location, Geometry.Coordinate(latitude: Double(37.4224764), longitude: Double(-122.0842499)))

        let viewPort = address.geometry.viewPort
        XCTAssertEqual(viewPort.northEast, Geometry.Coordinate(latitude: 37.4238253802915, longitude: -122.0829009197085))
        XCTAssertEqual(viewPort.southWest, Geometry.Coordinate(latitude: 37.4211274197085, longitude: -122.0855988802915))

        XCTAssert(address.components.count == 7)
        let targetComponents = [Component(shortName: "1600", longName: "1600", types: [AddressType.streetNumber]),
                                Component(shortName: "Amphitheatre Pkwy", longName: "Amphitheatre Pkwy", types: [AddressType.route]),
                                Component(shortName: "Mountain View", longName: "Mountain View", types: [AddressType.locality, AddressType.political]),
                                Component(shortName: "Santa Clara County", longName: "Santa Clara County", types: [AddressType.administrativeAreaLevel02, AddressType.political]),
                                Component(shortName: "CA", longName: "California", types: [AddressType.administrativeAreaLevel01, AddressType.political]),
                                Component(shortName: "US", longName: "United States", types: [AddressType.country, AddressType.political]),
                                Component(shortName: "94043", longName: "94043", types: [AddressType.postalCode])]

        XCTAssertEqual(address.components, targetComponents)
    }

    func testResponseJsonifying() {
//        let jsonString = """
//               {
//               "results" : [
//                  {
//                     "address_components" : [
//                        {
//                           "long_name" : "1600",
//                           "short_name" : "1600",
//                           "types" : [ "street_number" ]
//                        },
//                        {
//                           "long_name" : "Amphitheatre Pkwy",
//                           "short_name" : "Amphitheatre Pkwy",
//                           "types" : [ "route" ]
//                        },
//                        {
//                           "long_name" : "Mountain View",
//                           "short_name" : "Mountain View",
//                           "types" : [ "locality", "political" ]
//                        },
//                        {
//                           "long_name" : "Santa Clara County",
//                           "short_name" : "Santa Clara County",
//                           "types" : [ "administrative_area_level_2", "political" ]
//                        },
//                        {
//                           "long_name" : "California",
//                           "short_name" : "CA",
//                           "types" : [ "administrative_area_level_1", "political" ]
//                        },
//                        {
//                           "long_name" : "United States",
//                           "short_name" : "US",
//                           "types" : [ "country", "political" ]
//                        },
//                        {
//                           "long_name" : "94043",
//                           "short_name" : "94043",
//                           "types" : [ "postal_code" ]
//                        }
//                     ],
//                     "formatted_address" : "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA",
//                     "geometry" : {
//                        "location" : {
//                           "lat" : 37.4224764,
//                           "lng" : -122.0842499
//                        },
//                        "location_type" : "ROOFTOP",
//                        "viewport" : {
//                           "northeast" : {
//                              "lat" : 37.4238253802915,
//                              "lng" : -122.0829009197085
//                           },
//                           "southwest" : {
//                              "lat" : 37.4211274197085,
//                              "lng" : -122.0855988802915
//                           }
//                        }
//                     },
//                     "place_id" : "ChIJ2eUgeAK6j4ARbn5u_wAGqWA",
//                     "types" : [ "street_address" ]
//                  }
//               ],
//               "status" : "OK"
//               }
//        """
//
//        let jsonData = jsonString.data(using: .utf8)!
//        guard let response = try? JSONDecoder().decode(Response.self, from: jsonData) else {
//            return XCTFail("Failed to parse Response from JSON")
//        }
//
//        guard let encodedData = try? JSONEncoder().encode(response) else {
//            return XCTFail("Failed to encode Response")
//        }
//        let encodedString = String(data:encodedData, encoding: .utf8)
//
//        XCTAssertEqual(jsonString.trimJsonFormatting(), encodedString)
    }

    func testGeocodeUrlPreparationWithAddressOnly() {
        self.geocoder.geocode(address: "10 Biruzova Street, Minsk, Belarus") { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=10%20Biruzova%20Street,%20Minsk,%20Belarus&key=dummy_api_key&language=en")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testGeocodeUrlPreparationWithViewPort() {
        let viewPort = Geometry.ViewPort(northEast: Geometry.Coordinate(latitude: 34.172684, longitude: -118.604794),
                southWest: Geometry.Coordinate(latitude: 34.236144, longitude: -118.500938))

        self.geocoder.geocode(address: "Winnetka", viewPort: viewPort) { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?language=en&address=Winnetka&key=dummy_api_key&bounds=34.172684,-118.604794%7C34.236144,-118.500938")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testGeocodeUrlPreparationWithPlaceId() {
        self.geocoder.geocode(placeId: "ChIJd8BlQ2BZwokRAFUEcm_qrcA") { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?place_id=ChIJd8BlQ2BZwokRAFUEcm_qrcA&key=dummy_api_key&language=en")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testReverseGeocodeUrlPreparationWithLocationOnly() {
        let coordinate = Geometry.Coordinate(latitude: 40.714224, longitude: -73.961452)
        self.geocoder.reverseGeocode(coordinate: coordinate) { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=dummy_api_key&language=en")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testReverseGeocodeUrlPreparationWithResultType() {
        let coordinate = Geometry.Coordinate(latitude: 40.714224, longitude: -73.961452)
        self.geocoder.reverseGeocode(coordinate: coordinate,
                resultType: [.streetAddress, .country, .locality]) { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?language=en&latlng=40.714224,-73.961452&key=dummy_api_key&result_type=street_address%7Ccountry%7Clocality")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testReverseGeocodeUrlPreparationWithLocationType() {
        let coordinate = Geometry.Coordinate(latitude: 40.714224, longitude: -73.961452)
        self.geocoder.reverseGeocode(coordinate: coordinate,
                locationType: [.roofTop, .approximate]) { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?language=en&latlng=40.714224,-73.961452&key=dummy_api_key&location_type=ROOFTOP%7CAPPROXIMATE")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }

    func testReverseGeocodeUrlPreparationWithResultAndLocationType() {
        let coordinate = Geometry.Coordinate(latitude: 40.714224, longitude: -73.961452)
        self.geocoder.reverseGeocode(coordinate: coordinate,
                resultType: [.streetAddress, .country, .locality],
                locationType: [.roofTop, .approximate]) { (_) in
        }

        let targetUrl = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?language=en&latlng=40.714224,-73.961452&key=dummy_api_key&result_type=street_address%7Ccountry%7Clocality&location_type=ROOFTOP%7CAPPROXIMATE")
        XCTAssert(self.formedUrl!.equalsSemantically(to: targetUrl!))
    }
}
