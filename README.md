# ccapacitor-google-drive

Google Drive integration for Capacitor

## Install

```bash
npm install ccapacitor-google-drive
npx cap sync
```

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`listFiles(...)`](#listfiles)
* [`uploadFile(...)`](#uploadfile)
* [`downloadFile(...)`](#downloadfile)
* [`updateFile(...)`](#updatefile)
* [`deleteFile(...)`](#deletefile)
* [`createFolder(...)`](#createfolder)
* [`getFileMetadata(...)`](#getfilemetadata)
* [`searchFiles(...)`](#searchfiles)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initialize(...)

```typescript
initialize(options: { accessToken: string; }) => Promise<{ success: boolean; }>
```

Initialize the plugin with Firebase OAuth access token

| Param         | Type                                  |
| ------------- | ------------------------------------- |
| **`options`** | <code>{ accessToken: string; }</code> |

**Returns:** <code>Promise&lt;{ success: boolean; }&gt;</code>

--------------------


### listFiles(...)

```typescript
listFiles(options?: { pageSize?: number | undefined; query?: string | undefined; orderBy?: string | undefined; pageToken?: string | undefined; } | undefined) => Promise<{ files: DriveFile[]; nextPageToken?: string; }>
```

List files from Google Drive

| Param         | Type                                                                                      |
| ------------- | ----------------------------------------------------------------------------------------- |
| **`options`** | <code>{ pageSize?: number; query?: string; orderBy?: string; pageToken?: string; }</code> |

**Returns:** <code>Promise&lt;{ files: DriveFile[]; nextPageToken?: string; }&gt;</code>

--------------------


### uploadFile(...)

```typescript
uploadFile(options: { name: string; content: string; mimeType: string; folderId?: string; }) => Promise<{ fileId: string; webViewLink: string; }>
```

Upload a file to Google Drive

| Param         | Type                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| **`options`** | <code>{ name: string; content: string; mimeType: string; folderId?: string; }</code> |

**Returns:** <code>Promise&lt;{ fileId: string; webViewLink: string; }&gt;</code>

--------------------


### downloadFile(...)

```typescript
downloadFile(options: { fileId: string; }) => Promise<{ content: string; name: string; mimeType: string; }>
```

Download a file from Google Drive

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ fileId: string; }</code> |

**Returns:** <code>Promise&lt;{ content: string; name: string; mimeType: string; }&gt;</code>

--------------------


### updateFile(...)

```typescript
updateFile(options: { fileId: string; content: string; mimeType: string; }) => Promise<{ fileId: string; webViewLink: string; }>
```

Update an existing file

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code>{ fileId: string; content: string; mimeType: string; }</code> |

**Returns:** <code>Promise&lt;{ fileId: string; webViewLink: string; }&gt;</code>

--------------------


### deleteFile(...)

```typescript
deleteFile(options: { fileId: string; }) => Promise<{ success: boolean; }>
```

Delete a file from Google Drive

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ fileId: string; }</code> |

**Returns:** <code>Promise&lt;{ success: boolean; }&gt;</code>

--------------------


### createFolder(...)

```typescript
createFolder(options: { name: string; parentFolderId?: string; }) => Promise<{ folderId: string; }>
```

Create a folder in Google Drive

| Param         | Type                                                    |
| ------------- | ------------------------------------------------------- |
| **`options`** | <code>{ name: string; parentFolderId?: string; }</code> |

**Returns:** <code>Promise&lt;{ folderId: string; }&gt;</code>

--------------------


### getFileMetadata(...)

```typescript
getFileMetadata(options: { fileId: string; }) => Promise<{ file: DriveFile; }>
```

Get file metadata

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ fileId: string; }</code> |

**Returns:** <code>Promise&lt;{ file: <a href="#drivefile">DriveFile</a>; }&gt;</code>

--------------------


### searchFiles(...)

```typescript
searchFiles(options: { query: string; pageSize?: number; }) => Promise<{ files: DriveFile[]; }>
```

Search for files

| Param         | Type                                               |
| ------------- | -------------------------------------------------- |
| **`options`** | <code>{ query: string; pageSize?: number; }</code> |

**Returns:** <code>Promise&lt;{ files: DriveFile[]; }&gt;</code>

--------------------


### Interfaces


#### DriveFile

| Prop                 | Type                  |
| -------------------- | --------------------- |
| **`id`**             | <code>string</code>   |
| **`name`**           | <code>string</code>   |
| **`mimeType`**       | <code>string</code>   |
| **`createdTime`**    | <code>string</code>   |
| **`modifiedTime`**   | <code>string</code>   |
| **`size`**           | <code>string</code>   |
| **`webViewLink`**    | <code>string</code>   |
| **`webContentLink`** | <code>string</code>   |
| **`iconLink`**       | <code>string</code>   |
| **`thumbnailLink`**  | <code>string</code>   |
| **`parents`**        | <code>string[]</code> |

</docgen-api>
