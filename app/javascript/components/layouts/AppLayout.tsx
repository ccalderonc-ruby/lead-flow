import { Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import FlashBanner from '@/components/ui/FlashBanner'
import ThemeToggle from '@/components/ui/ThemeToggle'
import VisitProgress from '@/components/ui/VisitProgress'
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

function NavLink({ href, label, currentUrl }: { href: string; label: string; currentUrl: string }) {
  const active = isNavItemActive(href, currentUrl)

  return (
    <Link
      href={href}
      className={`block rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
        active
          ? 'bg-brand text-white'
          : 'text-indigo-200 hover:bg-sidebar-hover hover:text-white'
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

  const user = auth.user
  const showAdminNav = adminNavVisible(user?.role)
  const showAdvisorNav = advisorNavVisible(user?.role)
  const adminItems = adminNavItemsFor(user?.role)

  function signOut() {
    router.delete('/logout')
  }

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="border-b border-sidebar-border px-5 py-6">
        <Link href="/" className="text-xl font-semibold tracking-tight text-white">
          LeadFlow
        </Link>
        <p className="mt-1 text-xs text-indigo-300">Advisor CRM</p>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        <p className="px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-400">
          CRM
        </p>
        {mainNavItems.map((item) => (
          <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
        ))}

        {showAdvisorNav && advisorNavItems.length > 0 && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-400">
              Account
            </p>
            {advisorNavItems.map((item) => (
              <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
            ))}
          </>
        )}

        {showAdminNav && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-indigo-400">
              Admin
            </p>
            {adminItems.map((item) => (
              <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
            ))}
          </>
        )}
      </nav>

      {user && (
        <div className="border-t border-sidebar-border px-4 py-4">
          <p className="truncate text-sm font-medium text-white">{user.name}</p>
          <p className="text-xs text-indigo-300">{formatRoleLabel(user.role)}</p>
          <button
            type="button"
            onClick={signOut}
            className="mt-3 w-full rounded-lg border border-indigo-400/40 px-3 py-2 text-sm font-medium text-indigo-100 hover:bg-sidebar-hover"
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
          <div className="fixed inset-0 z-40 lg:hidden">
            <button
              type="button"
              aria-label="Close navigation"
              className="absolute inset-0 bg-sidebar/50"
              onClick={() => setMobileNavOpen(false)}
            />
            <aside className="relative h-full w-64 bg-sidebar shadow-xl">{sidebar}</aside>
          </div>
        )}

        <div className="flex min-h-screen min-w-0 flex-1 flex-col lg:pl-64">
          <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-slate-200 bg-panel px-4 py-3 lg:px-8">
            <button
              type="button"
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 lg:hidden"
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
