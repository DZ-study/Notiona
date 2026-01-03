import { AppError } from "@/errors/AppError";
import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";

export function errorMiddleware(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      code: 'BAD_REQUEST',
      message: "参数校验失败",
      errors: (err as ZodError).issues
    })
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      code: err.code,
      message: err.message,
    });
  }

  return res.status(500).json({
    code: 'INTERNAL_ERROR',
    message: err.message || '服务器错误',
    errors: err
  })
}