import { handle } from "hono/vercel";
import { getApi } from "@/server/api";

const api = () => handle(getApi());

export const GET = (request: Request) => api()(request);
export const POST = (request: Request) => api()(request);
export const PATCH = (request: Request) => api()(request);
