import { WebPlugin } from '@capacitor/core';
import type { GoogleDrivePlugin, DriveFile, DriveError } from './definitions';

export class GoogleDriveWeb extends WebPlugin implements GoogleDrivePlugin {
  private accessToken: string | null = null;
  private readonly DRIVE_API_BASE = 'https://www.googleapis.com/drive/v3';
  private readonly UPLOAD_API_BASE = 'https://www.googleapis.com/upload/drive/v3';

  async initialize(options: { accessToken: string }): Promise<{ success: boolean }> {
    if (!options.accessToken) {
      throw this.createError('Access token is required', 'MISSING_TOKEN', 400);
    }

    this.accessToken = options.accessToken;
    return { success: true };
  }

  private createError(message: string, code: string, status: number): DriveError {
    return { message, code, status } as any;
  }

  private async makeRequest(
    url: string,
    options: RequestInit = {}
  ): Promise<Response> {
    if (!this.accessToken) {
      throw this.createError(
        'Plugin not initialized. Call initialize() with an access token first.',
        'NOT_INITIALIZED',
        401
      );
    }

    const response = await fetch(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({
        error: { message: response.statusText },
      }));

      throw this.createError(
        errorData.error?.message || 'Request failed',
        errorData.error?.code || 'UNKNOWN_ERROR',
        response.status
      );
    }

    return response;
  }

  async listFiles(options?: {
    pageSize?: number;
    query?: string;
    orderBy?: string;
    pageToken?: string;
  }): Promise<{ files: DriveFile[]; nextPageToken?: string }> {
    const params = new URLSearchParams({
      pageSize: (options?.pageSize || 100).toString(),
      fields: 'files(id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents),nextPageToken',
    });

    if (options?.query) {
      params.append('q', options.query);
    }
    if (options?.orderBy) {
      params.append('orderBy', options.orderBy);
    }
    if (options?.pageToken) {
      params.append('pageToken', options.pageToken);
    }

    const response = await this.makeRequest(
      `${this.DRIVE_API_BASE}/files?${params}`
    );

    const data = await response.json();
    return {
      files: data.files || [],
      nextPageToken: data.nextPageToken,
    };
  }

  async uploadFile(options: {
    name: string;
    content: string;
    mimeType: string;
    folderId?: string;
  }): Promise<{ fileId: string; webViewLink: string }> {
    const metadata = {
      name: options.name,
      mimeType: options.mimeType,
      ...(options.folderId && { parents: [options.folderId] }),
    };

    // Simple upload for small text files, multipart for others
    // For simplicity in this web impl, we'll assume multipart for everything to handle metadata + content
    const boundary = '-------314159265358979323846';
    const delimiter = `\r\n--${boundary}\r\n`;
    const closeDelimiter = `\r\n--${boundary}--`;

    const body =
      delimiter +
      'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
      JSON.stringify(metadata) +
      delimiter +
      `Content-Type: ${options.mimeType}\r\n\r\n` +
      options.content +
      closeDelimiter;

    const response = await this.makeRequest(
      `${this.UPLOAD_API_BASE}/files?uploadType=multipart`,
      {
        method: 'POST',
        headers: {
          'Content-Type': `multipart/related; boundary=${boundary}`,
        },
        body,
      }
    );

    const data = await response.json();
    return {
      fileId: data.id,
      webViewLink: data.webViewLink,
    };
  }

  async downloadFile(options: { fileId: string }): Promise<{
    content: string;
    name: string;
    mimeType: string;
  }> {
    // 1. Get Metadata
    const metaResponse = await this.makeRequest(
      `${this.DRIVE_API_BASE}/files/${options.fileId}?fields=id,name,mimeType`
    );
    const meta = await metaResponse.json();

    // 2. Get Content
    const contentResponse = await this.makeRequest(
      `${this.DRIVE_API_BASE}/files/${options.fileId}?alt=media`
    );
    const content = await contentResponse.text();

    return {
      content,
      name: meta.name,
      mimeType: meta.mimeType,
    };
  }

  async updateFile(options: {
    fileId: string;
    content: string;
    mimeType: string;
  }): Promise<{ fileId: string; webViewLink: string }> {
    const metadata = {
      mimeType: options.mimeType // Update mimeType if changed, though usually remains same
    };

    const boundary = '-------314159265358979323846';
    const delimiter = `\r\n--${boundary}\r\n`;
    const closeDelimiter = `\r\n--${boundary}--`;

    const body =
      delimiter +
      'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
      JSON.stringify(metadata) +
      delimiter +
      `Content-Type: ${options.mimeType}\r\n\r\n` +
      options.content +
      closeDelimiter;

    const response = await this.makeRequest(
      `${this.UPLOAD_API_BASE}/files/${options.fileId}?uploadType=multipart`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': `multipart/related; boundary=${boundary}`,
        },
        body,
      }
    );

    const data = await response.json();
    return {
      fileId: data.id,
      webViewLink: data.webViewLink,
    };
  }

  async deleteFile(options: { fileId: string }): Promise<{ success: boolean }> {
    await this.makeRequest(`${this.DRIVE_API_BASE}/files/${options.fileId}`, {
      method: 'DELETE',
    });
    return { success: true };
  }

  async createFolder(options: {
    name: string;
    parentFolderId?: string;
  }): Promise<{ folderId: string }> {
    const metadata = {
      name: options.name,
      mimeType: 'application/vnd.google-apps.folder',
      ...(options.parentFolderId && { parents: [options.parentFolderId] }),
    };

    const response = await this.makeRequest(`${this.DRIVE_API_BASE}/files`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(metadata),
    });

    const data = await response.json();
    return { folderId: data.id };
  }

  async getFileMetadata(options: { fileId: string }): Promise<{ file: DriveFile }> {
    const response = await this.makeRequest(
      `${this.DRIVE_API_BASE}/files/${options.fileId}?fields=id,name,mimeType,createdTime,modifiedTime,size,webViewLink,webContentLink,iconLink,thumbnailLink,parents`
    );
    const data = await response.json();
    return { file: data };
  }

  async searchFiles(options: {
    query: string;
    pageSize?: number;
  }): Promise<{ files: DriveFile[] }> {
    return this.listFiles(options);
  }
}
