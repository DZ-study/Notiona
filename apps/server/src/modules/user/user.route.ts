import { Router } from 'express'
import { regist } from '@/modules/user/user.controller'

const router = Router()

router.post('/regist', regist)

export default router