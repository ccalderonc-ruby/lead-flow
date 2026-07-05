import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function DashboardIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Dashboard"
        description="Summary metrics arrive in Story 1.5."
      />
    </AuthenticatedPage>
  )
}
