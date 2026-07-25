export type NavItem = {
  label: string
  href: string
}

export const mainNavItems: NavItem[] = [
  { label: 'Dashboard', href: '/' },
  { label: 'Leads', href: '/leads' },
  { label: 'Tasks', href: '/tasks' },
  { label: 'Meetings', href: '/meetings' },
  { label: 'Opportunities', href: '/opportunities' },
]

export const advisorNavItems: NavItem[] = [
  { label: 'Subscription', href: '/settings/subscription' },
]

export const adminNavItems: NavItem[] = [
  { label: 'Users', href: '/admin/users' },
  { label: 'Roles', href: '/admin/roles' },
]

export function adminNavVisible(role: string | undefined): boolean {
  return role === 'admin'
}

export function advisorNavVisible(role: string | undefined): boolean {
  return role === 'advisor'
}

export function formatRoleLabel(role: string): string {
  return role.charAt(0).toUpperCase() + role.slice(1)
}

export function isNavItemActive(href: string, currentUrl: string): boolean {
  if (href === '/') {
    return currentUrl === '/' || currentUrl === ''
  }

  return currentUrl === href || currentUrl.startsWith(`${href}/`)
}
