import { RefObject, useEffect, useLayoutEffect, useRef } from 'react'

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'textarea:not([disabled])',
  'input:not([disabled]):not([type="hidden"])',
  'select:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ')

function focusableElements(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR))
}

function dialogRoot(container: HTMLElement): HTMLElement {
  return container.querySelector<HTMLElement>('[role="dialog"], [role="alertdialog"]') ?? container
}

type UseDialogA11yOptions = {
  open: boolean
  onClose: () => void
  containerRef: RefObject<HTMLElement | null>
}

/**
 * Escape to close, initial focus, Tab cycle, restore focus on close.
 * Intentional useLayoutEffect/useEffect — dialog behavior, not form prop sync.
 */
export function useDialogA11y({ open, onClose, containerRef }: UseDialogA11yOptions) {
  const onCloseRef = useRef(onClose)
  onCloseRef.current = onClose
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useLayoutEffect(() => {
    if (!open) return

    const container = containerRef.current
    if (!container) return

    previousFocusRef.current =
      document.activeElement instanceof HTMLElement ? document.activeElement : null

    const root = dialogRoot(container)
    if (!root.hasAttribute('tabindex')) {
      root.tabIndex = -1
    }

    const focusable = focusableElements(root)
    ;(focusable[0] ?? root).focus()

    return () => {
      const previous = previousFocusRef.current
      previousFocusRef.current = null
      if (previous && document.contains(previous)) {
        previous.focus()
      }
    }
  }, [open, containerRef])

  useEffect(() => {
    if (!open) return

    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        event.preventDefault()
        onCloseRef.current()
        return
      }

      if (event.key !== 'Tab') return

      const container = containerRef.current
      if (!container) return

      const root = dialogRoot(container)
      const focusable = focusableElements(root)
      if (focusable.length === 0) {
        event.preventDefault()
        root.focus()
        return
      }

      const first = focusable[0]
      const last = focusable[focusable.length - 1]
      const active = document.activeElement

      if (event.shiftKey) {
        if (active === first || !root.contains(active)) {
          event.preventDefault()
          last.focus()
        }
      } else if (active === last || !root.contains(active)) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [open, containerRef])
}
