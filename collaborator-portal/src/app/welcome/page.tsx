'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createClient } from '@/lib/supabase';
import Link from 'next/link';

// Feature cards to showcase the platform
const features = [
  {
    icon: '📊',
    title: 'Proposals & Quotes',
    description: 'Create professional proposals, collaborate with consultants, and win more projects.',
  },
  {
    icon: '📁',
    title: 'Project Management',
    description: 'Track projects, tasks, and milestones. Keep your team aligned and on schedule.',
  },
  {
    icon: '⏱️',
    title: 'Time Tracking',
    description: 'Log hours, track expenses, and generate accurate invoices automatically.',
  },
  {
    icon: '💰',
    title: 'Invoicing & Payments',
    description: 'Send professional invoices, accept payments, and manage your cash flow.',
  },
  {
    icon: '👥',
    title: 'Team Collaboration',
    description: 'Invite team members, assign roles, and collaborate seamlessly.',
  },
  {
    icon: '📈',
    title: 'Analytics & Reports',
    description: 'Get insights into your business performance with powerful analytics.',
  },
];

function WelcomeContent() {
  const [userName, setUserName] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();
  const searchParams = useSearchParams();
  const supabase = createClient();
  
  const fromSubmission = searchParams.get('submitted') === 'true';
  const projectName = searchParams.get('project') || 'the project';

  useEffect(() => {
    async function checkUser() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        router.push('/auth/signin');
        return;
      }
      
      // Get user's name from profile or metadata
      const { data: profile } = await supabase
        .from('collaborator_accounts')
        .select('full_name')
        .eq('auth_user_id', user.id)
        .single();
      
      setUserName(profile?.full_name || user.email?.split('@')[0] || 'there');
      setIsLoading(false);
    }
    checkUser();
  }, [router, supabase]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-teal-50 to-white">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="w-10 h-10 bg-teal-700 text-white font-bold text-xl rounded-xl flex items-center justify-center">B</div>
              <span className="ml-2 text-xl font-bold text-gray-900">Billdora</span>
            </div>
            <Link
              href="/dashboard"
              className="text-sm text-teal-600 hover:text-teal-700 font-medium"
            >
              Go to Dashboard →
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="text-center">
          {fromSubmission && (
            <div className="inline-flex items-center px-4 py-2 rounded-full bg-green-100 text-green-700 text-sm font-medium mb-6">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              Your pricing has been submitted for {projectName}!
            </div>
          )}
          
          <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-4">
            Welcome, {userName}! 🎉
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto mb-8">
            You're now part of the Billdora community. Unlock all features to streamline your business and win more projects.
          </p>
          
          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <a
              href="https://www.billdora.com"
              className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold text-white bg-teal-600 rounded-xl hover:bg-teal-700 transition-colors shadow-lg hover:shadow-xl"
            >
              <svg className="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              Continue on Web
            </a>
            
            <button
              onClick={() => {
                // Show app download modal
                const modal = document.getElementById('download-modal');
                modal?.classList.remove('hidden');
              }}
              className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold text-teal-700 bg-white border-2 border-teal-200 rounded-xl hover:border-teal-300 hover:bg-teal-50 transition-colors"
            >
              <svg className="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
              Download Mobile App
            </button>
          </div>
        </div>

        {/* Features Grid */}
        <div className="mb-16">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Everything You Need to Run Your Business
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature, index) => (
              <div
                key={index}
                className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow border border-gray-100"
              >
                <div className="text-4xl mb-4">{feature.icon}</div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">{feature.title}</h3>
                <p className="text-gray-600">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Testimonial or Social Proof */}
        <div className="bg-white rounded-2xl p-8 shadow-sm border border-gray-100 text-center">
          <p className="text-lg text-gray-700 italic mb-4">
            "Billdora has transformed how we handle proposals and invoicing. What used to take hours now takes minutes."
          </p>
          <p className="text-gray-500 font-medium">— Sarah K., Architecture Firm Owner</p>
        </div>
      </div>

      {/* Download Modal */}
      <div id="download-modal" className="hidden fixed inset-0 z-50 overflow-y-auto">
        <div className="flex items-center justify-center min-h-screen px-4">
          <div className="fixed inset-0 bg-black opacity-50" onClick={() => document.getElementById('download-modal')?.classList.add('hidden')}></div>
          
          <div className="relative bg-white rounded-2xl max-w-md w-full p-8 shadow-2xl">
            <button
              onClick={() => document.getElementById('download-modal')?.classList.add('hidden')}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            
            <div className="text-center">
              <div className="w-16 h-16 bg-teal-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">📱</span>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2">Get the App</h3>
              <p className="text-gray-600 mb-6">
                Take Billdora with you everywhere. Available on iOS and Android.
              </p>
              
              <div className="space-y-3">
                <a
                  href="https://apps.apple.com/app/billdora"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center w-full px-6 py-3 bg-black text-white rounded-xl hover:bg-gray-800 transition-colors"
                >
                  <svg className="w-6 h-6 mr-2" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  Download on App Store
                </a>
                
                <a
                  href="https://play.google.com/store/apps/details?id=com.billdora"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center w-full px-6 py-3 bg-black text-white rounded-xl hover:bg-gray-800 transition-colors"
                >
                  <svg className="w-6 h-6 mr-2" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/>
                  </svg>
                  Get it on Google Play
                </a>
              </div>
              
              <p className="text-sm text-gray-500 mt-6">
                Your account is already set up. Just sign in with your email.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-50 border-t border-gray-200 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-500 text-sm">
          <p>© 2026 Billdora. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}

export default function WelcomePage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600"></div>
      </div>
    }>
      <WelcomeContent />
    </Suspense>
  );
}
