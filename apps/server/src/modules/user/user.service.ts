import { TCreateUserDTO } from "@/modules/user/user.dto";
import { createUser, findUserByEmail } from "@/modules/user/user.repository";
import { AppError } from '@/errors/AppError'
import bcrypt from 'bcrypt'
import { generateToken } from "@/lib/auth";
import { sendMail } from "../mail/mail.service";

// 用户注册
export async function registryUser(data: TCreateUserDTO) {
  try {
    const existUser = await findUserByEmail(data.email)
    if (existUser) {
      throw new AppError("用户已存在", {
        statusCode: 409,
        code: 'CONFLICT'
      })
    }

    const passwordHash = await bcrypt.hash(data.password, 10)

    const user = await createUser({
      email: data.email,
      username: data.username,
      password: passwordHash
    })

    // 发送邮箱token
    const verifyUrl = `http://localhost:3001/verify-email?token=${generateToken(user)}`
    console.log('before send email')
    sendMail({
      to: data.email,
      subject: '测试',
      html: `<p>${verifyUrl}</p>`
    })
    console.log('end send email')

    return {
      id: user.id,
      email: user.email,
      username: user.username,
      createdAt: user.createdAt
    }
  } catch (error) {
    console.log("用户注册失败", error)
    throw new AppError("用户注册失败", {
      statusCode: 400,
      code: 'INTERNAL_ERROR'
    })
  }
}