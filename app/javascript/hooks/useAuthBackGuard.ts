import { usePage } from '@inertiajs/react'
import { useEffect, useRef } from 'react'

import {
  clearAuthBackGuard,
  holdAuthBackGuard,
  isAuthBackGuardArmed,
  seedAuthBackGuardHistory,
} from '@/lib/authBackGuard'

/**
 * After a fresh sign-in, browser Back should no-op until the user navigates
 * somewhere else in the app (so they don't fall through to pre-login history).
 */
export function useAuthBackGuard() {
  const url = usePage().url
  const landingUrl = useRef(url)
  const armed = useRef(isAuthBackGuardArmed())

  useEffect(() => {
    if (!armed.current) return

    seedAuthBackGuardHistory()

    function onPopState() {
      holdAuthBackGuard()
    }

    window.addEventListener('popstate', onPopState)
    return () => window.removeEventListener('popstate', onPopState)
  }, [])

  useEffect(() => {
    if (!armed.current) return
    if (url === landingUrl.current) return

    clearAuthBackGuard()
    armed.current = false
  }, [url])
}
