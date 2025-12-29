import { api } from ".";

export type TLoginPayload = {
  email: string,
  password_hash: string
}

export const login = (data: TLoginPayload) => api.post('/auth/login', data)

export const getCurrentUser = () => api.get('/auth/me')

export const register = (data: { name: string; email: string; password: string }) => 
  api.post('/auth/register', data)