import { Request, Response } from "express"
import { registryUser } from '@/modules/user/user.service'
import { createUserSchema } from '@/modules/user/user.dto'
import z from "zod"

export async function regist(req: Request, res: Response) {
  try {
    const data = createUserSchema.parse(req.body)
    const user = await registryUser(data)
    res.status(201).json(user)
  } catch (err) {
    if (err instanceof z.ZodError) {
      // 请求验证失败
      return res.status(400).json({ errors: err })
    }
    res.status(500).json({ message: "服务器错误", error: err })
  }
}