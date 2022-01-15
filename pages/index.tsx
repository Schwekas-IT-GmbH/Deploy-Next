import type { NextPage } from 'next'

const Home: NextPage = () =>
{
	return (
		<>
			<div className="bg-white min-h-full px-4 py-16 sm:px-6 sm:py-24 md:grid md:place-items-center lg:px-8">
				<div className="max-w-max mx-auto">
					<main className="sm:flex">
						<p className="text-4xl font-extrabold text-indigo-600 sm:text-5xl">Yo!</p>
						<div className="sm:ml-6">
							<div className="sm:border-l sm:border-gray-200 sm:pl-6">
								<h1 className="text-4xl font-extrabold text-gray-900 tracking-tight sm:text-5xl">Everything is in order!</h1>
								<p className="mt-1 text-base text-gray-500">You can now customize this project as you wish...</p>
							</div>
							<div className="mt-10 flex space-x-3 sm:border-l sm:border-transparent sm:pl-6">
								<a
									href={process.env.NEXT_PUBLIC_API_DOMAIN}
									className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
								>
									To Directus
								</a>
								<a
									href="https://schwekas.com"
									className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
								>
									Schwekas.com - Creators of this Toolkit
								</a>
							</div>
						</div>
					</main>
				</div>
			</div>
		</>
	)
}

export default Home
