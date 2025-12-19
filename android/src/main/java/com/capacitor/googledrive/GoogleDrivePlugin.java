package com.capacitor.googledrive;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

@CapacitorPlugin(name = "GoogleDrive")
public class GoogleDrivePlugin extends Plugin {

    private String accessToken = null;
    private static final String DRIVE_API_BASE = "https://www.googleapis.com/drive/v3";
    private static final String UPLOAD_API_BASE = "https://www.googleapis.com/upload/drive/v3";

    @PluginMethod
    public void initialize(PluginCall call) {
        String token = call.getString("accessToken");
        if (token == null) {
            call.reject("Access token is required", "MISSING_TOKEN");
            return;
        }
        this.accessToken = token;
        JSObject ret = new JSObject();
        ret.put("success", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void listFiles(PluginCall call) {
        if (accessToken == null) {
            call.reject("Plugin not initialized", "NOT_INITIALIZED");
            return;
        }

        try {
            Integer pageSize = call.getInt("pageSize", 100);
            String query = call.getString("query");
            String orderBy = call.getString("orderBy");
            String pageToken = call.getString("pageToken");

            StringBuilder urlBuilder = new StringBuilder(DRIVE_API_BASE + "/files?");
            urlBuilder.append("pageSize=").append(pageSize);
            urlBuilder.append("&fields=").append("files(id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents),nextPageToken");
            
            if (query != null) urlBuilder.append("&q=").append(java.net.URLEncoder.encode(query, "UTF-8"));
            if (orderBy != null) urlBuilder.append("&orderBy=").append(java.net.URLEncoder.encode(orderBy, "UTF-8"));
            if (pageToken != null) urlBuilder.append("&pageToken=").append(java.net.URLEncoder.encode(pageToken, "UTF-8"));

            HttpURLConnection conn = createConnection(urlBuilder.toString(), "GET");
            processResponse(conn, call);

        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }

    @PluginMethod
    public void getFileMetadata(PluginCall call) {
        if (accessToken == null) {
            call.reject("Plugin not initialized", "NOT_INITIALIZED");
            return;
        }
        try {
            String fileId = call.getString("fileId");
            if (fileId == null) {
                call.reject("fileId is required");
                return;
            }
            String url = DRIVE_API_BASE + "/files/" + fileId + "?fields=id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents";
            HttpURLConnection conn = createConnection(url, "GET");
            
            String responseStr = readResponse(conn);
            if (conn.getResponseCode() >= 200 && conn.getResponseCode() < 300) {
                JSObject ret = new JSObject();
                ret.put("file", new JSObject(responseStr));
                call.resolve(ret);
            } else {
                 call.reject(responseStr);
            }
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }
    
    // Simplistic text upload for demonstration in this rapid implementation
    // Real implementation should handle multipart properly; for now we support simple upload if logic is complex
    @PluginMethod
    public void uploadFile(PluginCall call) {
         if (accessToken == null) {
            call.reject("Plugin not initialized", "NOT_INITIALIZED");
            return;
        }
        
        try {
            String name = call.getString("name");
            String content = call.getString("content");
            String mimeType = call.getString("mimeType");
            String folderId = call.getString("folderId"); // ignored in simple upload if not using multipart

            // Using multipart upload
            String boundary = "-------314159265358979323846";
            String delimiter = "\r\n--" + boundary + "\r\n";
            String closeDelimiter = "\r\n--" + boundary + "--";

            JSONObject metadata = new JSONObject();
            metadata.put("name", name);
            metadata.put("mimeType", mimeType);
            if (folderId != null) {
                JSONArray parents = new JSONArray();
                parents.put(folderId);
                metadata.put("parents", parents);
            }

            String body = delimiter +
                "Content-Type: application/json; charset=UTF-8\r\n\r\n" +
                metadata.toString() +
                delimiter +
                "Content-Type: " + mimeType + "\r\n\r\n" +
                content +
                closeDelimiter;

            HttpURLConnection conn = createConnection(UPLOAD_API_BASE + "/files?uploadType=multipart", "POST");
            conn.setRequestProperty("Content-Type", "multipart/related; boundary=" + boundary);
            conn.setDoOutput(true);

            try(OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }

            processResponseGeneric(conn, call, "fileId", "id", "webViewLink", "webViewLink");

        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }

    private HttpURLConnection createConnection(String urlStr, String method) throws IOException {
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod(method);
        conn.setRequestProperty("Authorization", "Bearer " + accessToken);
        return conn;
    }

    private String readResponse(HttpURLConnection conn) throws IOException {
        InputStream is = (conn.getResponseCode() >= 200 && conn.getResponseCode() < 300) ? conn.getInputStream() : conn.getErrorStream();
        if (is == null) return "";
        try (BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                response.append(line);
            }
            return response.toString();
        }
    }

    private void processResponse(HttpURLConnection conn, PluginCall call) throws IOException, JSONException {
        String responseStr = readResponse(conn);
        if (conn.getResponseCode() >= 200 && conn.getResponseCode() < 300) {
            JSObject ret = new JSObject(responseStr);
            call.resolve(ret);
        } else {
            call.reject(responseStr);
        }
    }

    private void processResponseGeneric(HttpURLConnection conn, PluginCall call, String... mapping) throws IOException, JSONException {
         String responseStr = readResponse(conn);
        if (conn.getResponseCode() >= 200 && conn.getResponseCode() < 300) {
             JSONObject json = new JSONObject(responseStr);
             JSObject ret = new JSObject();
             for (int i = 0; i < mapping.length; i += 2) {
                 String key = mapping[i];
                 String sourceKey = mapping[i+1];
                 if (json.has(sourceKey)) ret.put(key, json.get(sourceKey));
             }
             call.resolve(ret);
        } else {
            call.reject(responseStr);
        }
    }
}
