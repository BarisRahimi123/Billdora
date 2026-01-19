import { createBrowserClient } from '@supabase/ssr'

// Client-side Supabase client (for use in 'use client' components)
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://pouzlstzxpggjpgutmvd.supabase.co',
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdXpsc3R6eHBnZ2pwZ3V0bXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODA2MzEsImV4cCI6MjA4Mzg1NjYzMX0.uSD8dt8wF69xIV5WymXc4LC1qLqwL0meTB7OjrPTjI0'
  )
}
