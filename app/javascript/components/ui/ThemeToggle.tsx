import { useEffect, useState } from 'react'

import {
  applyColorScheme,
  getPreferredColorScheme,
  setColorScheme,
  type ColorScheme,
} from '@/lib/theme'

function SunIcon() {
  return (
    <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
    </svg>
  )
}

function MoonIcon() {
  return (
    <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
      <path d="M21 14.5A8.5 8.5 0 1 1 9.5 3 7 7 0 0 0 21 14.5z" />
    </svg>
  )
}

/** Day / night toggle — persists to localStorage and syncs the `html.dark` class. */
export default function ThemeToggle({ className = '' }: { className?: string }) {
  const [scheme, setScheme] = useState<ColorScheme>('light')

  useEffect(() => {
    const initial = getPreferredColorScheme()
    setScheme(initial)
    applyColorScheme(initial)
  }, [])

  function toggle() {
    const next: ColorScheme = scheme === 'dark' ? 'light' : 'dark'
    setColorScheme(next)
    setScheme(next)
  }

  const isDark = scheme === 'dark'

  return (
    <button
      type="button"
      onClick={toggle}
      className={[
        'inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-panel px-3 py-1.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      aria-label={isDark ? 'Switch to day view' : 'Switch to night view'}
      title={isDark ? 'Day view' : 'Night view'}
    >
      {isDark ? <SunIcon /> : <MoonIcon />}
      <span className="hidden sm:inline">{isDark ? 'Day' : 'Night'}</span>
    </button>
  )
}
