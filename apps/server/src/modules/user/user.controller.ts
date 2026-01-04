import { Request, Response } from "express"
import { registryUser } from '@/modules/user/user.service'
import { registerSchema } from '@/modules/user/user.schema'

export async function register(req: Request, res: Response) {
  const data = registerSchema.parse(req.body)
  const user = await registryUser(data)
  res.status(201).json(user)
}