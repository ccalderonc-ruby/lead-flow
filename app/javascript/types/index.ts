export type FlashData = {
  notice?: string
  alert?: string
}

export type AuthUser = {
  id: number
  name: string
  email: string
  role: string
  subscription_status?: string
  subscribed?: boolean
}

export type SharedProps = {
  auth: {
    user: AuthUser | null
  }
  flash: FlashData
}

export type * from './leads'
