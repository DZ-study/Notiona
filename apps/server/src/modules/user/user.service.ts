import { TCreateUserDTO } from "@/modules/user/user.dto";
import { createUser, findUserByEmail } from "@/modules/user/user.repository";

export async function registryUser(data: TCreateUserDTO) {
  try {
    const existUser = await findUserByEmail(data.email)
    if (existUser) {
      throw new Error("用户已存在")
    }
    const user = await createUser({
      email: data.email,
      username: data.username,
      passwordHash: data.passwordHash
    })

    return {
      id: user.id,
      email: user.email,
      username: user.username,
      createdAt: user.createdAt
    }
  } catch (error) {
    console.log("用户注册失败", error)
    throw error
  }
}