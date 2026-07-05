import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function LeadsIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Leads"
        description="Lead list and search arrive in Epic 2."
      />
    </AuthenticatedPage>
  )
}
