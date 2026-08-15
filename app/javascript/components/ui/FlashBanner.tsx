import { useEffect, useState } from 'react'

type FlashBannerProps = {
  notice?: string
  alert?: string
}

export default function FlashBanner({ notice, alert }: FlashBannerProps) {
  const [dismissedNotice, setDismissedNotice] = useState(false)
  const [dismissedAlert, setDismissedAlert] = useState(false)

  useEffect(() => {
    setDismissedNotice(false)
    setDismissedAlert(false)
  }, [notice, alert])

  const showNotice = Boolean(notice) && !dismissedNotice
  const showAlert = Boolean(alert) && !dismissedAlert

  if (!showNotice && !showAlert) return null

  return (
    <div className="mb-4 space-y-2" aria-live="polite">
      {showNotice && (
        <div className="flex items-start justify-between gap-3 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
          <p>{notice}</p>
          <button
            type="button"
            onClick={() => setDismissedNotice(true)}
            className="shrink-0 text-emerald-700 hover:text-emerald-900"
            aria-label="Dismiss notice"
          >
            ×
          </button>
        </div>
      )}
      {showAlert && (
        <div className="flex items-start justify-between gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-900" role="alert">
          <p>{alert}</p>
          <button
            type="button"
            onClick={() => setDismissedAlert(true)}
            className="shrink-0 text-red-700 hover:text-red-900"
            aria-label="Dismiss alert"
          >
            ×
          </button>
        </div>
      )}
    </div>
  )
}
