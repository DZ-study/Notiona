import nodemailer from 'nodemailer'

export const mailer = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
})

// 邮件服务
export const sendMail = async ({
  to,
  subject,
  html
}: {
  to: string,
  subject: string,
  html: string
}) => {
  if (!process.env.MAIL_FROM) {
    throw new Error('MAIL_FROM is not set')
  }

  return mailer.sendMail({
    from: process.env.MAIL_FROM,
    to,
    subject,
    html
  })
}