import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  experimental: {
    // Disable Turbopack due to Korean character path issues
  },
  // Force webpack instead of Turbopack
  webpack: (config) => {
    return config;
  },
};

export default nextConfig;
