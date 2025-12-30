import type { Express } from "express"
import userRouter from '@/modules/user/user.route'

export function registerRoutes(app: Express) {
  app.use("/users", userRouter)
}