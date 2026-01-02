import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "CONNECT : SEOUL",
  description: "서울 탐방 시뮬레이션 RPG",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" data-theme="light">
      <body>
        {children}
      </body>
    </html>
  );
}
