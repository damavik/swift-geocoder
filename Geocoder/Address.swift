//
// Created by Vital Vinahradau on 3/16/18.
// Copyright (c) 2018 ___VITAL___. All rights reserved.
//

import Foundation

public enum AddressType: String, Codable {
    // Most common
    case administrativeAreaLevel01 = "administrative_area_level_1"
    case administrativeAreaLevel02 = "administrative_area_level_2"
    case administrativeAreaLevel03 = "administrative_area_level_3"
    case administrativeAreaLevel04 = "administrative_area_level_4"
    case administrativeAreaLevel05 = "administrative_area_level_5"

    case streetAddress = "street_address"
    case route
    case intersection
    case political
    case country
    case colloquialArea = "colloquial_area"
    case locality
    case subLocality = "sublocality"
    case ward
    case neighborhood
    case premise
    case subPremise = "subpremise"
    case postalCode = "postal_code"
    case naturalFeature = "natural_feature"
    case airport
    case park
    case pointOfInterest = "point_of_interest"

    // Common
    case subLocalityLevel01 = "sublocality_level_1"
    case subLocalityLevel02 = "sublocality_level_2"
    case subLocalityLevel03 = "sublocality_level_3"
    case subLocalityLevel04 = "sublocality_level_4"
    case subLocalityLevel05 = "sublocality_level_5"

    // Least common
    case floor
    case establishment
    case parking
    case postBox = "post_box"
    case postalTown = "postal_town"
    case room
    case streetNumber = "street_number"
    case busStation = "bus_station"
    case trainStation = "train_station"
    case transitStation = "transit_station"
}

public enum LocationType: String, Codable {
    case roofTop = "ROOFTOP"
    case rangeInterpolated = "RANGE_INTERPOLATED"
    case geometricCenter = "GEOMETRIC_CENTER"
    case approximate = "APPROXIMATE"
}

public struct Component: Equatable, Codable {
    let shortName: String
    let longName: String
    let types: [AddressType]

    private enum CodingKeys: String, CodingKey {
        case shortName = "short_name"
        case longName = "long_name"
        case types
    }
}

public struct Geometry: Equatable, Codable {
    let location: Coordinate
    let locationType: LocationType
    let viewPort: ViewPort

    private enum CodingKeys: String, CodingKey {
        case location
        case locationType = "location_type"
        case viewPort = "viewport"
    }

    public struct Coordinate: Equatable, Codable {
        // Unable to deal with plain member variables of Double type because of https://bugs.swift.org/browse/SR-7054
        public var latitude: Double {
            return NSDecimalNumber(decimal: _latitude).doubleValue
        }
        public var longitude: Double {
            return NSDecimalNumber(decimal: _longitude).doubleValue
        }

        private let _latitude: Decimal
        private let _longitude: Decimal

        public init(latitude: Double, longitude: Double) {
            self._latitude = Decimal.init(latitude)
            self._longitude = Decimal.init(longitude)
        }

        private enum CodingKeys: String, CodingKey {
            case _latitude = "lat"
            case _longitude = "lng"
        }
    }

    public struct ViewPort: Equatable, Codable {
        let northEast: Coordinate
        let southWest: Coordinate

        private enum CodingKeys: String, CodingKey {
            case northEast = "northeast"
            case southWest = "southwest"
        }
    }
}

public struct Address: Equatable, Codable {
    let components: [Component]
    let geometry: Geometry
    let formattedAddress: String?
    let placeId: String?
    let types: [AddressType]

    private enum CodingKeys: String, CodingKey {
        case components = "address_components"
        case geometry
        case formattedAddress = "formatted_address"
        case placeId = "place_id"
        case types
    }
}
