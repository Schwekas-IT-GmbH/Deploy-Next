module.exports = {
  mode: "jit",
  content: ['./pages/**/*.{js,ts,jsx,tsx}', './@modules/**/*.{js,ts,jsx,tsx}'],
  darkMode: true,
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [
	require('@tailwindcss/forms'),
	require('@tailwindcss/typography')
  ],
}
