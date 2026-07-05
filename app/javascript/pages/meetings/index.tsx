import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function MeetingsIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Meetings"
        description="Meeting scheduling arrives in Epic 4."
      />
    </AuthenticatedPage>
  )
}
