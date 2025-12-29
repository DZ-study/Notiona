import { Router } from 'express'
import { regist } from '@/controller/user.controller'

const router = Router()

router.post('/user/regist', regist)

export default router