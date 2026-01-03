import { z } from 'zod'

export const createUserSchema = z.object({
  email: z.email(),
  username: z.string().min(3).max(100),
  password: z.string()
})

export type TCreateUserDTO = z.infer<typeof createUserSchema>