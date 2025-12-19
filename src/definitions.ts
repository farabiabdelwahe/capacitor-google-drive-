export interface GoogleDrivePlugin {
  /**
   * Initialize the plugin with Firebase OAuth access token
   */
  initialize(options: { accessToken: string }): Promise<{ success: boolean }>;

  /**
   * List files from Google Drive
   */
  listFiles(options?: {
    pageSize?: number;
    query?: string;
    orderBy?: string;
    pageToken?: string;
  }): Promise<{
    files: DriveFile[];
    nextPageToken?: string;
  }>;

  /**
   * Upload a file to Google Drive
   */
  uploadFile(options: {
    name: string;
    content: string;
    mimeType: string;
    folderId?: string;
  }): Promise<{
    fileId: string;
    webViewLink: string;
  }>;

  /**
   * Download a file from Google Drive
   */
  downloadFile(options: {
    fileId: string;
  }): Promise<{
    content: string;
    name: string;
    mimeType: string;
  }>;

  /**
   * Update an existing file
   */
  updateFile(options: {
    fileId: string;
    content: string;
    mimeType: string;
  }): Promise<{
    fileId: string;
    webViewLink: string;
  }>;

  /**
   * Delete a file from Google Drive
   */
  deleteFile(options: {
    fileId: string;
  }): Promise<{ success: boolean }>;

  /**
   * Create a folder in Google Drive
   */
  createFolder(options: {
    name: string;
    parentFolderId?: string;
  }): Promise<{ folderId: string }>;

  /**
   * Get file metadata
   */
  getFileMetadata(options: {
    fileId: string;
  }): Promise<{ file: DriveFile }>;

  /**
   * Search for files
   */
  searchFiles(options: {
    query: string;
    pageSize?: number;
  }): Promise<{ files: DriveFile[] }>;
}

export interface DriveFile {
  id: string;
  name: string;
  mimeType: string;
  createdTime: string;
  modifiedTime: string;
  size?: string;
  webViewLink?: string;
  webContentLink?: string;
  iconLink?: string;
  thumbnailLink?: string;
  parents?: string[];
}

export interface DriveError {
  code: string;
  message: string;
  status: number;
}
