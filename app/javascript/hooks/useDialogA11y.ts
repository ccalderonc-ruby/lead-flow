import { RefObject, useEffect, useLayoutEffect, useRef } from 'react'

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'textarea:not([disabled])',
  'input:not([disabled]):not([type="hidden"])',
  'select:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ')

type DialogStackEntry = {
  id: symbol
  onClose: () => void
}

/** Topmost open dialog owns Escape and Tab trapping (supports nested modals). */
const dialogStack: DialogStackEntry[] = []

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
 * Nested dialogs: only the topmost stack entry handles Escape / Tab.
 * Intentional useLayoutEffect/useEffect — dialog behavior, not form prop sync.
 */
export function useDialogA11y({ open, onClose, containerRef }: UseDialogA11yOptions) {
  const onCloseRef = useRef(onClose)
  onCloseRef.current = onClose
  const previousFocusRef = useRef<HTMLElement | null>(null)
  const stackIdRef = useRef(Symbol('dialog-a11y'))

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

    const entry: DialogStackEntry = {
      id: stackIdRef.current,
      onClose: () => onCloseRef.current(),
    }
    dialogStack.push(entry)

    function isTopmost() {
      return dialogStack[dialogStack.length - 1]?.id === entry.id
    }

    function onKeyDown(event: KeyboardEvent) {
      if (!isTopmost()) return

      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopPropagation()
        entry.onClose()
        return
      }

      if (event.key !== 'Tab') return

      const container = containerRef.current
      if (!container) {
        event.preventDefault()
        return
      }

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
    return () => {
      const index = dialogStack.findIndex((item) => item.id === entry.id)
      if (index >= 0) dialogStack.splice(index, 1)
      document.removeEventListener('keydown', onKeyDown)
    }
  }, [open, containerRef])
}
