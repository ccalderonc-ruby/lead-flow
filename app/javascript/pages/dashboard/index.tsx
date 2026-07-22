import { Head } from '@inertiajs/react'

import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import MetricCard from '@/components/dashboard/MetricCard'
import { formatCurrency } from '@/lib/format'

export type DashboardMetrics = {
  open_leads: number
  overdue_tasks: number
  upcoming_meetings: number
  pipeline_value: number
}

type DashboardIndexProps = {
  metrics: DashboardMetrics
}

export default function DashboardIndex({ metrics }: DashboardIndexProps) {
  return (
    <AuthenticatedPage>
      <Head title="Dashboard" />

      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Dashboard</h1>
        <p className="mt-1 text-slate-600">Your pipeline at a glance.</p>

        <div className="mt-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <MetricCard
            label="Open leads"
            value={String(metrics.open_leads)}
            hint="Excludes closed stage"
          />
          <MetricCard
            label="Overdue tasks"
            value={String(metrics.overdue_tasks)}
            hint="Past due and not completed"
          />
          <MetricCard
            label="Upcoming meetings"
            value={String(metrics.upcoming_meetings)}
            hint="Next 7 days"
          />
          <MetricCard
            label="Pipeline value"
            value={formatCurrency(metrics.pipeline_value)}
            hint="Active opportunities"
          />
        </div>
      </div>
    </AuthenticatedPage>
  )
}

export type DashboardPageProps = DashboardIndexProps
