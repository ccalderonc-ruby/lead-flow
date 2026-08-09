export type NavItem = {
  label: string
  href: string
}

export const mainNavItems: NavItem[] = [
  { label: 'Dashboard', href: '/' },
  { label: 'Leads', href: '/leads' },
  { label: 'Tasks', href: '/tasks' },
  { label: 'Meetings', href: '/meetings' },
  { label: 'Notes', href: '/notes' },
  { label: 'Opportunities', href: '/opportunities' },
]

export const advisorNavItems: NavItem[] = [
  { label: 'Assistants', href: '/assistants' },
]

const sharedAdminNavItems: NavItem[] = [
  { label: 'Users', href: '/admin/users' },
  { label: 'Roles', href: '/admin/roles' },
]

const billingAdminNavItems: NavItem[] = [
  { label: 'Subscriptions', href: '/admin/subscriptions' },
]

/** @deprecated Prefer adminNavItemsFor(role) — kept for tests/imports that expect a static list. */
export const adminNavItems: NavItem[] = [...sharedAdminNavItems, ...billingAdminNavItems]

export function adminNavItemsFor(role: string | undefined): NavItem[] {
  if (role === 'billing_admin') {
    return [...sharedAdminNavItems, ...billingAdminNavItems]
  }
  if (role === 'admin') {
    return [...sharedAdminNavItems]
  }
  return []
}

export function adminNavVisible(role: string | undefined): boolean {
  return role === 'admin' || role === 'billing_admin'
}

export function advisorNavVisible(role: string | undefined): boolean {
  return role === 'advisor' || role === 'admin' || role === 'billing_admin'
}

export function formatRoleLabel(role: string): string {
  if (role === 'billing_admin') return 'Billing admin'
  return role.charAt(0).toUpperCase() + role.slice(1)
}

export function isNavItemActive(href: string, currentUrl: string): boolean {
  if (href === '/') {
    return currentUrl === '/' || currentUrl === ''
  }

  return currentUrl === href || currentUrl.startsWith(`${href}/`)
}
