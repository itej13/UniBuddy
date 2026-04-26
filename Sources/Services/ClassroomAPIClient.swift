import Foundation

struct ClassroomAPIClient {
    var accessToken: String
    var session: URLSession = .shared

    func listCourses() async throws -> [ClassroomCourse] {
        try await pagedRequest(
            path: "courses",
            queryItems: [
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(name: "courseStates", value: "ACTIVE")
            ],
            responseType: ClassroomCoursesResponse.self,
            items: \.courses
        )
    }

    func listCourseWork(courseID: String) async throws -> [ClassroomCourseWork] {
        try await pagedRequest(
            path: "courses/\(courseID)/courseWork",
            queryItems: [
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(name: "orderBy", value: "dueDate desc")
            ],
            responseType: ClassroomCourseWorkResponse.self,
            items: \.courseWork
        )
    }

    func listSubmissions(courseID: String) async throws -> [ClassroomStudentSubmission] {
        try await pagedRequest(
            path: "courses/\(courseID)/courseWork/-/studentSubmissions",
            queryItems: [
                URLQueryItem(name: "pageSize", value: "100"),
                URLQueryItem(name: "userId", value: "me")
            ],
            responseType: ClassroomSubmissionsResponse.self,
            items: \.studentSubmissions
        )
    }

    private func pagedRequest<Response: Decodable, Item>(
        path: String,
        queryItems: [URLQueryItem],
        responseType: Response.Type,
        items: KeyPath<Response, [Item]?>
    ) async throws -> [Item] where Response: PageTokenProviding {
        var allItems: [Item] = []
        var nextPageToken: String?

        repeat {
            var requestQuery = queryItems
            if let nextPageToken {
                requestQuery.append(URLQueryItem(name: "pageToken", value: nextPageToken))
            }
            let response = try await request(path: path, queryItems: requestQuery, responseType: responseType)
            allItems.append(contentsOf: response[keyPath: items] ?? [])
            nextPageToken = response.nextPageToken
        } while nextPageToken != nil

        return allItems
    }

    private func request<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        responseType: Response.Type
    ) async throws -> Response {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "classroom.googleapis.com"
        components.path = "/v1/\(path)"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ClassroomAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClassroomAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No response body"
            let apiError = try? JSONDecoder.classroom.decode(GoogleAPIErrorEnvelope.self, from: data)
            throw ClassroomAPIError.http(
                status: httpResponse.statusCode,
                message: message,
                reason: apiError?.error.details.first?.reason,
                activationURL: apiError?.error.details.compactMap(\.metadata?.activationURL).first
            )
        }

        return try JSONDecoder.classroom.decode(Response.self, from: data)
    }
}

enum ClassroomAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int, message: String, reason: String? = nil, activationURL: String? = nil)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build the Google Classroom API URL."
        case .invalidResponse:
            return "Google Classroom returned an invalid response."
        case let .http(status, message, reason, activationURL):
            if reason == "SERVICE_DISABLED" {
                if let activationURL {
                    return "Google Classroom API is disabled for this Google Cloud project. Enable it here, wait a few minutes, then press Sync again: \(activationURL)"
                }
                return "Google Classroom API is disabled for this Google Cloud project. Enable the Classroom API in Google Cloud, wait a few minutes, then press Sync again."
            }
            return "Google Classroom request failed (\(status)): \(message)"
        }
    }

    var activationURL: URL? {
        if case let .http(_, _, _, activationURL) = self,
           let activationURL {
            return URL(string: activationURL)
        }
        return nil
    }
}

struct GoogleAPIErrorEnvelope: Decodable {
    let error: GoogleAPIError
}

struct GoogleAPIError: Decodable {
    let code: Int
    let message: String
    let status: String
    let details: [GoogleAPIErrorDetail]
}

struct GoogleAPIErrorDetail: Decodable {
    let reason: String?
    let metadata: GoogleAPIErrorMetadata?
}

struct GoogleAPIErrorMetadata: Decodable {
    let activationURL: String?

    enum CodingKeys: String, CodingKey {
        case activationURL = "activationUrl"
    }
}

protocol PageTokenProviding {
    var nextPageToken: String? { get }
}

struct ClassroomCoursesResponse: Decodable, PageTokenProviding {
    let courses: [ClassroomCourse]?
    let nextPageToken: String?
}

struct ClassroomCourseWorkResponse: Decodable, PageTokenProviding {
    let courseWork: [ClassroomCourseWork]?
    let nextPageToken: String?
}

struct ClassroomSubmissionsResponse: Decodable, PageTokenProviding {
    let studentSubmissions: [ClassroomStudentSubmission]?
    let nextPageToken: String?
}

struct ClassroomCourse: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let section: String?
}

struct ClassroomCourseWork: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let alternateLink: String?
    let dueDate: ClassroomDate?
    let dueTime: ClassroomTime?
    let maxPoints: Double?
}

struct ClassroomStudentSubmission: Decodable, Identifiable, Hashable {
    let id: String
    let courseWorkId: String
    let state: String?
    let alternateLink: String?
}

struct ClassroomDate: Decodable, Hashable {
    let year: Int
    let month: Int
    let day: Int
}

struct ClassroomTime: Decodable, Hashable {
    let hours: Int?
    let minutes: Int?
}

extension ClassroomCourseWork {
    var resolvedDueDate: Date? {
        guard let dueDate else { return nil }
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = dueDate.year
        components.month = dueDate.month
        components.day = dueDate.day
        components.hour = dueTime?.hours ?? 23
        components.minute = dueTime?.minutes ?? 59
        return components.date
    }
}

extension JSONDecoder {
    static var classroom: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
