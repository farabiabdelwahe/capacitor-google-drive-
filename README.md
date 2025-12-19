# capacitor-google-drive

Google Drive integration for Capacitor - backup and sync files to Google Drive on Android, iOS, and Web.

## Install

```bash
npm install capacitor-google-drive
npx cap sync
```

## Platform Support

| Feature | Android | iOS | Web |
|---------|:-------:|:---:|:---:|
| initialize | ✅ | ✅ | ✅ |
| listFiles | ✅ | ✅ | ✅ |
| uploadFile | ✅ | ✅ | ✅ |
| downloadFile | ✅ | ✅ | ✅ |
| updateFile | ✅ | ✅ | ✅ |
| deleteFile | ✅ | ✅ | ✅ |
| createFolder | ✅ | ✅ | ✅ |
| getFileMetadata | ✅ | ✅ | ✅ |
| searchFiles | ✅ | ✅ | ✅ |

## Configuration & Authentication

**Important:** This plugin does **not** handle the OAuth 2.0 login flow. You must obtain a valid **OAuth2 Access Token** with appropriate Google Drive scopes before using this plugin.

Use a separate authentication plugin (like `@capacitor-firebase/authentication`, `@codetrix-studio/capacitor-google-auth`, or similar) to obtain the access token.

### Required Scopes

Ensure your auth flow requests one of these scopes:
- `https://www.googleapis.com/auth/drive` (Full access)
- `https://www.googleapis.com/auth/drive.file` (Access to files created by the app)

## Usage Examples

### Initialize

Before calling any API methods, you **must** initialize the plugin with an access token:

```typescript
import { GoogleDrive } from 'capacitor-google-drive';

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

### List Files

```typescript
const listFiles = async () => {
  const response = await GoogleDrive.listFiles({
    pageSize: 10,
    query: "mimeType = 'application/vnd.google-apps.folder'",
    orderBy: "modifiedTime desc"
  });
  
  response.files.forEach(file => {
    console.log(`File: ${file.name} (${file.id})`);
  });
};
```

### Create a Folder

```typescript
const createFolder = async (folderName: string) => {
  const result = await GoogleDrive.createFolder({
    name: folderName,
    // parentFolderId: 'parent_id' // Optional
  });
  console.log('Created Folder ID:', result.folderId);
};
```

### Upload a File

```typescript
const uploadFile = async () => {
  const result = await GoogleDrive.uploadFile({
    name: 'backup.json',
    content: JSON.stringify({ data: 'my data' }),
    mimeType: 'application/json',
    folderId: 'optional_folder_id'
  });
  
  console.log('Uploaded File ID:', result.fileId);
};
```

### Download a File

```typescript
const downloadFile = async (fileId: string) => {
  const result = await GoogleDrive.downloadFile({ fileId });
  console.log('File name:', result.name);
  console.log('Content:', result.content);
};
```

### Update a File

```typescript
const updateFile = async (fileId: string, newContent: string) => {
  const result = await GoogleDrive.updateFile({
    fileId,
    content: newContent,
    mimeType: 'application/json'
  });
  console.log('Updated File ID:', result.fileId);
};
```

### Delete a File

```typescript
const deleteFile = async (fileId: string) => {
  const result = await GoogleDrive.deleteFile({ fileId });
  console.log('Deleted:', result.success);
};
```

### Search Files

```typescript
const searchFiles = async (searchQuery: string) => {
  const result = await GoogleDrive.searchFiles({
    query: `name contains '${searchQuery}'`,
    pageSize: 20
  });
  console.log('Found files:', result.files);
};
```

## Complete Backup Service Example

Here's a complete example of a backup service using this plugin:

```typescript
import { GoogleDrive } from 'capacitor-google-drive';

const APP_FOLDER_NAME = 'My App Backup';
const BACKUP_FILE_NAME = 'backup.json';

class BackupService {
  private appFolderId: string | null = null;

  async initialize(accessToken: string) {
    await GoogleDrive.initialize({ accessToken });
  }

  async ensureAppFolder(): Promise<string> {
    // Find existing folder
    const response = await GoogleDrive.listFiles({
      query: `name = '${APP_FOLDER_NAME}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false`,
    });

    if (response.files.length > 0) {
      this.appFolderId = response.files[0].id;
      return this.appFolderId;
    }

    // Create new folder
    const result = await GoogleDrive.createFolder({ name: APP_FOLDER_NAME });
    this.appFolderId = result.folderId;
    return this.appFolderId;
  }

  async backup(data: any) {
    await this.ensureAppFolder();
    
    await GoogleDrive.uploadFile({
      name: BACKUP_FILE_NAME,
      content: JSON.stringify(data),
      mimeType: 'application/json',
      folderId: this.appFolderId!,
    });
  }

  async restore(): Promise<any | null> {
    await this.ensureAppFolder();

    const response = await GoogleDrive.listFiles({
      query: `name = '${BACKUP_FILE_NAME}' and '${this.appFolderId}' in parents and trashed = false`,
    });

    if (response.files.length === 0) return null;

    const result = await GoogleDrive.downloadFile({ fileId: response.files[0].id });
    return JSON.parse(result.content);
  }
}
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

## License

MIT
