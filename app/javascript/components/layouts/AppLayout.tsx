import { Link, router, usePage } from '@inertiajs/react'
import { useEffect, useRef, useState } from 'react'

import FlashBanner from '@/components/ui/FlashBanner'
import ThemeToggle from '@/components/ui/ThemeToggle'
import VisitProgress from '@/components/ui/VisitProgress'
import { useDialogA11y } from '@/hooks/useDialogA11y'
import {
  adminNavItemsFor,
  adminNavVisible,
  advisorNavItems,
  advisorNavVisible,
  formatRoleLabel,
  isNavItemActive,
  mainNavItems,
} from '@/lib/navigation'
import type { SharedProps } from '@/types'

type AppLayoutProps = {
  children: React.ReactNode
}

function NavLink({
  href,
  label,
  currentUrl,
  onNavigate,
}: {
  href: string
  label: string
  currentUrl: string
  onNavigate?: () => void
}) {
  const active = isNavItemActive(href, currentUrl)

  return (
    <Link
      href={href}
      onClick={onNavigate}
      aria-current={active ? 'page' : undefined}
      className={`block rounded-lg px-3 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar ${
        active
          ? 'bg-brand text-white'
          : 'text-indigo-100 hover:bg-sidebar-hover hover:text-white'
      }`}
    >
      {label}
    </Link>
  )
}

export default function AppLayout({ children }: AppLayoutProps) {
  const { auth, flash } = usePage<SharedProps>().props
  const currentUrl = usePage().url
  const [mobileNavOpen, setMobileNavOpen] = useState(false)
  const mobileNavRef = useRef<HTMLDivElement>(null)

  const user = auth.user
  const showAdminNav = adminNavVisible(user?.role)
  const showAdvisorNav = advisorNavVisible(user?.role)
  const adminItems = adminNavItemsFor(user?.role)

  function closeMobileNav() {
    setMobileNavOpen(false)
  }

  function signOut() {
    closeMobileNav()
    router.delete('/logout', { replace: true })
  }

  useEffect(() => {
    closeMobileNav()
  }, [currentUrl])

  useEffect(() => {
    const media = window.matchMedia('(min-width: 1024px)')
    function onChange() {
      if (media.matches) closeMobileNav()
    }
    media.addEventListener('change', onChange)
    return () => media.removeEventListener('change', onChange)
  }, [])

  useDialogA11y({
    open: mobileNavOpen,
    onClose: closeMobileNav,
    containerRef: mobileNavRef,
  })

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="border-b border-sidebar-border px-5 py-6">
        <Link
          href="/"
          onClick={closeMobileNav}
          className="text-xl font-semibold tracking-tight text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar"
        >
          LeadFlow
        </Link>
        <p className="mt-1 text-xs text-indigo-200">Advisor CRM</p>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4" aria-label="Primary">
        <p className="px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-200">
          CRM
        </p>
        {mainNavItems.map((item) => (
          <NavLink
            key={item.href}
            href={item.href}
            label={item.label}
            currentUrl={currentUrl}
            onNavigate={closeMobileNav}
          />
        ))}

        {showAdvisorNav && advisorNavItems.length > 0 && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-200">
              Account
            </p>
            {advisorNavItems.map((item) => (
              <NavLink
                key={item.href}
                href={item.href}
                label={item.label}
                currentUrl={currentUrl}
                onNavigate={closeMobileNav}
              />
            ))}
          </>
        )}

        {showAdminNav && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-200">
              Admin
            </p>
            {adminItems.map((item) => (
              <NavLink
                key={item.href}
                href={item.href}
                label={item.label}
                currentUrl={currentUrl}
                onNavigate={closeMobileNav}
              />
            ))}
          </>
        )}
      </nav>

      {user && (
        <div className="border-t border-sidebar-border px-4 py-4">
          <p className="truncate text-sm font-medium text-white">{user.name}</p>
          <p className="text-xs text-indigo-200">{formatRoleLabel(user.role)}</p>
          <button
            type="button"
            onClick={signOut}
            className="mt-3 w-full rounded-lg border border-indigo-300/50 px-3 py-2 text-sm font-medium text-indigo-50 hover:bg-sidebar-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar"
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  )

  return (
    <div className="min-h-screen bg-surface">
      <VisitProgress />
      <div className="lg:flex">
        <aside className="hidden w-64 shrink-0 bg-sidebar lg:fixed lg:inset-y-0 lg:flex lg:flex-col">
          {sidebar}
        </aside>

        {mobileNavOpen && (
          <div ref={mobileNavRef} className="fixed inset-0 z-40 lg:hidden">
            <button
              type="button"
              tabIndex={-1}
              aria-label="Close navigation"
              className="absolute inset-0 bg-sidebar/50"
              onClick={closeMobileNav}
            />
            <aside
              id="mobile-navigation"
              role="dialog"
              aria-modal="true"
              aria-label="Main navigation"
              className="relative flex h-full w-64 flex-col bg-sidebar shadow-xl"
            >
              <div className="flex justify-end border-b border-sidebar-border px-3 py-2">
                <button
                  type="button"
                  onClick={closeMobileNav}
                  className="inline-flex min-h-11 items-center rounded-lg px-3 text-sm font-medium text-indigo-100 hover:bg-sidebar-hover hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar"
                >
                  Close
                </button>
              </div>
              {sidebar}
            </aside>
          </div>
        )}

        <div className="flex min-h-screen min-w-0 flex-1 flex-col lg:pl-64">
          <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-slate-200 bg-panel px-4 py-3 lg:px-8">
            <button
              type="button"
              className="inline-flex min-h-11 items-center rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium text-slate-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel lg:hidden"
              aria-expanded={mobileNavOpen}
              aria-haspopup="dialog"
              aria-controls={mobileNavOpen ? 'mobile-navigation' : undefined}
              onClick={() => setMobileNavOpen(true)}
            >
              Menu
            </button>
            <div className="ml-auto flex items-center gap-3">
              <ThemeToggle />
              {user && (
                <div className="text-right text-sm lg:hidden">
                  <p className="font-medium text-ink">{user.name}</p>
                  <p className="text-slate-500">{formatRoleLabel(user.role)}</p>
                </div>
              )}
            </div>
          </header>

          <main className="min-w-0 flex-1 px-4 py-6 lg:px-8 lg:py-8">
            <FlashBanner notice={flash?.notice} alert={flash?.alert} />
            {children}
          </main>
        </div>
      </div>
    </div>
  )
}
