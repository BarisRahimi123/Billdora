// API utilities with retry logic and error handling
import { supabase } from './supabase';

export class ApiError extends Error {
  constructor(
    message: string,
    public code?: string,
    public status?: number,
    public retryable: boolean = false
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

interface RetryConfig {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
}

const defaultRetryConfig: RetryConfig = {
  maxRetries: 3,
  baseDelay: 1000,
  maxDelay: 10000,
};

function isAuthError(error: unknown): boolean {
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    return (
      message.includes('jwt') ||
      message.includes('token') ||
      message.includes('unauthorized') ||
      message.includes('401') ||
      message.includes('session')
    );
  }
  return false;
}

function isRetryableError(error: unknown): boolean {
  if (error instanceof ApiError) return error.retryable;
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    return (
      message.includes('network') ||
      message.includes('timeout') ||
      message.includes('fetch failed') ||
      message.includes('503') ||
      message.includes('429')
    );
  }
  return false;
}

function getDelay(attempt: number, config: RetryConfig): number {
  const delay = config.baseDelay * Math.pow(2, attempt);
  const jitter = Math.random() * 0.3 * delay;
  return Math.min(delay + jitter, config.maxDelay);
}

// Track if we're currently refreshing to prevent multiple simultaneous refreshes
let isRefreshing = false;
let refreshPromise: Promise<boolean> | null = null;

async function refreshSession(): Promise<boolean> {
  if (isRefreshing && refreshPromise) {
    return refreshPromise;
  }
  
  isRefreshing = true;
  refreshPromise = (async () => {
    try {
      const { data, error } = await supabase.auth.refreshSession();
      return !error && !!data.session;
    } catch {
      return false;
    } finally {
      isRefreshing = false;
      refreshPromise = null;
    }
  })();
  
  return refreshPromise;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  config: Partial<RetryConfig> = {}
): Promise<T> {
  const cfg = { ...defaultRetryConfig, ...config };
  let lastError: unknown;
  let hasTriedRefresh = false;

  for (let attempt = 0; attempt <= cfg.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      // On auth errors, try refreshing the session once
      if (!hasTriedRefresh && isAuthError(error)) {
        hasTriedRefresh = true;
        const refreshed = await refreshSession();
        if (refreshed) {
          continue; // Retry with new token
        }
        // If refresh failed, redirect to login
        window.location.href = '/login';
        throw error;
      }
      
      if (attempt < cfg.maxRetries && isRetryableError(error)) {
        const delay = getDelay(attempt, cfg);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      throw error;
    }
  }

  throw lastError;
}

export function formatApiError(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message;
  }
  if (error instanceof Error) {
    // Clean up Supabase/Postgres errors
    const message = error.message;
    if (message.includes('row-level security')) {
      return 'You do not have permission to perform this action.';
    }
    if (message.includes('duplicate key')) {
      return 'This record already exists.';
    }
    if (message.includes('violates foreign key')) {
      return 'This record is linked to other data and cannot be modified.';
    }
    if (message.includes('network') || message.includes('fetch')) {
      return 'Network error. Please check your connection and try again.';
    }
    return message;
  }
  return 'An unexpected error occurred. Please try again.';
}
