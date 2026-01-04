import { z } from 'zod'
import { registerSchema } from './user.schema'

export type TCreateUserDTO = z.infer<typeof registerSchema>