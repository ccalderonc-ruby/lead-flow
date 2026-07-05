import AuthenticatedPage from '@/components/layouts/AuthenticatedPage'
import PlaceholderPage from '@/components/PlaceholderPage'

export default function TasksIndex() {
  return (
    <AuthenticatedPage>
      <PlaceholderPage
        title="Tasks"
        description="Task management arrives in Epic 3."
      />
    </AuthenticatedPage>
  )
}
