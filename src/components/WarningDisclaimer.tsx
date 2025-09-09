import React, {useState} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Modal,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';

interface WarningDisclaimerProps {
  visible: boolean;
  onAccept: () => void;
  onCancel: () => void;
  wipingMethod: string;
  selectedItemsCount: number;
  estimatedTime: number;
  totalSize: string;
}

const WarningDisclaimer: React.FC<WarningDisclaimerProps> = ({
  visible,
  onAccept,
  onCancel,
  wipingMethod,
  selectedItemsCount,
  estimatedTime,
  totalSize,
}) => {
  const [acceptedWarnings, setAcceptedWarnings] = useState<Set<string>>(new Set());
  const [finalConfirmation, setFinalConfirmation] = useState(false);

  const warnings = [
    {
      id: 'irreversible',
      title: 'IRREVERSIBLE DATA LOSS',
      description: 'All selected data will be PERMANENTLY DELETED and CANNOT BE RECOVERED by any means.',
      icon: 'warning',
      color: '#dc2626',
    },
    {
      id: 'no_backup',
      title: 'NO RECOVERY POSSIBLE',
      description: 'This process uses military-grade wiping algorithms that make data recovery impossible.',
      icon: 'delete-forever',
      color: '#dc2626',
    },
    {
      id: 'system_impact',
      title: 'DEVICE FUNCTIONALITY RISK',
      description: 'Wiping system files may render your device unusable. Only wipe files you are certain about.',
      icon: 'phone-android',
      color: '#ea580c',
    },
    {
      id: 'legal_compliance',
      title: 'LEGAL RESPONSIBILITY',
      description: 'You are responsible for ensuring compliance with data protection laws and regulations.',
      icon: 'gavel',
      color: '#ea580c',
    },
    {
      id: 'time_commitment',
      title: 'PROCESS DURATION',
      description: `This operation will take approximately ${Math.ceil(estimatedTime / 60)} minutes and cannot be interrupted safely.`,
      icon: 'schedule',
      color: '#d97706',
    },
  ];

  const toggleWarningAcceptance = (warningId: string) => {
    const newAccepted = new Set(acceptedWarnings);
    if (newAccepted.has(warningId)) {
      newAccepted.delete(warningId);
    } else {
      newAccepted.add(warningId);
    }
    setAcceptedWarnings(newAccepted);
  };

  const allWarningsAccepted = warnings.every(warning => acceptedWarnings.has(warning.id));

  const handleProceed = () => {
    if (!allWarningsAccepted) {
      Alert.alert(
        'Acknowledgment Required',
        'Please read and acknowledge all warnings before proceeding.',
        [{text: 'OK'}]
      );
      return;
    }

    setFinalConfirmation(true);
  };

  const handleFinalConfirmation = () => {
    Alert.alert(
      'FINAL CONFIRMATION',
      `Are you absolutely certain you want to PERMANENTLY DELETE ${selectedItemsCount} items (${totalSize})?\n\nType "DELETE" to confirm or cancel to abort.`,
      [
        {text: 'CANCEL', style: 'cancel', onPress: () => setFinalConfirmation(false)},
        {
          text: 'DELETE',
          style: 'destructive',
          onPress: () => {
            setFinalConfirmation(false);
            onAccept();
          },
        },
      ]
    );
  };

  const resetState = () => {
    setAcceptedWarnings(new Set());
    setFinalConfirmation(false);
  };

  const handleCancel = () => {
    resetState();
    onCancel();
  };

  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={false}
      onRequestClose={handleCancel}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Icon name="warning" size={40} color="#dc2626" />
          <Text style={styles.title}>CRITICAL WARNING</Text>
          <Text style={styles.subtitle}>Data Wiping Disclaimer</Text>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={true}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Operation Summary</Text>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Method:</Text>
              <Text style={styles.summaryValue}>{wipingMethod.toUpperCase()}</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Items to wipe:</Text>
              <Text style={styles.summaryValue}>{selectedItemsCount}</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Total size:</Text>
              <Text style={styles.summaryValue}>{totalSize}</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Estimated time:</Text>
              <Text style={styles.summaryValue}>{formatTime(estimatedTime)}</Text>
            </View>
          </View>

          <View style={styles.warningsContainer}>
            <Text style={styles.warningsTitle}>
              You must acknowledge all warnings below:
            </Text>
            
            {warnings.map((warning) => (
              <TouchableOpacity
                key={warning.id}
                style={[
                  styles.warningCard,
                  {borderColor: warning.color},
                  acceptedWarnings.has(warning.id) && styles.warningCardAccepted,
                ]}
                onPress={() => toggleWarningAcceptance(warning.id)}>
                <View style={styles.warningHeader}>
                  <Icon name={warning.icon} size={24} color={warning.color} />
                  <Text style={[styles.warningTitle, {color: warning.color}]}>
                    {warning.title}
                  </Text>
                  <Icon
                    name={acceptedWarnings.has(warning.id) ? 'check-circle' : 'radio-button-unchecked'}
                    size={24}
                    color={acceptedWarnings.has(warning.id) ? '#059669' : '#9ca3af'}
                  />
                </View>
                <Text style={styles.warningDescription}>{warning.description}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <View style={styles.legalNotice}>
            <Text style={styles.legalText}>
              By proceeding, you acknowledge that you have read, understood, and accept full responsibility 
              for the consequences of this data wiping operation. This software is provided "as is" without 
              any warranties. The developers are not liable for any data loss or damage.
            </Text>
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity style={styles.cancelButton} onPress={handleCancel}>
            <Icon name="cancel" size={20} color="#fff" />
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.proceedButton,
              !allWarningsAccepted && styles.proceedButtonDisabled,
            ]}
            onPress={handleProceed}
            disabled={!allWarningsAccepted}>
            <Icon name="delete-forever" size={20} color="#fff" />
            <Text style={styles.proceedButtonText}>
              {allWarningsAccepted ? 'PROCEED TO WIPE' : 'ACKNOWLEDGE WARNINGS'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    backgroundColor: '#dc2626',
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginTop: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#fef2f2',
    marginTop: 5,
  },
  content: {
    flex: 1,
    padding: 20,
  },
  summaryCard: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 8,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 15,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  summaryLabel: {
    fontSize: 16,
    color: '#6b7280',
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
  },
  warningsContainer: {
    marginBottom: 20,
  },
  warningsTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 15,
  },
  warningCard: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 8,
    marginBottom: 10,
    borderWidth: 2,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  warningCardAccepted: {
    backgroundColor: '#f0fdf4',
    borderColor: '#059669',
  },
  warningHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  warningTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    flex: 1,
    marginLeft: 10,
  },
  warningDescription: {
    fontSize: 14,
    color: '#4b5563',
    lineHeight: 20,
  },
  legalNotice: {
    backgroundColor: '#f3f4f6',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#d1d5db',
  },
  legalText: {
    fontSize: 12,
    color: '#6b7280',
    lineHeight: 18,
    textAlign: 'center',
  },
  footer: {
    flexDirection: 'row',
    padding: 20,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  cancelButton: {
    flex: 1,
    backgroundColor: '#6b7280',
    padding: 15,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  cancelButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 5,
  },
  proceedButton: {
    flex: 2,
    backgroundColor: '#dc2626',
    padding: 15,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  proceedButtonDisabled: {
    backgroundColor: '#9ca3af',
  },
  proceedButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 5,
  },
});

export default WarningDisclaimer;
