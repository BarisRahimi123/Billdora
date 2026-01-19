'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

export default function HomePage() {
  const router = useRouter()

  useEffect(() => {
    checkAuth()
  }, [])

  async function checkAuth() {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    
    if (user) {
      router.push('/dashboard')
    } else {
      router.push('/auth/signin')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#f5f5f3]">
      <div className="text-center">
        <div className="w-16 h-16 bg-[#476E66] rounded-2xl flex items-center justify-center mx-auto mb-4">
          <span className="text-white font-bold text-3xl">B</span>
        </div>
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#476E66] mx-auto mt-4"></div>
      </div>
    </div>
  )
}
