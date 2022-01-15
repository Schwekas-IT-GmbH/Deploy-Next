
declare module '*.gql'
{
	import { TypedDocumentNode } from '@apollo/client';
	const Schema: TypedDocumentNode;
	export = Schema;
}