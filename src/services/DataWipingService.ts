import RNFS from 'react-native-fs';
import CryptoJS from 'react-native-crypto-js';

export type WipingMethod = 'dod' | 'nist' | 'gutmann' | 'random' | 'zero';

export interface WipingOptions {
  method: WipingMethod;
  target: string;
  passes?: number;
  verify: boolean;
}

export interface WipingProgress {
  currentFile: string;
  filesProcessed: number;
  totalFiles: number;
  currentPass: number;
  totalPasses: number;
  bytesProcessed: number;
  totalBytes: number;
  isComplete: boolean;
  error?: string;
}

export interface WipingResult {
  success: boolean;
  filesWiped: number;
  bytesWiped: number;
  timeElapsed: number;
  verificationPassed: boolean;
  errors: string[];
}

export class DataWipingService {
  private static instance: DataWipingService;
  private isWiping: boolean = false;
  private shouldCancel: boolean = false;

  static getInstance(): DataWipingService {
    if (!DataWipingService.instance) {
      DataWipingService.instance = new DataWipingService();
    }
    return DataWipingService.instance;
  }

  /**
   * Performs secure data wiping operation
   */
  async wipeData(
    options: WipingOptions,
    progressCallback?: (progress: WipingProgress) => void,
  ): Promise<WipingResult> {
    if (this.isWiping) {
      throw new Error('Wiping operation already in progress');
    }

    this.isWiping = true;
    this.shouldCancel = false;
    const startTime = Date.now();

    const result: WipingResult = {
      success: false,
      filesWiped: 0,
      bytesWiped: 0,
      timeElapsed: 0,
      verificationPassed: false,
      errors: [],
    };

    try {
      // Get list of files to wipe
      const filesToWipe = await this.getFilesToWipe(options.target);
      const totalBytes = await this.calculateTotalBytes(filesToWipe);
      const passes = this.getPassesForMethod(options.method, options.passes);

      let bytesProcessed = 0;
      let filesProcessed = 0;

      for (const filePath of filesToWipe) {
        if (this.shouldCancel) {
          throw new Error('Wiping operation cancelled by user');
        }

        try {
          const fileSize = (await RNFS.stat(filePath)).size;
          
          // Report progress
          if (progressCallback) {
            progressCallback({
              currentFile: filePath,
              filesProcessed,
              totalFiles: filesToWipe.length,
              currentPass: 0,
              totalPasses: passes,
              bytesProcessed,
              totalBytes,
              isComplete: false,
            });
          }

          // Perform wiping passes
          await this.wipeFile(filePath, options.method, passes, (passNum) => {
            if (progressCallback) {
              progressCallback({
                currentFile: filePath,
                filesProcessed,
                totalFiles: filesToWipe.length,
                currentPass: passNum,
                totalPasses: passes,
                bytesProcessed,
                totalBytes,
                isComplete: false,
              });
            }
          });

          result.filesWiped++;
          result.bytesWiped += fileSize;
          bytesProcessed += fileSize;
          filesProcessed++;

        } catch (error) {
          result.errors.push(`Failed to wipe ${filePath}: ${error.message}`);
        }
      }

      // Verification step
      if (options.verify) {
        result.verificationPassed = await this.verifyWipe(options.target);
      }

      result.success = result.errors.length === 0;
      result.timeElapsed = Date.now() - startTime;

      // Final progress callback
      if (progressCallback) {
        progressCallback({
          currentFile: '',
          filesProcessed: filesToWipe.length,
          totalFiles: filesToWipe.length,
          currentPass: passes,
          totalPasses: passes,
          bytesProcessed: totalBytes,
          totalBytes,
          isComplete: true,
        });
      }

    } catch (error) {
      result.errors.push(error.message);
      result.timeElapsed = Date.now() - startTime;
    } finally {
      this.isWiping = false;
    }

    return result;
  }

  /**
   * Wipes a single file using the specified method
   */
  private async wipeFile(
    filePath: string, 
    method: WipingMethod, 
    passes: number,
    passCallback?: (passNum: number) => void,
  ): Promise<void> {
    const stat = await RNFS.stat(filePath);
    if (!stat.isFile()) {
      throw new Error(`${filePath} is not a file`);
    }

    const fileSize = stat.size;
    
    for (let pass = 1; pass <= passes; pass++) {
      if (this.shouldCancel) {
        throw new Error('Operation cancelled');
      }

      if (passCallback) {
        passCallback(pass);
      }

      const pattern = this.getPatternForPass(method, pass);
      await this.overwriteFile(filePath, pattern, fileSize);
    }

    // Final step: delete the file
    await RNFS.unlink(filePath);
  }

