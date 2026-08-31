//
//  LoginResponse.swift
//  resde
//

import Foundation

struct AuthResponse: Codable {
    let code: Int
    let msj: String
    let accessToken: String
    let token_type: String
    let data: AuthData
}

struct AuthData: Codable {
    let id: Int
    let first_name: String
    let last_name: String
    let residencial_id: Int
    let residencial: String
    let logo: String
    let is_super_admin: Bool
    let ubicaciones: [String: String]
    let roles: [String]
    let permissions: [String]

    enum CodingKeys: String, CodingKey {
        case id, first_name, last_name
        case residencial_id, residencial
        case logo, is_super_admin
        case ubicaciones, roles, permissions
    }

    var name: String {
        "\(first_name) \(last_name)"
    }

    var email: String {
        ""
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}
