import pino from "pino";

export const logger = pino({ level: process.env.LOG_LEVEL ?? "info" });

export function requestLogger(requestId: string, userId?: string) {
  return logger.child({ requestId, userId });
}
