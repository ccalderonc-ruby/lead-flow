type ActiveFiltersProps = {
  labels: string[]
  onClear: () => void
  clearLabel?: string
}

/** Chip row showing active filters with a clear action. */
export default function ActiveFilters({
  labels,
  onClear,
  clearLabel = 'Clear all',
}: ActiveFiltersProps) {
  if (labels.length === 0) return null

  return (
    <div className="flex flex-wrap items-center gap-2">
      <p className="text-sm text-slate-600">Active filters:</p>
      {labels.map((label) => (
        <span
          key={label}
          className="inline-flex rounded-full bg-brand-subtle px-2.5 py-1 text-xs font-medium text-brand-ink"
        >
          {label}
        </span>
      ))}
      <button
        type="button"
        onClick={onClear}
        className="inline-flex min-h-11 items-center px-1 text-sm font-medium text-brand-ink hover:text-brand"
      >
        {clearLabel}
      </button>
    </div>
  )
}
