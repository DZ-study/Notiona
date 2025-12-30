import 'dotenv/config'
import express from 'express'
import prisma from './config/prisma'
import bodyParser from 'body-parser'
import { registerRoutes } from './routes'


const app = express()

app.use(bodyParser.json())

// 注册路由
registerRoutes(app)

app.get('/health', (_req, res) => {
  res.json({
    ok: true
  })
})

app.get("/db-check", async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, error: err });
  }
});

app.get('/users', async(_req, res) => {
  const users = await prisma.user.findMany()
  res.json(users)
})

app.listen(3001, () => {
  console.log('Server running on http://localhost:3001')
})