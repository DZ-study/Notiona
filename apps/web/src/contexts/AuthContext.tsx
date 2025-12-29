import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { login as authLogin, getCurrentUser } from '@/api/auth'
import { getToken, removeToken, setToken } from '@/lib/utils'

interface User {
  id: string
  name: string
  email: string
}

interface AuthProviderProps {
  children: ReactNode
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)


  const checkAuth = async () => {
    try {
      const token = getToken()
      if (token) {
        const response = await getCurrentUser()
        setUser(response.data.user)
      }
    } catch (error) {
      console.log('权限校验失败', error)
      removeToken()
    }
     finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    checkAuth()
  }, [])

  const login = async (email: string, password_hash: string) => {
    const response = await authLogin({ email, password_hash })
    const { token, user } = response.data
    setToken(token)
    setUser(user)
  }



}
