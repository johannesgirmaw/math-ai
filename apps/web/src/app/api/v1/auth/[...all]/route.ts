import { toNextJsHandler } from "better-auth/next-js";
import { getAuth } from "@/server/auth";

const handler = () => toNextJsHandler(getAuth());

export const GET = (request: Request) => handler().GET(request);
export const POST = (request: Request) => handler().POST(request);
