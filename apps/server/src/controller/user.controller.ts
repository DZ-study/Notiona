import { createUser } from '@/services/user.service'

// TODO 从req获取
export async function regist(_req: any, res: any) {
  const user = await createUser({
    email: '1213198891@qq.com'
  })
  return res.json(user)
}