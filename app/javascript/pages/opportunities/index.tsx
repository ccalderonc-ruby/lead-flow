import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function OpportunitiesIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Opportunities"
        description="Pipeline view arrives in Epic 4."
      />
    </AuthenticatedPage>
  )
}
