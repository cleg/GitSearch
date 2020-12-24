//
//  NetworkManager.swift
//  GitSearch
//
//  Created by Paul Dmitryev on 24.12.2020.
//

import Foundation

enum Request {
    case search(String)
}

protocol Requestable {
    var pathComponent: String { get }
    var queryItems: [String: String] { get }
}

extension Request: Requestable {
    var pathComponent: String {
        switch self {
        case .search:
            return "/search/repositories"
        }
    }

    var queryItems: [String : String] {
        switch self {
        case let .search(term):
            return ["q": term]
        }
    }
}

protocol RequestMaker {
    func perform<Response: Decodable>(request: Request, callback: @escaping (Result<Response, Error>) -> Void)
}

struct Creds: Decodable {
    let token: String
    let name: String
}

enum APIErrors: Error {
    case jsonParseError(Error)
}

struct ReposItems: Decodable {
    let id: Int
    let name: String
    let fullName: String
}

struct ReposSearchResponse: Decodable {
    let items: [ReposItems]
}

class DefaultRequestMaker: RequestMaker {
    private let creds: Creds
    private let decoder = JSONDecoder()

    private var dataTask: URLSessionTask?

    init() {
        guard let configUrl = Bundle.main.url(forResource: "creds", withExtension: "json") else {
            fatalError("No config file")
        }
        do {
            let configData = try Data(contentsOf: configUrl)
            let creds = try JSONDecoder().decode(Creds.self, from: configData)
            self.creds = creds
        } catch {
            print("Reading error \(error.localizedDescription)")
            fatalError()
        }

        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    private func build(request: Request) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = request.pathComponent
        components.queryItems = request.queryItems.map(URLQueryItem.init)

        var request = URLRequest(url: components.url!)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(creds.token)", forHTTPHeaderField: "Authorization")

        return request
    }

    func perform<Response>(request: Request, callback: @escaping (Result<Response, Error>) -> Void) where Response: Decodable {
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with: build(request: request)) { [weak self] data, response, error in
            defer {
                self?.dataTask = nil
            }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print(String(decoding: data!, as: UTF8.self))
                return
            }

            switch (data, error) {
            case let (_, error?):
                callback(.failure(error))
            case let (data?, .none):
                do {
                    guard let strongSelf = self else {
                        return
                    }
                    let decoded = try strongSelf.decoder.decode(Response.self, from: data)
                    callback(.success(decoded))
                } catch {
                    callback(.failure(APIErrors.jsonParseError(error)))
                }
            case (.none, .none):
                fatalError()
            }
        }
        dataTask?.resume()
    }
}
