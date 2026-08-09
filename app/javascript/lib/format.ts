export function formatCurrency(amount: string | number | null | undefined): string {
  if (amount == null || amount === '') return '—'
  const value = typeof amount === 'number' ? amount : Number(amount)
  if (Number.isNaN(value)) return '—'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value)
}

/** Format a USD amount for text inputs with thousand separators (keeps up to 2 decimals while typing). */
export function formatUsdInput(raw: string | number | null | undefined): string {
  if (raw == null || raw === '') return ''

  if (typeof raw === 'number') {
    if (Number.isNaN(raw)) return ''
    return formatUsdInput(raw.toFixed(2))
  }

  const cleaned = String(raw).replace(/[^\d.]/g, '')
  if (cleaned === '') return ''

  const hasDecimal = cleaned.includes('.')
  const [intPart = '', ...fractionParts] = cleaned.split('.')
  const fraction = fractionParts.join('').slice(0, 2)
  const groupedInt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',')

  if (hasDecimal) return `${groupedInt}.${fraction}`
  return groupedInt
}

/** Strip grouping commas from a USD input before submit. */
export function parseUsdInput(formatted: string): string {
  const cleaned = formatted.replace(/,/g, '').trim()
  if (cleaned === '' || cleaned === '.') return ''
  return cleaned
}

/** Date-only ISO (`YYYY-MM-DD`) or datetime ISO → short US date. */
export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—'

  if (/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    const [year, month, day] = iso.split('-').map(Number)
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(Date.UTC(year, month - 1, day)))
  }

  const parsed = new Date(iso)
  if (Number.isNaN(parsed.getTime())) return '—'

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(parsed)
}

/** True when a date-only / ISO due date is before today (local calendar day). */
export function isPastDueDate(iso: string | null | undefined): boolean {
  if (!iso) return false

  const today = new Date()
  const todayUtc = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate())

  if (/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    const [year, month, day] = iso.split('-').map(Number)
    return Date.UTC(year, month - 1, day) < todayUtc
  }

  const parsed = new Date(iso)
  if (Number.isNaN(parsed.getTime())) return false
  return Date.UTC(parsed.getFullYear(), parsed.getMonth(), parsed.getDate()) < todayUtc
}

/** Datetime ISO → short US date + time. */
export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return '—'

  const parsed = new Date(iso)
  if (Number.isNaN(parsed.getTime())) return '—'

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(parsed)
}
