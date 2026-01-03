import { Router } from 'express'
import { register } from '@/modules/user/user.controller'
import { registerSchema } from './user.schema'
import { validate } from '@/middlewares/validate'
import { asyncHandler } from '@/middlewares/asyncHandler'

const router = Router()

router.post(
  '/register',
  validate(registerSchema),
  asyncHandler(register)
)

export default router