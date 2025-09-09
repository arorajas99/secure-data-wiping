import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  BackHandler,
  ScrollView,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import * as Progress from 'react-native-progress';
import {DataWipingService, WipingProgress, WipingResult} from '../services/DataWipingService';

interface WipingScreenProps {
  navigation: any;
  route: {
    params: {
      selectedPaths: string[];
      wipingMethod: string;
      totalSize: number;
      estimatedTime: number;
    };
  };
}

const WipingScreen: React.FC<WipingScreenProps> = ({navigation, route}) => {
  const {selectedPaths, wipingMethod, totalSize, estimatedTime} = route.params;
  const [progress, setProgress] = useState<WipingProgress | null>(null);
  const [result, setResult] = useState<WipingResult | null>(null);
  const [isComplete, setIsComplete] = useState(false);
  const [elapsedTime, setElapsedTime] = useState(0);
  const [startTime, setStartTime] = useState<number>(0);

  const wipingService = DataWipingService.getInstance();

  useEffect(() => {
    // Prevent back navigation during wiping
    const backHandler = BackHandler.addEventListener('hardwareBackPress', () => {
      if (!isComplete) {
        handleCancelWiping();
        return true;
      }
      return false;
    });

    startWiping();

    return () => backHandler.remove();
  }, []);

  useEffect(() => {
    if (!isComplete && startTime > 0) {
      const timer = setInterval(() => {
        setElapsedTime(Math.floor((Date.now() - startTime) / 1000));
      }, 1000);

      return () => clearInterval(timer);
    }
  }, [isComplete, startTime]);

  const startWiping = async () => {
    try {
      const start = Date.now();
      setStartTime(start);

      const wipingResult = await wipingService.wipeData(
        {
          method: wipingMethod as any,
          target: '', // Not used for multiple files
          verify: true,
        },
        (progressUpdate) => {
          setProgress(progressUpdate);
        }
      );

      setResult(wipingResult);
      setIsComplete(true);
    } catch (error) {
      Alert.alert(
        'Wiping Failed',
        error.message || 'An error occurred during the wiping process.',
        [
          {
            text: 'OK',
            onPress: () => navigation.goBack(),
          },
        ]
      );
    }
  };

  const handleCancelWiping = () => {
    Alert.alert(
      'Cancel Wiping',
      'Are you sure you want to cancel the wiping process? This may leave data in an inconsistent state.',
      [
        {text: 'Continue Wiping', style: 'cancel'},
        {
          text: 'Cancel',
          style: 'destructive',
          onPress: () => {
            wipingService.cancelWiping();
            navigation.goBack();
          },
        },
      ]
    );
  };

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgressPercentage = (): number => {
    if (!progress) return 0;
    if (progress.totalFiles === 0) return 0;
    return (progress.filesProcessed / progress.totalFiles) * 100;
  };

  const getPassProgressPercentage = (): number => {
    if (!progress) return 0;
    if (progress.totalPasses === 0) return 0;
    return (progress.currentPass / progress.totalPasses) * 100;
  };

  const getBytesProgressPercentage = (): number => {
    if (!progress) return 0;
    if (progress.totalBytes === 0) return 0;
    return (progress.bytesProcessed / progress.totalBytes) * 100;
  };

  const renderWipingInProgress = () => (
    <ScrollView contentContainerStyle={styles.progressContainer}>
      <View style={styles.statusHeader}>
        <Icon name="security" size={60} color="#dc2626" />
        <Text style={styles.statusTitle}>Data Wiping in Progress</Text>
        <Text style={styles.statusSubtitle}>
          Using {wipingMethod.toUpperCase()} method
        </Text>
      </View>

      <View style={styles.progressSection}>
        <View style={styles.progressItem}>
          <Text style={styles.progressLabel}>Overall Progress</Text>
          <Progress.Bar
            progress={getProgressPercentage() / 100}
            width={null}
            height={8}
            color="#dc2626"
            unfilledColor="#e5e7eb"
            borderWidth={0}
            style={styles.progressBar}
          />
          <Text style={styles.progressText}>
            {progress?.filesProcessed || 0} of {progress?.totalFiles || 0} files
          </Text>
        </View>

        <View style={styles.progressItem}>
          <Text style={styles.progressLabel}>Current Pass</Text>
          <Progress.Bar
            progress={getPassProgressPercentage() / 100}
            width={null}
            height={6}
            color="#f59e0b"
            unfilledColor="#e5e7eb"
            borderWidth={0}
            style={styles.progressBar}
          />
          <Text style={styles.progressText}>
            Pass {progress?.currentPass || 0} of {progress?.totalPasses || 0}
          </Text>
        </View>

        <View style={styles.progressItem}>
          <Text style={styles.progressLabel}>Data Processed</Text>
          <Progress.Bar
            progress={getBytesProgressPercentage() / 100}
            width={null}
            height={6}
            color="#059669"
            unfilledColor="#e5e7eb"
            borderWidth={0}
            style={styles.progressBar}
          />
          <Text style={styles.progressText}>
            {((progress?.bytesProcessed || 0) / (1024 * 1024)).toFixed(1)} MB of{' '}
            {((progress?.totalBytes || 0) / (1024 * 1024)).toFixed(1)} MB
          </Text>
        </View>
      </View>

      <View style={styles.currentFileSection}>
        <Text style={styles.currentFileLabel}>Currently Processing:</Text>
        <Text style={styles.currentFileName} numberOfLines={2}>
          {progress?.currentFile || 'Preparing...'}
        </Text>
      </View>

      <View style={styles.timeSection}>
        <View style={styles.timeItem}>
          <Icon name="schedule" size={20} color="#6b7280" />
          <Text style={styles.timeText}>
            Elapsed: {formatTime(elapsedTime)}
          </Text>
        </View>
        
        <View style={styles.timeItem}>
          <Icon name="timer" size={20} color="#6b7280" />
          <Text style={styles.timeText}>
            Estimated: {formatTime(estimatedTime)}
          </Text>
        </View>
      </View>

      <View style={styles.warningBox}>
        <Icon name="warning" size={20} color="#f59e0b" />
        <Text style={styles.warningText}>
          Do not interrupt this process. Interrupting may leave data partially wiped.
        </Text>
      </View>

      <TouchableOpacity style={styles.cancelButton} onPress={handleCancelWiping}>
        <Icon name="cancel" size={20} color="#ef4444" />
        <Text style={styles.cancelButtonText}>Cancel Wiping</Text>
      </TouchableOpacity>
    </ScrollView>
  );

  const renderWipingComplete = () => (
    <ScrollView contentContainerStyle={styles.completionContainer}>
      <View style={styles.statusHeader}>
        <Icon 
          name={result?.success ? "check-circle" : "error"} 
          size={80} 
          color={result?.success ? "#059669" : "#ef4444"} 
        />
        <Text style={[
          styles.statusTitle,
          {color: result?.success ? "#059669" : "#ef4444"}
        ]}>
          {result?.success ? 'Wiping Completed' : 'Wiping Failed'}
        </Text>
        <Text style={styles.statusSubtitle}>
          {result?.success 
            ? 'All selected data has been securely wiped' 
            : 'Some errors occurred during wiping'}
        </Text>
      </View>

      <View style={styles.resultsSection}>
        <View style={styles.resultItem}>
          <Icon name="delete" size={24} color="#059669" />
          <Text style={styles.resultLabel}>Files Wiped</Text>
          <Text style={styles.resultValue}>{result?.filesWiped || 0}</Text>
        </View>

        <View style={styles.resultItem}>
          <Icon name="storage" size={24} color="#059669" />
          <Text style={styles.resultLabel}>Data Wiped</Text>
          <Text style={styles.resultValue}>
            {((result?.bytesWiped || 0) / (1024 * 1024)).toFixed(1)} MB
          </Text>
        </View>

        <View style={styles.resultItem}>
          <Icon name="schedule" size={24} color="#059669" />
          <Text style={styles.resultLabel}>Time Taken</Text>
          <Text style={styles.resultValue}>
            {formatTime(Math.floor((result?.timeElapsed || 0) / 1000))}
          </Text>
        </View>

        <View style={styles.resultItem}>
          <Icon name={result?.verificationPassed ? "verified" : "error"} size={24} color={result?.verificationPassed ? "#059669" : "#ef4444"} />
          <Text style={styles.resultLabel}>Verification</Text>
          <Text style={[
            styles.resultValue,
            {color: result?.verificationPassed ? "#059669" : "#ef4444"}
          ]}>
            {result?.verificationPassed ? "Passed" : "Failed"}
          </Text>
        </View>
      </View>

      {result?.errors && result.errors.length > 0 && (
        <View style={styles.errorsSection}>
          <Text style={styles.errorsTitle}>Errors:</Text>
          {result.errors.map((error, index) => (
            <Text key={index} style={styles.errorText}>
              • {error}
            </Text>
          ))}
        </View>
      )}

      <View style={styles.securityNotice}>
        <Icon name="security" size={20} color="#3b82f6" />
        <Text style={styles.securityText}>
          The wiping process used {wipingMethod.toUpperCase()} standard with cryptographic-grade 
          security. The deleted data cannot be recovered by conventional means.
        </Text>
      </View>

      <TouchableOpacity
        style={styles.doneButton}
        onPress={() => navigation.navigate('Home')}>
        <Icon name="home" size={20} color="#fff" />
        <Text style={styles.doneButtonText}>Return to Home</Text>
      </TouchableOpacity>
    </ScrollView>
  );

  return (
    <View style={styles.container}>
      {!isComplete ? renderWipingInProgress() : renderWipingComplete()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  progressContainer: {
    flexGrow: 1,
    padding: 20,
  },
  completionContainer: {
    flexGrow: 1,
    padding: 20,
  },
  statusHeader: {
    alignItems: 'center',
    marginBottom: 30,
  },
  statusTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
    marginTop: 15,
    textAlign: 'center',
  },
  statusSubtitle: {
    fontSize: 16,
    color: '#6b7280',
    marginTop: 5,
    textAlign: 'center',
  },
  progressSection: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  progressItem: {
    marginBottom: 20,
  },
  progressLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 8,
  },
  progressBar: {
    marginBottom: 5,
  },
  progressText: {
    fontSize: 12,
    color: '#6b7280',
  },
  currentFileSection: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  currentFileLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 8,
  },
  currentFileName: {
    fontSize: 12,
    color: '#6b7280',
    fontFamily: 'monospace',
  },
  timeSection: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  timeItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeText: {
    fontSize: 14,
    color: '#1f2937',
    marginLeft: 5,
    fontWeight: '500',
  },
  warningBox: {
    flexDirection: 'row',
    backgroundColor: '#fef3c7',
    borderRadius: 8,
    padding: 15,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#fbbf24',
    alignItems: 'flex-start',
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    color: '#92400e',
    marginLeft: 10,
    lineHeight: 20,
  },
  cancelButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fee2e2',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#fecaca',
  },
  cancelButtonText: {
    fontSize: 16,
    color: '#ef4444',
    marginLeft: 8,
    fontWeight: '500',
  },
  resultsSection: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  resultItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f3f4f6',
  },
  resultLabel: {
    flex: 1,
    fontSize: 16,
    color: '#1f2937',
    marginLeft: 12,
  },
  resultValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
  },
  errorsSection: {
    backgroundColor: '#fef2f2',
    borderRadius: 8,
    padding: 15,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#fecaca',
  },
  errorsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#dc2626',
    marginBottom: 10,
  },
  errorText: {
    fontSize: 14,
    color: '#7f1d1d',
    marginBottom: 5,
    lineHeight: 18,
  },
  securityNotice: {
    flexDirection: 'row',
    backgroundColor: '#eff6ff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#bfdbfe',
    alignItems: 'flex-start',
  },
  securityText: {
    flex: 1,
    fontSize: 13,
    color: '#1e40af',
    marginLeft: 10,
    lineHeight: 18,
  },
  doneButton: {
    backgroundColor: '#059669',
    padding: 15,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  doneButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
});

export default WipingScreen;