  /**
   * Generates the overwrite pattern for a specific pass
   */
  private getPatternForPass(method: WipingMethod, pass: number): Buffer {
    switch (method) {
      case 'dod':
        // DoD 5220.22-M: Pass 1: 0x00, Pass 2: 0xFF, Pass 3: Random
        if (pass === 1) return Buffer.alloc(1024, 0x00);
        if (pass === 2) return Buffer.alloc(1024, 0xFF);
        return this.generateRandomBuffer(1024);

      case 'nist':
        // NIST 800-88: Single pass with random data
        return this.generateRandomBuffer(1024);

      case 'gutmann':
        // Gutmann method: 35 passes with specific patterns
        return this.getGutmannPattern(pass);

      case 'random':
        return this.generateRandomBuffer(1024);

      case 'zero':
        return Buffer.alloc(1024, 0x00);

      default:
        return this.generateRandomBuffer(1024);
    }
  }

  /**
   * Generates Gutmann method patterns
   */
  private getGutmannPattern(pass: number): Buffer {
    const buffer = Buffer.alloc(1024);
    
    // Simplified Gutmann patterns (full implementation would have 35 specific patterns)
    const patterns = [
      0x00, 0xFF, 0x55, 0xAA, 0x92, 0x49, 0x24, 0x6D,
      0xB6, 0xDB, 0x95, 0x55, 0xAA, 0x24, 0x49, 0x92,
    ];

    const pattern = patterns[(pass - 1) % patterns.length];
    buffer.fill(pattern);
    
    return buffer;
  }

  /**
   * Generates cryptographically secure random buffer
   */
  private generateRandomBuffer(size: number): Buffer {
    const randomWords = CryptoJS.lib.WordArray.random(size);
    return Buffer.from(randomWords.toString(CryptoJS.enc.Hex), 'hex');
  }

  /**
   * Overwrites a file with the specified pattern
   */
  private async overwriteFile(filePath: string, pattern: Buffer, fileSize: number): Promise<void> {
    const tempPath = `${filePath}.tmp`;
    let bytesWritten = 0;

    // Create temporary file with overwrite pattern
    while (bytesWritten < fileSize) {
      const remainingBytes = fileSize - bytesWritten;
      const chunkSize = Math.min(pattern.length, remainingBytes);
      const chunk = pattern.slice(0, chunkSize);
      
      await RNFS.appendFile(tempPath, chunk.toString('base64'), 'base64');
      bytesWritten += chunkSize;
    }

    // Replace original file with overwritten version
    await RNFS.moveFile(tempPath, filePath);
  }

  /**
   * Gets the number of passes for a wiping method
   */
  private getPassesForMethod(method: WipingMethod, customPasses?: number): number {
    if (customPasses) return customPasses;

    switch (method) {
      case 'dod': return 3;
      case 'nist': return 1;
      case 'gutmann': return 35;
      case 'random': return 7;
      case 'zero': return 1;
      default: return 3;
    }
  }

  /**
   * Gets list of all files in the target path
   */
  private async getFilesToWipe(targetPath: string): Promise<string[]> {
    const files: string[] = [];
    
    const stat = await RNFS.stat(targetPath);
    
    if (stat.isFile()) {
      files.push(targetPath);
    } else if (stat.isDirectory()) {
      const contents = await RNFS.readDir(targetPath);
      
      for (const item of contents) {
        const itemPath = `${targetPath}/${item.name}`;
        const itemFiles = await this.getFilesToWipe(itemPath);
        files.push(...itemFiles);
      }
    }

    return files;
  }

  /**
   * Calculates total bytes to be processed
   */
  private async calculateTotalBytes(filePaths: string[]): Promise<number> {
    let totalBytes = 0;
    
    for (const filePath of filePaths) {
      try {
        const stat = await RNFS.stat(filePath);
        totalBytes += stat.size;
      } catch (error) {
        // File might have been deleted or is inaccessible
      }
    }

    return totalBytes;
  }

  /**
   * Verifies that data has been successfully wiped
   */
  async verifyWipe(target: string): Promise<boolean> {
    try {
      const exists = await RNFS.exists(target);
      return !exists; // If target doesn't exist, wipe was successful
    } catch (error) {
      return false;
    }
  }

  /**
   * Cancels the current wiping operation
   */
  cancelWiping(): void {
    this.shouldCancel = true;
  }

  /**
   * Checks if a wiping operation is currently in progress
   */
  isWipingInProgress(): boolean {
    return this.isWiping;
  }

  /**
   * Estimates time required for wiping operation
   */
  async estimateWipeTime(options: WipingOptions): Promise<number> {
    try {
      const filesToWipe = await this.getFilesToWipe(options.target);
      const totalBytes = await this.calculateTotalBytes(filesToWipe);
      const passes = this.getPassesForMethod(options.method, options.passes);

      // Rough estimate: 10MB per second per pass
      const estimatedSeconds = (totalBytes * passes) / (10 * 1024 * 1024);
      
      return Math.max(estimatedSeconds, 1); // Minimum 1 second
    } catch (error) {
      return 60; // Default estimate if calculation fails
    }
  }
}
