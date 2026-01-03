import { AppError } from '@/errors/AppError';
import { findUserByEmail } from '@/modules/user/user.repository';
import bcrypt from 'bcrypt'

export async function login(email: string, password: string) {
  const user = await findUserByEmail(email)

  if (!user) {
    throw new AppError('用户不存在', {
      statusCode: 401,
      code: 'NOT_FOUND'
    });
  }

  if (!bcrypt.compare(password, user.passwordHash)) {
    throw new AppError("登录失败", {
      statusCode: 401,
      code: 'UNAUTHORIZED'
    })
  }

  if (!user.isActive) {
    throw new AppError('用户未激活', {
      statusCode: 403,
      code: 'FORBIDDEN'
    })
  }

  // return this.generateToken(user);

}