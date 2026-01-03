import prisma from '@/lib/prisma'
import type { Prisma } from "@/generated/prisma/client";

export function createUser(data: Prisma.UserCreateInput) {
  return prisma.user.create({ data })
}

export async function findUserByEmail(email: string) {
  return prisma.user.findUnique({
    where: { email }
  })
}

export async function updateUserProfile(id: string, data: Prisma.UserUpdateInput) {
  return prisma.user.update({
    where: { id },
    data
  })
}