import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String?
    let residencialId: Int?
    let residencial: String?
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case residencialId = "residencial_id"
        case residencial
        case logo
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
