import { NextFunction, Request, Response } from "express"
import { registryUser } from '@/modules/user/user.service'
import { createUserSchema } from '@/modules/user/user.dto'

export async function register(req: Request, res: Response, next: NextFunction) {
  try {
    console.log(req.body)
    const data = createUserSchema.parse(req.body)
    const user = await registryUser(data)
    res.status(201).json(user)
  } catch (err) {
    console.log(err)
    next()
  }
}