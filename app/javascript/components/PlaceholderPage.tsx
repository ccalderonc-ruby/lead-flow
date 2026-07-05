import { Head } from '@inertiajs/react'

type PlaceholderPageProps = {
  title: string
  description?: string
}

export default function PlaceholderPage({ title, description }: PlaceholderPageProps) {
  return (
    <div>
      <Head title={title} />
      <h1 className="text-2xl font-semibold text-slate-900">{title}</h1>
      <p className="mt-2 text-slate-600">{description ?? 'Coming in a future story.'}</p>
    </div>
  )
}
