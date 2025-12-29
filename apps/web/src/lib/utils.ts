import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export const getToken = () => {
  return localStorage.getItem('token')
}

export const removeToken = () =>{
  localStorage.removeItem('token')
}

export const setToken = (token: string) => {
  localStorage.setItem('token', token)
}