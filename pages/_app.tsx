import '@styles/app.css';
import type { AppProps } from 'next/app'

function Main({ Component, pageProps }: AppProps)
{
	return <Component { ...pageProps } />
}
export default Main
