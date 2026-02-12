import { slate, red, amber, blue } from '@radix-ui/colors';

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        ...slate,
        ...red,
        ...amber,
        ...blue,
      },
    },
  },
  plugins: [],
}
