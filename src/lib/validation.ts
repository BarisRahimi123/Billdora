// Form validation utilities

export interface ValidationRule {
  required?: boolean;
  minLength?: number;
  maxLength?: number;
  min?: number;
  max?: number;
  pattern?: RegExp;
  email?: boolean;
  custom?: (value: unknown) => string | null;
}

export interface ValidationResult {
  valid: boolean;
  errors: Record<string, string>;
}

export function validateEmail(email: string): boolean {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
}

export function validateRequired(value: unknown): boolean {
  if (value === null || value === undefined) return false;
  if (typeof value === 'string') return value.trim().length > 0;
  if (typeof value === 'number') return !isNaN(value);
  if (Array.isArray(value)) return value.length > 0;
  return true;
}

export function validateField(value: unknown, rules: ValidationRule): string | null {
  if (rules.required && !validateRequired(value)) {
    return 'This field is required';
  }

  if (value === null || value === undefined || value === '') {
    return null; // Skip other validations if empty and not required
  }

  if (typeof value === 'string') {
    if (rules.minLength && value.length < rules.minLength) {
      return `Must be at least ${rules.minLength} characters`;
    }
    if (rules.maxLength && value.length > rules.maxLength) {
      return `Must be no more than ${rules.maxLength} characters`;
    }
    if (rules.email && !validateEmail(value)) {
      return 'Please enter a valid email address';
    }
    if (rules.pattern && !rules.pattern.test(value)) {
      return 'Invalid format';
    }
  }

  if (typeof value === 'number') {
    if (rules.min !== undefined && value < rules.min) {
      return `Must be at least ${rules.min}`;
    }
    if (rules.max !== undefined && value > rules.max) {
      return `Must be no more than ${rules.max}`;
    }
  }

  if (rules.custom) {
    return rules.custom(value);
  }

  return null;
}

export function validateForm<T extends Record<string, unknown>>(
  data: T,
  rules: Partial<Record<keyof T, ValidationRule>>
): ValidationResult {
  const errors: Record<string, string> = {};

  for (const [field, fieldRules] of Object.entries(rules)) {
    if (fieldRules) {
      const error = validateField(data[field], fieldRules as ValidationRule);
      if (error) {
        errors[field] = error;
      }
    }
  }

  return {
    valid: Object.keys(errors).length === 0,
    errors,
  };
}

// Common validation schemas
export const clientValidationRules = {
  name: { required: true, minLength: 2, maxLength: 100 },
  email: { email: true },
  display_name: { maxLength: 100 },
};

export const invoiceValidationRules = {
  client_id: { required: true },
  due_date: { required: true },
};

export const projectValidationRules = {
  name: { required: true, minLength: 2, maxLength: 100 },
  client_id: { required: true },
};

export const timeEntryValidationRules = {
  hours: { required: true, min: 0.25, max: 24 },
  date: { required: true },
};
