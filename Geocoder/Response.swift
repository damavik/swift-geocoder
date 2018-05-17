//
// Created by Vital Vinahradau on 3/16/18.
// Copyright (c) 2018 ___VITAL___. All rights reserved.
//

import Foundation

public enum StatusCode: String, Codable {
    case ok = "OK"
    case zeroResults = "ZERO_RESULTS"
    case overQueryLimit = "OVER_QUERY_LIMIT"
    case requestDenied = "REQUEST_DENIED"
    case invalidRequest = "INVALID_REQUEST"
    case unknown = "UNKNOWN_ERROR"
}

public struct Response: Codable {
    let results: [Address]?
    let statusCode: StatusCode
    let errorMessage: String?

    private enum CodingKeys: String, CodingKey {
        case results
        case statusCode = "status"
        case errorMessage = "error_message"

    }

    init(results: [Address]?, statusCode: StatusCode, errorMessage: String?) {
        self.results = results
        self.statusCode = statusCode
        self.errorMessage = errorMessage
    }

    public init?(from: String) {
        guard let jsonData = from.data(using: .utf8) else {
            return nil
        }

        guard let response = try? JSONDecoder().decode(Response.self, from: jsonData) else {
            return nil
        }

        self = response
    }
}
