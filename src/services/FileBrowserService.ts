import RNFS from 'react-native-fs';

export interface FileItem {
  name: string;
  path: string;
  isDirectory: boolean;
  size: number;
  modificationTime: number;
  isSelected: boolean;
  isProtected: boolean; // System files that shouldn't be deleted
  children?: FileItem[];
}

export interface BrowserState {
  currentPath: string;
  items: FileItem[];
  selectedItems: Set<string>;
  protectedPaths: Set<string>;
}

export class FileBrowserService {
  private static instance: FileBrowserService;
  private protectedPaths: Set<string> = new Set([
    '/system',
    '/data/system',
    '/proc',
    '/sys',
    '/dev',
    '/vendor',
    '/boot',
  ]);

  static getInstance(): FileBrowserService {
    if (!FileBrowserService.instance) {
      FileBrowserService.instance = new FileBrowserService();
    }
    return FileBrowserService.instance;
  }

  /**
   * Browse directory and return file/folder list
   */
  async browseDirectory(path: string): Promise<FileItem[]> {
    try {
      const exists = await RNFS.exists(path);
      if (!exists) {
        throw new Error(`Path does not exist: ${path}`);
      }

      const stat = await RNFS.stat(path);
      if (!stat.isDirectory()) {
        throw new Error(`Path is not a directory: ${path}`);
      }

      const items = await RNFS.readDir(path);
      const fileItems: FileItem[] = [];

      for (const item of items) {
        try {
          const itemPath = `${path}/${item.name}`;
          const itemStat = await RNFS.stat(itemPath);
          
          const fileItem: FileItem = {
            name: item.name,
            path: itemPath,
            isDirectory: itemStat.isDirectory(),
            size: itemStat.size,
            modificationTime: itemStat.mtime?.getTime() || 0,
            isSelected: false,
            isProtected: this.isProtectedPath(itemPath),
          };

          fileItems.push(fileItem);
        } catch (error) {
          // Skip items we can't access
          console.warn(`Cannot access item: ${item.name}`, error);
        }
      }

      // Sort: directories first, then files, both alphabetically
      return fileItems.sort((a, b) => {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
      });

    } catch (error) {
      console.error('Error browsing directory:', error);
      throw error;
    }
  }

  /**
   * Get directory tree for hierarchical selection
   */
  async getDirectoryTree(rootPath: string, maxDepth: number = 3): Promise<FileItem> {
    const rootStat = await RNFS.stat(rootPath);
    
    const rootItem: FileItem = {
      name: rootPath.split('/').pop() || rootPath,
      path: rootPath,
      isDirectory: rootStat.isDirectory(),
      size: rootStat.size,
      modificationTime: rootStat.mtime?.getTime() || 0,
      isSelected: false,
      isProtected: this.isProtectedPath(rootPath),
      children: [],
    };

    if (rootItem.isDirectory && maxDepth > 0) {
      try {
        const children = await this.browseDirectory(rootPath);
        rootItem.children = [];

        for (const child of children) {
          if (child.isDirectory) {
            const childTree = await this.getDirectoryTree(child.path, maxDepth - 1);
            rootItem.children.push(childTree);
          } else {
            rootItem.children.push(child);
          }
        }
      } catch (error) {
        // Directory not accessible, leave children empty
      }
    }

    return rootItem;
  }

  /**
   * Calculate total size of selected items
   */
  async calculateSelectedSize(selectedPaths: string[]): Promise<number> {
    let totalSize = 0;

    for (const path of selectedPaths) {
      try {
        const size = await this.calculatePathSize(path);
        totalSize += size;
      } catch (error) {
        console.warn(`Cannot calculate size for ${path}:`, error);
      }
    }

    return totalSize;
  }

