//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "9a6a6eceadb61124b2620ea38fedbedf"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case getFavorites
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken:
                return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId:
                return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth:
                return "https://www.themoviedb.org/authenticate/" +  TMDBClient.Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout:
                return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites:
                return Endpoints.base + "/account/{account_id}/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        TMDBClient.taskForRequest(url: Endpoints.getWatchlist.url, method: "GET", body: "", responseType: MovieResults.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion([], error)
                return
            }
            completion(responseObject.results, nil)
        }
    }
    
    class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) {
        TMDBClient.taskForRequest(url: Endpoints.getFavorites.url, method: "GET", body: "", responseType: MovieResults.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion([], error)
                return
            }
            completion(responseObject.results, nil)
        }
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        TMDBClient.taskForRequest(url: Endpoints.getRequestToken.url, method: "GET", body: "", responseType: RequestTokenResponse.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion(false, error)
                return
            }
            Auth.requestToken = responseObject.requestToken
            completion(responseObject.success,nil)
        }
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        TMDBClient.taskForRequest(url: Endpoints.login.url, method: "POST", body: LoginRequest(username: username, password: password, requestToken: TMDBClient.Auth.requestToken), responseType: RequestTokenResponse.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion(false, error)
                return
            }
            Auth.requestToken = responseObject.requestToken
            completion(responseObject.success, nil)
        }
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?) -> Void ) {
        TMDBClient.taskForRequest(url: Endpoints.createSessionId.url, method: "POST", body: PostSession(requestToken: TMDBClient.Auth.requestToken), responseType: SessionResponse.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion(false,error)
                return
            }
            Auth.sessionId = responseObject.sessionId
            completion(responseObject.success,nil)
        }
    }
    
    class func logout(completion: @escaping (Bool, Error?) -> Void) {
        TMDBClient.taskForRequest(url: Endpoints.logout.url, method: "DELETE", body: LogoutRequest(sessionId: TMDBClient.Auth.sessionId), responseType: LogoutResponse.self) { responseObject, error in
            guard let responseObject = responseObject else {
                completion(false,error)
                return
            }
            completion(responseObject.success,nil)
        }
    }
    
    class func taskForRequest<ResponseType:Decodable, RequestType: Encodable>(
        url: URL,
        method: String,
        body: RequestType?,
        responseType: ResponseType.Type,
        completion: @escaping(ResponseType?, Error?) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if method != "GET" {
            request.httpBody = try! JSONEncoder().encode(body)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(nil,error)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(responseType.self, from: data)
                completion(responseObject,nil)
            } catch {
                completion(nil,error)
            }
        }
        task.resume()
    }
        
}
