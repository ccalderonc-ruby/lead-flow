import { Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

import {
  adminNavItems,
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
          ? 'bg-indigo-600 text-white'
          : 'text-slate-300 hover:bg-slate-800 hover:text-white'
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

  function signOut() {
    router.delete('/logout')
  }

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="border-b border-slate-800 px-5 py-6">
        <Link href="/" className="text-xl font-semibold tracking-tight text-white">
          LeadFlow
        </Link>
        <p className="mt-1 text-xs text-slate-400">Advisor CRM</p>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        <p className="px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
          CRM
        </p>
        {mainNavItems.map((item) => (
          <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
        ))}

        {showAdvisorNav && advisorNavItems.length > 0 && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
              Account
            </p>
            {advisorNavItems.map((item) => (
              <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
            ))}
          </>
        )}

        {showAdminNav && (
          <>
            <p className="mt-6 px-3 pb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
              Admin
            </p>
            {adminNavItems.map((item) => (
              <NavLink key={item.href} href={item.href} label={item.label} currentUrl={currentUrl} />
            ))}
          </>
        )}
      </nav>

      {user && (
        <div className="border-t border-slate-800 px-4 py-4">
          <p className="truncate text-sm font-medium text-white">{user.name}</p>
          <p className="text-xs text-slate-400">{formatRoleLabel(user.role)}</p>
          <button
            type="button"
            onClick={signOut}
            className="mt-3 w-full rounded-lg border border-slate-600 px-3 py-2 text-sm font-medium text-slate-200 hover:bg-slate-800"
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  )

  return (
    <div className="min-h-screen bg-slate-100">
      <div className="lg:flex">
        <aside className="hidden w-64 shrink-0 bg-slate-900 lg:fixed lg:inset-y-0 lg:flex lg:flex-col">
          {sidebar}
        </aside>

        {mobileNavOpen && (
          <div className="fixed inset-0 z-40 lg:hidden">
            <button
              type="button"
              aria-label="Close navigation"
              className="absolute inset-0 bg-slate-900/50"
              onClick={() => setMobileNavOpen(false)}
            />
            <aside className="relative h-full w-64 bg-slate-900 shadow-xl">{sidebar}</aside>
          </div>
        )}

        <div className="flex min-h-screen min-w-0 flex-1 flex-col lg:pl-64">
          <header className="sticky top-0 z-30 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 lg:px-8">
            <button
              type="button"
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 lg:hidden"
              onClick={() => setMobileNavOpen(true)}
            >
              Menu
            </button>
            {user && (
              <div className="ml-auto text-right text-sm lg:hidden">
                <p className="font-medium text-slate-900">{user.name}</p>
                <p className="text-slate-500">{formatRoleLabel(user.role)}</p>
              </div>
            )}
          </header>

          <main className="min-w-0 flex-1 px-4 py-6 lg:px-8 lg:py-8">
            {flash?.notice && (
              <p className="mb-4 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-800">
                {flash.notice}
              </p>
            )}
            {flash?.alert && (
              <p className="mb-4 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-800">
                {flash.alert}
              </p>
            )}
            {children}
          </main>
        </div>
      </div>
    </div>
  )
}
