/**
 * Push Notifications Service
 * 
 * Handles native iOS push notifications using Capacitor.
 * This service manages permission requests, token registration,
 * and local notification delivery.
 */

import { PushNotifications } from '@capacitor/push-notifications';
import { Capacitor } from '@capacitor/core';

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
  return Capacitor.isNativePlatform();
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
export function addPushNotificationListener(
  callback: (notification: { title: string; body: string; data: any }) => void
): void {
  if (!isPushNotificationsAvailable()) {
    return;
  }

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
  if (!isPushNotificationsAvailable()) {
    console.log('Local notifications not available on web');
    return false;
  }

  try {
    // For local notifications, we use the native notification API
    // This simulates a push notification for testing
    const { LocalNotifications } = await import('@capacitor/local-notifications');
    
    const hasPermission = await LocalNotifications.checkPermissions();
    if (hasPermission.display !== 'granted') {
      await LocalNotifications.requestPermissions();
    }
    
    await LocalNotifications.schedule({
      notifications: [
        {
          id: Date.now(),
          title,
          body,
          schedule: { at: new Date(Date.now() + 1000) }, // 1 second delay
          extra: data,
        },
      ],
    });
    
    return true;
  } catch (error) {
    console.error('Failed to send local notification:', error);
    return false;
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
