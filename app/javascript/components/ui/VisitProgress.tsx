import { router } from '@inertiajs/react'
import { useEffect, useState } from 'react'

/** Thin top progress bar for Inertia page visits (U1 loading feedback). */
export default function VisitProgress() {
  const [active, setActive] = useState(false)

  useEffect(() => {
    const removeStart = router.on('start', () => setActive(true))
    const removeFinish = router.on('finish', () => setActive(false))
    const removeError = router.on('error', () => setActive(false))

    return () => {
      removeStart()
      removeFinish()
      removeError()
    }
  }, [])

  if (!active) return null

  return (
    <div
      className="pointer-events-none fixed inset-x-0 top-0 z-[60] h-0.5 overflow-hidden bg-indigo-100"
      role="progressbar"
      aria-label="Loading page"
      aria-busy="true"
    >
      <div className="h-full w-1/3 animate-pulse bg-indigo-600" />
    </div>
  )
}
