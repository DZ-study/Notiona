import jwt, { SignOptions } from 'jsonwebtoken'

type TAuthUser = {
  id: string
  email: string
}

// 生成token
export const generateToken = (user: TAuthUser) => {
  const secret = process.env.JWT_SECRET
  if (!secret) {
    throw new Error('JWT_SECRET is not set')
  }
  const payload = {
    sub: user.id,
    email: user.email
  }

  const expiresIn = (process.env.JWT_EXPIRES_IN || '15m') as SignOptions['expiresIn']

  return jwt.sign(payload, secret, {
    expiresIn
  })
}