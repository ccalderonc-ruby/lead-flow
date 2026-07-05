import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function AdminRolesIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Roles"
        description="Role management arrives in Epic 5."
      />
    </AuthenticatedPage>
  )
}
