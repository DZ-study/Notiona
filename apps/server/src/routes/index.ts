import type { Express } from "express"
import userRouter from './user'

export function registerRoutes(app: Express) {
  app.use("/users", userRouter)
}