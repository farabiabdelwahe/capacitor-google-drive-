import Foundation
import Capacitor

@objc(GoogleDrivePlugin)
public class GoogleDrivePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GoogleDrivePlugin"
    public let jsName = "GoogleDrive"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listFiles", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "uploadFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "downloadFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deleteFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "createFolder", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getFileMetadata", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "searchFiles", returnType: CAPPluginReturnPromise)
    ]
    
    private var accessToken: String?
    private let DRIVE_API_BASE = "https://www.googleapis.com/drive/v3"
    private let UPLOAD_API_BASE = "https://www.googleapis.com/upload/drive/v3"

    @objc func initialize(_ call: CAPPluginCall) {
        guard let token = call.getString("accessToken") else {
            call.reject("Access token is required", "MISSING_TOKEN")
            return
        }
        self.accessToken = token
        call.resolve(["success": true])
    }
    
    @objc func listFiles(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        let pageSize = call.getInt("pageSize") ?? 100
        let query = call.getString("query")
        let orderBy = call.getString("orderBy")
        let pageToken = call.getString("pageToken")
        
        var components = URLComponents(string: "\(DRIVE_API_BASE)/files")!
        var queryItems = [
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents),nextPageToken")
        ]
        
        if let query = query { queryItems.append(URLQueryItem(name: "q", value: query)) }
        if let orderBy = orderBy { queryItems.append(URLQueryItem(name: "orderBy", value: orderBy)) }
        if let pageToken = pageToken { queryItems.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        
        components.queryItems = queryItems
        
        makeRequest(url: components.url!, method: "GET", body: nil, call: call)
    }
    
    @objc func uploadFile(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let name = call.getString("name"),
              let content = call.getString("content"),
              let mimeType = call.getString("mimeType") else {
            call.reject("Missing required arguments")
            return
        }
        
        let folderId = call.getString("folderId")
        
        let boundary = "-------314159265358979323846"
        let delimiter = "\r\n--\(boundary)\r\n"
        let closeDelimiter = "\r\n--\(boundary)--"
        
        var parents: [String] = []
        if let folderId = folderId {
            parents.append(folderId)
        }
        
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": mimeType,
            "parents": parents
        ]
        
        // Construct the multipart body
        var body = Data()
        
        // Metadata part
        body.append("\(delimiter)Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        
        // Content part
        body.append("\(delimiter)Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(content.data(using: .utf8)!)
        
        body.append("\(closeDelimiter)".data(using: .utf8)!)
        
        let url = URL(string: "\(UPLOAD_API_BASE)/files?uploadType=multipart")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                call.reject("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                     // Check if successful (could check response status code too)
                     if let fileId = json["id"] as? String {
                         call.resolve([
                             "fileId": fileId,
                             "webViewLink": json["webViewLink"] ?? ""
                         ])
                     } else {
                         call.reject("Upload failed", nil, error, json)
                     }
                }
            } catch {
                call.reject("JSON parsing error", nil, error)
            }
        }
        task.resume()
    }

    @objc func downloadFile(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let fileId = call.getString("fileId") else {
            call.reject("fileId is required")
            return
        }
        
        // 1. Get metadata
        let metaUrl = URL(string: "\(DRIVE_API_BASE)/files/\(fileId)?fields=id,name,mimeType")!
        var metaRequest = URLRequest(url: metaUrl)
        metaRequest.httpMethod = "GET"
        metaRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let metaTask = URLSession.shared.dataTask(with: metaRequest) { [weak self] metaData, metaResponse, metaError in
            guard let self = self else { return }
            
            if let error = metaError {
                call.reject(error.localizedDescription)
                return
            }
            
            guard let metaData = metaData,
                  let meta = try? JSONSerialization.jsonObject(with: metaData) as? [String: Any] else {
                call.reject("Failed to get file metadata")
                return
            }
            
            // 2. Get content
            let contentUrl = URL(string: "\(self.DRIVE_API_BASE)/files/\(fileId)?alt=media")!
            var contentRequest = URLRequest(url: contentUrl)
            contentRequest.httpMethod = "GET"
            contentRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let contentTask = URLSession.shared.dataTask(with: contentRequest) { contentData, contentResponse, contentError in
                if let error = contentError {
                    call.reject(error.localizedDescription)
                    return
                }
                
                guard let contentData = contentData,
                      let content = String(data: contentData, encoding: .utf8) else {
                    call.reject("Failed to get file content")
                    return
                }
                
                call.resolve([
                    "content": content,
                    "name": meta["name"] as? String ?? "",
                    "mimeType": meta["mimeType"] as? String ?? ""
                ])
            }
            contentTask.resume()
        }
        metaTask.resume()
    }

    @objc func updateFile(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let fileId = call.getString("fileId"),
              let content = call.getString("content"),
              let mimeType = call.getString("mimeType") else {
            call.reject("fileId, content, and mimeType are required")
            return
        }
        
        let boundary = "-------314159265358979323846"
        let delimiter = "\r\n--\(boundary)\r\n"
        let closeDelimiter = "\r\n--\(boundary)--"
        
        let metadata: [String: Any] = [
            "mimeType": mimeType
        ]
        
        // Construct the multipart body
        var body = Data()
        
        // Metadata part
        body.append("\(delimiter)Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        
        // Content part
        body.append("\(delimiter)Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(content.data(using: .utf8)!)
        
        body.append("\(closeDelimiter)".data(using: .utf8)!)
        
        let url = URL(string: "\(UPLOAD_API_BASE)/files/\(fileId)?uploadType=multipart")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                call.reject("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let fileId = json["id"] as? String {
                        call.resolve([
                            "fileId": fileId,
                            "webViewLink": json["webViewLink"] ?? ""
                        ])
                    } else {
                        call.reject("Update failed", nil, error, json)
                    }
                }
            } catch {
                call.reject("JSON parsing error", nil, error)
            }
        }
        task.resume()
    }

    @objc func deleteFile(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let fileId = call.getString("fileId") else {
            call.reject("fileId is required")
            return
        }
        
        let url = URL(string: "\(DRIVE_API_BASE)/files/\(fileId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                call.resolve(["success": true])
            } else {
                call.reject("Delete failed")
            }
        }
        task.resume()
    }

    @objc func createFolder(_ call: CAPPluginCall) {
        guard let token = self.accessToken else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let name = call.getString("name") else {
            call.reject("name is required")
            return
        }
        
        let parentFolderId = call.getString("parentFolderId")
        
        var metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        
        if let parentFolderId = parentFolderId {
            metadata["parents"] = [parentFolderId]
        }
        
        let url = URL(string: "\(DRIVE_API_BASE)/files")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: metadata)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                call.reject("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let folderId = json["id"] as? String {
                        call.resolve(["folderId": folderId])
                    } else {
                        call.reject("Create folder failed", nil, error, json)
                    }
                }
            } catch {
                call.reject("JSON parsing error", nil, error)
            }
        }
        task.resume()
    }

    @objc func searchFiles(_ call: CAPPluginCall) {
        // searchFiles is essentially listFiles with a query parameter
        // We delegate to listFiles implementation
        listFiles(call)
    }

    @objc func getFileMetadata(_ call: CAPPluginCall) {
        guard self.accessToken != nil else {
            call.reject("Plugin not initialized", "NOT_INITIALIZED")
            return
        }
        
        guard let fileId = call.getString("fileId") else {
            call.reject("fileId is required")
            return
        }
        
        let url = URL(string: "\(DRIVE_API_BASE)/files/\(fileId)?fields=id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents")!
        
        makeRequest(url: url, method: "GET", body: nil, call: call) { data in
            return ["file": data]
        }
    }
    
    private func makeRequest(url: URL, method: String, body: Data?, call: CAPPluginCall, transform: (([String: Any]) -> [String: Any])? = nil) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                call.resolve([:])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let transform = transform {
                        call.resolve(transform(json))
                    } else {
                        call.resolve(json)
                    }
                } else {
                     call.resolve([:]) // Or handle as text/empty
                }
            } catch {
                call.reject("Parsing error", nil, error)
            }
        }
        task.resume()
    }
}

