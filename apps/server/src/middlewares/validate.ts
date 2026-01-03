import { ZodSchema } from 'zod'

import { Request, Response, NextFunction } from 'express'

export const validate =
  (schema: ZodSchema) => {
    return (
      req: Request,
      res: Response,
      next: NextFunction
    ) => {
      console.log('22222')
      const result  = schema.safeParse(req.body)

      if (!result.success) {
        return next(result.error)
      }

      req.body = result.data
      next()
    }
  }