import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Billdora - Collaborate on Proposals",
  description: "Submit your pricing and collaborate on proposals with Billdora",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-[#f5f5f3]">
        {children}
      </body>
    </html>
  );
}
