import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../context/AuthContext';

interface HomeScreenProps {
  navigation: any;
}

const HomeScreen: React.FC<HomeScreenProps> = ({navigation}) => {
  const {logout} = useAuth();

  const handleLogout = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to logout?',
      [
        {text: 'Cancel', style: 'cancel'},
        {
          text: 'Logout',
          onPress: async () => {
            await logout();
            navigation.replace('Auth');
          },
        },
      ]
    );
  };

  const navigationOptions = [
    {
      id: 'external_devices',
      title: 'Scan External Storage',
      description: 'Detect and wipe external storage devices',
      icon: 'usb',
      color: '#059669',
      screen: 'DeviceScan',
    },
    {
      id: 'internal_storage',
      title: 'Browse SD Card / Internal Storage',
      description: 'Select files and folders to wipe from internal storage',
      icon: 'sd-card',
      color: '#dc2626',
      screen: 'FileSelection',
      params: {storageType: 'internal'},
    },
  ];

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Icon name="security" size={40} color="#dc2626" />
          <View style={styles.titleText}>
            <Text style={styles.title}>CleanSlate</Text>
            <Text style={styles.subtitle}>Secure Data Wiping</Text>
          </View>
        </View>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Icon name="logout" size={20} color="#6b7280" />
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        <View style={styles.warningCard}>
          <Icon name="warning" size={24} color="#f59e0b" />
          <Text style={styles.warningText}>
            Warning: Data wiping is irreversible. Make sure to backup important data before proceeding.
          </Text>
        </View>

        <Text style={styles.sectionTitle}>Select Wiping Operation</Text>

        {navigationOptions.map((option) => (
          <TouchableOpacity
            key={option.id}
            style={[styles.optionCard, {borderLeftColor: option.color}]}
            onPress={() => navigation.navigate(option.screen, option.params || {})}>
            <View style={styles.optionIcon}>
              <Icon name={option.icon} size={32} color={option.color} />
            </View>
            <View style={styles.optionContent}>
              <Text style={styles.optionTitle}>{option.title}</Text>
              <Text style={styles.optionDescription}>{option.description}</Text>
            </View>
            <Icon name="chevron-right" size={24} color="#9ca3af" />
          </TouchableOpacity>
        ))}

        <View style={styles.featuresSection}>
          <Text style={styles.sectionTitle}>Security Features</Text>
          
          <View style={styles.featuresList}>
            <View style={styles.featureItem}>
              <Icon name="verified" size={20} color="#059669" />
              <Text style={styles.featureText}>DoD 5220.22-M Standard</Text>
            </View>
            <View style={styles.featureItem}>
              <Icon name="verified" size={20} color="#059669" />
              <Text style={styles.featureText}>NIST 800-88 Guidelines</Text>
            </View>
            <View style={styles.featureItem}>
              <Icon name="verified" size={20} color="#059669" />
              <Text style={styles.featureText}>Gutmann 35-Pass Method</Text>
            </View>
            <View style={styles.featureItem}>
              <Icon name="verified" size={20} color="#059669" />
              <Text style={styles.featureText}>Cryptographic Random Overwrite</Text>
            </View>
            <View style={styles.featureItem}>
              <Icon name="verified" size={20} color="#059669" />
              <Text style={styles.featureText}>Verification & Audit Trail</Text>
            </View>
          </View>
        </View>

        <View style={styles.infoCard}>
          <Icon name="info" size={20} color="#3b82f6" />
          <Text style={styles.infoText}>
            CleanSlate uses military-grade algorithms to ensure complete data destruction. 
            All operations are logged for security audit purposes.
          </Text>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  titleText: {
    marginLeft: 12,
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  subtitle: {
    fontSize: 14,
    color: '#6b7280',
  },
  logoutButton: {
    padding: 8,
  },
  content: {
    padding: 20,
  },
  warningCard: {
    flexDirection: 'row',
    backgroundColor: '#fef3c7',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#fbbf24',
    marginBottom: 25,
    alignItems: 'flex-start',
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    color: '#92400e',
    marginLeft: 10,
    lineHeight: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 15,
  },
  optionCard: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 15,
    borderLeftWidth: 4,
    alignItems: 'center',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  optionIcon: {
    marginRight: 15,
  },
  optionContent: {
    flex: 1,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 4,
  },
  optionDescription: {
    fontSize: 14,
    color: '#6b7280',
    lineHeight: 18,
  },
  featuresSection: {
    marginTop: 30,
    marginBottom: 20,
  },
  featuresList: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  featureText: {
    fontSize: 14,
    color: '#374151',
    marginLeft: 10,
  },
  infoCard: {
    flexDirection: 'row',
    backgroundColor: '#eff6ff',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#bfdbfe',
    alignItems: 'flex-start',
    marginTop: 10,
  },
  infoText: {
    flex: 1,
    fontSize: 13,
    color: '#1e40af',
    marginLeft: 10,
    lineHeight: 18,
  },
});

export default HomeScreen;
