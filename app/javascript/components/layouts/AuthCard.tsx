import { Head, usePage } from '@inertiajs/react'
import type { ReactNode } from 'react'

import Card from '@/components/ui/Card'
import FlashBanner from '@/components/ui/FlashBanner'
import ThemeToggle from '@/components/ui/ThemeToggle'
import type { SharedProps } from '@/types'

type AuthCardProps = {
  title: string
  subtitle?: string
  children: ReactNode
}

export default function AuthCard({ title, subtitle, children }: AuthCardProps) {
  const { flash } = usePage<SharedProps>().props

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-surface px-4">
      <Head title={title} />
      <div className="absolute right-4 top-4">
        <ThemeToggle />
      </div>

      <Card className="w-full max-w-md p-8" padding="none">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-ink">LeadFlow</h1>
          {subtitle ? <p className="mt-2 text-sm text-slate-600">{subtitle}</p> : null}
        </div>

        <FlashBanner notice={flash?.notice} alert={flash?.alert} />

        {children}
      </Card>
    </div>
  )
}
