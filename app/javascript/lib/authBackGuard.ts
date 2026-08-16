const GUARD_KEY = 'lf_auth_back_guard'
const SEEDED_KEY = 'lf_auth_back_guard_seeded'

/** Call right before a successful sign-in so Back has nowhere to go yet. */
export function armAuthBackGuard() {
  try {
    sessionStorage.setItem(GUARD_KEY, '1')
    sessionStorage.removeItem(SEEDED_KEY)
  } catch {
    // sessionStorage may be unavailable (private mode quirks); ignore.
  }
}

export function clearAuthBackGuard() {
  try {
    sessionStorage.removeItem(GUARD_KEY)
    sessionStorage.removeItem(SEEDED_KEY)
  } catch {
    // ignore
  }
}

export function isAuthBackGuardArmed(): boolean {
  try {
    return sessionStorage.getItem(GUARD_KEY) === '1'
  } catch {
    return false
  }
}

export function seedAuthBackGuardHistory() {
  try {
    if (!isAuthBackGuardArmed()) return
    if (sessionStorage.getItem(SEEDED_KEY) === '1') return
    window.history.pushState({ lfAuthGuard: true }, '', window.location.href)
    sessionStorage.setItem(SEEDED_KEY, '1')
  } catch {
    // ignore
  }
}

/** Keep the user on the post-login page when they hit Back. */
export function holdAuthBackGuard() {
  if (!isAuthBackGuardArmed()) return
  try {
    window.history.pushState({ lfAuthGuard: true }, '', window.location.href)
  } catch {
    // ignore
  }
}
