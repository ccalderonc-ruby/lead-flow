export type ColorScheme = 'light' | 'dark'

export const COLOR_SCHEME_STORAGE_KEY = 'leadflow-color-scheme'

export function getPreferredColorScheme(): ColorScheme {
  if (typeof window === 'undefined') return 'light'

  const stored = window.localStorage.getItem(COLOR_SCHEME_STORAGE_KEY)
  if (stored === 'light' || stored === 'dark') return stored

  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export function applyColorScheme(scheme: ColorScheme) {
  const root = document.documentElement
  root.classList.toggle('dark', scheme === 'dark')
  root.dataset.colorScheme = scheme
  root.style.colorScheme = scheme
}

export function setColorScheme(scheme: ColorScheme) {
  window.localStorage.setItem(COLOR_SCHEME_STORAGE_KEY, scheme)
  applyColorScheme(scheme)
}

export function toggleColorScheme(): ColorScheme {
  const next: ColorScheme = getPreferredColorScheme() === 'dark' ? 'light' : 'dark'
  setColorScheme(next)
  return next
}
