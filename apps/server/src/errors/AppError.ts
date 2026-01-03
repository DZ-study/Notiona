export type ErrorCode =
  | "BAD_REQUEST"
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "INTERNAL_ERROR";

export class AppError extends Error {
  statusCode: number;
  code: ErrorCode;
  isOperational: boolean;

  constructor(
    message: string,
    options: {
      statusCode: number;
      code: ErrorCode;
      isOperational?: boolean;
    }
  ) {
    super(message)
    this.statusCode = options.statusCode;
    this.code = options.code;
    this.isOperational = options.isOperational ?? true;

    Object.setPrototypeOf(this, new.target.prototype);
  }

}