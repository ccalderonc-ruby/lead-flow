import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function AdminUsersIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Users"
        description="User management arrives in Epic 5."
      />
    </AuthenticatedPage>
  )
}
