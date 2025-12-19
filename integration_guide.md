# Capacitor Google Drive Plugin Integration Guide

This guide provides a comprehensive step-by-step instruction set for integrating the `capacitor-google-drive` plugin into a Capacitor project. It is designed to be clear and structured, making it suitable for providing context to an AI assistant.

## 1. Installation

First, install the package from npm.

```bash
npm install capacitor-google-drive
npx cap sync
```

> **Note:** Verify the exact package name on npm. If it was published with a typo (e.g., `ccapacitor-google-drive`), use that name instead.

## 2. Platform Usage

This plugin works on **Android**, **iOS**, and **Web**.
- **Web**: Fully supported.
- **Android/iOS**: Native implementation provided for core features.

## 3. Configuration & Authentication

**Crucial Step:** This plugin **does not** handle the OAuth 2.0 Login flow itself. It requires a valid **OAuth2 Access Token** with appropriate Google Drive scopes (e.g., `https://www.googleapis.com/auth/drive`).

You must use a separate plugin (like `capacitor-firebase-auth`, `@codetrix-studio/capacitor-google-auth`, or generic OAuth providers) to obtain the `accessToken` before using this plugin.

### Required Scopes
Ensure your auth flow requests:
- `https://www.googleapis.com/auth/drive` (Full access)
- Or specific scopes like `https://www.googleapis.com/auth/drive.file` depending on your needs.

## 4. Initialization

Before calling any API methods, you **must** initialize the plugin with the access token.

```typescript
import { GoogleDrive } from 'capacitor-google-drive';

// Example: Initialize with a token obtained from your Auth provider
const initializeDrive = async (accessToken: string) => {
  try {
    const result = await GoogleDrive.initialize({ accessToken });
    if (result.success) {
      console.log('Google Drive Plugin initialized successfully');
    }
  } catch (error) {
    console.error('Failed to initialize Google Drive:', error);
  }
};
```

## 5. API Usage Examples

Here are examples of how to use the core methods.

### List Files

```typescript
const listFiles = async () => {
  try {
    const response = await GoogleDrive.listFiles({
      pageSize: 10,
      query: "mimeType = 'application/vnd.google-apps.folder'", // Optional: Filter query
      orderBy: "modifiedTime desc" // Optional: Sort order
    });
    
    response.files.forEach(file => {
      console.log(`File: ${file.name} (${file.id})`);
    });
    
    if (response.nextPageToken) {
      console.log('Next page token:', response.nextPageToken);
    }
  } catch (error) {
    console.error('Error listing files:', error);
  }
};
```

### Upload a File

```typescript
const uploadFile = async () => {
  try {
    const result = await GoogleDrive.uploadFile({
      name: 'my_document.txt',
      content: 'Hello World', // File content (text or base64 depending on implementation context)
      mimeType: 'text/plain',
      // folderId: 'parent_folder_id' // Optional: Upload to a specific folder
    });
    
    console.log('Uploaded File ID:', result.fileId);
    console.log('Web Link:', result.webViewLink);
  } catch (error) {
    console.error('Upload failed:', error);
  }
};
```

### Create a Folder (Web Only / Fallback)
*Note: Ensure platform support for this method.*

```typescript
const createFolder = async (folderName: string) => {
  try {
    const result = await GoogleDrive.createFolder({
      name: folderName,
      // parentFolderId: 'parent_id' // Optional
    });
    console.log('Created Folder ID:', result.folderId);
  } catch (error) {
    console.error('Create folder failed:', error);
  }
};
```

### Get File Metadata

```typescript
const getMetadata = async (fileId: string) => {
  try {
    const result = await GoogleDrive.getFileMetadata({ fileId });
    console.log('Metadata:', result.file);
  } catch (error) {
    console.error('Error fetching metadata:', error);
  }
};
```

### Download File (Web only currently)

```typescript
const downloadFile = async (fileId: string) => {
  try {
    const result = await GoogleDrive.downloadFile({ fileId });
    console.log('Content:', result.content);
  } catch (error) {
    console.error('Download failed:', error);
  }
};
```

## 6. Prompting AI

To ask an AI to use this plugin, you can paste the following context:

> "I am using the `capacitor-google-drive` plugin. It has an API that requires initialization with an OAuth Access Token.
> The main class is `GoogleDrive`.
> Methods:
> - `initialize({ accessToken: string })`
> - `listFiles({ pageSize, query, orderBy, pageToken })`
> - `uploadFile({ name, content, mimeType, folderId })`
> - `getFileMetadata({ fileId })`
> 
> Please write a function to [YOUR GOAL, e.g., 'upload a text file to a specific folder'] using this plugin."
