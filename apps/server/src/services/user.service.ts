import { UserCreateInput } from './../generated/prisma/models/User';
import prisma from '@/config/prisma'
import { User } from '@/generated/prisma/client'
import type { Prisma } from "@/generated/prisma/client";

export function createUser(data: Prisma.UserCreateInput) {
  prisma.user.create({
    data: {
      email: data.email
    }
  })
}