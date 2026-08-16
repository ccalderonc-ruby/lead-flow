import Card from '@/components/ui/Card'

type MetricCardProps = {
  label: string
  value: string
  hint?: string
  accentClassName?: string
}

export default function MetricCard({
  label,
  value,
  hint,
  accentClassName = 'bg-brand',
}: MetricCardProps) {
  return (
    <Card>
      <div className="flex items-start justify-between gap-3">
        <p className="text-sm font-medium text-slate-500">{label}</p>
        <span className={`mt-1 h-2.5 w-2.5 shrink-0 rounded-full ${accentClassName}`} aria-hidden />
      </div>
      <p className="mt-2 text-3xl font-semibold tracking-tight text-ink">{value}</p>
      {hint && <p className="mt-1 text-xs text-slate-500">{hint}</p>}
    </Card>
  )
}