  /**
   * Calculate size of a path (file or directory)
   */
  private async calculatePathSize(path: string): Promise<number> {
    try {
      const stat = await RNFS.stat(path);
      
      if (stat.isFile()) {
        return stat.size;
      } else if (stat.isDirectory()) {
        let totalSize = 0;
        const items = await RNFS.readDir(path);
        
        for (const item of items) {
          const itemPath = `${path}/${item.name}`;
          totalSize += await this.calculatePathSize(itemPath);
        }
        
        return totalSize;
      }
    } catch (error) {
      // Path not accessible
      return 0;
    }
    
    return 0;
  }

  /**
   * Get list of files to be wiped based on selection
   */
  async getFilesToWipe(selectedPaths: string[]): Promise<string[]> {
    const allFiles: string[] = [];

    for (const path of selectedPaths) {
      const files = await this.expandPathToFiles(path);
      allFiles.push(...files);
    }

    // Remove duplicates and filter out protected files
    const uniqueFiles = Array.from(new Set(allFiles));
    return uniqueFiles.filter(file => !this.isProtectedPath(file));
  }

  /**
   * Expand a path to all files it contains
   */
  private async expandPathToFiles(path: string): Promise<string[]> {
    const files: string[] = [];
    
    try {
      const stat = await RNFS.stat(path);
      
      if (stat.isFile()) {
        files.push(path);
      } else if (stat.isDirectory()) {
        const items = await RNFS.readDir(path);
        
        for (const item of items) {
          const itemPath = `${path}/${item.name}`;
          const itemFiles = await this.expandPathToFiles(itemPath);
          files.push(...itemFiles);
        }
      }
    } catch (error) {
      // Path not accessible, skip
    }

    return files;
  }

  /**
   * Check if a path is protected (system files that shouldn't be deleted)
   */
  private isProtectedPath(path: string): boolean {
    const normalizedPath = path.toLowerCase();
    
    for (const protectedPath of this.protectedPaths) {
      if (normalizedPath.startsWith(protectedPath.toLowerCase())) {
        return true;
      }
    }

    // Additional protection patterns
    const protectedPatterns = [
      /\/system\//,
      /\/vendor\//,
      /\/boot\//,
      /\/proc\//,
      /\/sys\//,
      /\/dev\//,
      /\.so$/,
      /\.apk$/,
    ];

    return protectedPatterns.some(pattern => pattern.test(normalizedPath));
  }

  /**
   * Get safe paths for user data wiping
   */
  getSafePaths(): string[] {
    return [
      RNFS.DocumentDirectoryPath,
      RNFS.CachesDirectoryPath,
      RNFS.DownloadDirectoryPath,
      RNFS.PicturesDirectoryPath,
      RNFS.MoviesDirectoryPath,
      RNFS.MusicDirectoryPath,
    ].filter(path => path !== null);
  }

  /**
   * Format file size for display
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Get file extension
   */
  getFileExtension(fileName: string): string {
    const lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(lastDot + 1).toLowerCase() : '';
  }

  /**
   * Get file type category
   */
  getFileType(fileName: string): 'document' | 'image' | 'video' | 'audio' | 'archive' | 'other' {
    const extension = this.getFileExtension(fileName);
    
    const documentExtensions = ['txt', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv'];
    const audioExtensions = ['mp3', 'wav', 'flac', 'aac', 'ogg'];
    const archiveExtensions = ['zip', 'rar', '7z', 'tar', 'gz'];

    if (documentExtensions.includes(extension)) return 'document';
    if (imageExtensions.includes(extension)) return 'image';
    if (videoExtensions.includes(extension)) return 'video';
    if (audioExtensions.includes(extension)) return 'audio';
    if (archiveExtensions.includes(extension)) return 'archive';
    
    return 'other';
  }

  /**
   * Add custom protected path
   */
  addProtectedPath(path: string): void {
    this.protectedPaths.add(path);
  }

  /**
   * Remove custom protected path
   */
  removeProtectedPath(path: string): void {
    this.protectedPaths.delete(path);
  }

  /**
   * Get all protected paths
   */
  getProtectedPaths(): string[] {
    return Array.from(this.protectedPaths);
  }
}
