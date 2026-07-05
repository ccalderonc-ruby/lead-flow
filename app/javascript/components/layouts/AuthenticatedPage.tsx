import type { ReactNode } from 'react'

import AppLayout from '@/components/layouts/AppLayout'

type AuthenticatedPageProps = {
  children: ReactNode
}

export default function AuthenticatedPage({ children }: AuthenticatedPageProps) {
  return <AppLayout>{children}</AppLayout>
}
