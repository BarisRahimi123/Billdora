/**
 * Push Notifications Service
 * 
 * Handles native iOS push notifications using Capacitor.
 * This service manages permission requests, token registration,
 * and local notification delivery.
 * 
 * Uses lazy loading to avoid blocking app startup.
 */

import { Capacitor } from '@capacitor/core';

// Lazy load PushNotifications to avoid blocking app startup
let PushNotificationsModule: typeof import('@capacitor/push-notifications').PushNotifications | null = null;

async function getPushNotifications() {
  if (!PushNotificationsModule) {
    const module = await import('@capacitor/push-notifications');
    PushNotificationsModule = module.PushNotifications;
  }
  return PushNotificationsModule;
}

export interface PushNotificationToken {
  value: string;
}

export interface PushNotificationData {
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

/**
 * Check if push notifications are available (only on native platforms)
 */
export function isPushNotificationsAvailable(): boolean {
  // Check multiple ways to detect native platform
  const platform = Capacitor.getPlatform();
  const isNative = Capacitor.isNativePlatform();
  const isIOS = platform === 'ios';
  const isAndroid = platform === 'android';
  
  console.log('[Push] Platform detection:', { platform, isNative, isIOS, isAndroid });
  
  return isNative || isIOS || isAndroid;
}

/**
 * Request permission for push notifications
 */
export async function requestPushPermission(): Promise<boolean> {
  if (!isPushNotificationsAvailable()) {
    console.log('Push notifications not available on this platform');
    return false;
  }

  try {
    const PushNotifications = await getPushNotifications();
    
    // Check current permission status
    const permStatus = await PushNotifications.checkPermissions();
    
    if (permStatus.receive === 'granted') {
      return true;
    }
    
    if (permStatus.receive === 'denied') {
      console.log('Push notification permission denied');
      return false;
    }
    
    // Request permission
    const result = await PushNotifications.requestPermissions();
    return result.receive === 'granted';
  } catch (error) {
    console.error('Error requesting push permission:', error);
    return false;
  }
}

/**
 * Register for push notifications and get device token
 */
export async function registerPushNotifications(): Promise<string | null> {
  if (!isPushNotificationsAvailable()) {
    return null;
  }

  const hasPermission = await requestPushPermission();
  if (!hasPermission) {
    return null;
  }

  const PushNotifications = await getPushNotifications();

  return new Promise((resolve) => {
    // Listen for registration success
    PushNotifications.addListener('registration', (token: PushNotificationToken) => {
      console.log('Push registration success, token:', token.value);
      resolve(token.value);
    });

    // Listen for registration error
    PushNotifications.addListener('registrationError', (error: any) => {
      console.error('Push registration error:', error);
      resolve(null);
    });

    // Register with Apple Push Notification service
    PushNotifications.register();
  });
}

/**
 * Add listener for incoming push notifications
 */
export async function addPushNotificationListener(
  callback: (notification: { title: string; body: string; data: any }) => void
): Promise<void> {
  if (!isPushNotificationsAvailable()) {
    return;
  }

  const PushNotifications = await getPushNotifications();

  // Listen for push notification received
  PushNotifications.addListener('pushNotificationReceived', (notification) => {
    console.log('Push notification received:', notification);
    callback({
      title: notification.title || 'Notification',
      body: notification.body || '',
      data: notification.data,
    });
  });

  // Listen for push notification action (tap)
  PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
    console.log('Push notification action:', action);
    callback({
      title: action.notification.title || 'Notification',
      body: action.notification.body || '',
      data: action.notification.data,
    });
  });
}

/**
 * Remove all push notification listeners
 */
export async function removeAllPushListeners(): Promise<void> {
  if (!isPushNotificationsAvailable()) {
    return;
  }
  const PushNotifications = await getPushNotifications();
  await PushNotifications.removeAllListeners();
}

/**
 * Schedule a local notification (appears immediately)
 * This is useful for testing without a push server
 */
export async function sendLocalNotification(
  title: string,
  body: string,
  data?: Record<string, unknown>
): Promise<boolean> {
  // Try to send notification regardless of platform detection
  // This helps debug issues with Capacitor bridge detection
  try {
    const { LocalNotifications } = await import('@capacitor/local-notifications');
    
    // Request permissions
    const permResult = await LocalNotifications.requestPermissions();
    
    if (permResult.display !== 'granted') {
      throw new Error('Notification permission denied by user');
    }
    
    const notificationId = Math.floor(Math.random() * 100000);
    
    await LocalNotifications.schedule({
      notifications: [
        {
          id: notificationId,
          title,
          body,
          schedule: { at: new Date(Date.now() + 1000) }, // 1 second delay
          extra: data,
        },
      ],
    });
    
    return true;
  } catch (error: any) {
    // Re-throw with more context
    throw new Error(`Notification failed: ${error?.message || error}`);
  }
}

/**
 * Get the current push notification permission status
 */
export async function getPushPermissionStatus(): Promise<'granted' | 'denied' | 'prompt'> {
  if (!isPushNotificationsAvailable()) {
    return 'denied';
  }

  try {
    const PushNotifications = await getPushNotifications();
    const status = await PushNotifications.checkPermissions();
    return status.receive as 'granted' | 'denied' | 'prompt';
  } catch (error) {
    console.error('Error checking push permission:', error);
    return 'denied';
  }
}

export default {
  isPushNotificationsAvailable,
  requestPushPermission,
  registerPushNotifications,
  addPushNotificationListener,
  removeAllPushListeners,
  sendLocalNotification,
  getPushPermissionStatus,
};
