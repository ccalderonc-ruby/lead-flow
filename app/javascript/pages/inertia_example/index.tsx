import { Head, router, usePage } from '@inertiajs/react'
import { version as react_version } from 'react'

import railsSvg from '/assets/rails.svg'
import inertiaSvg from '/assets/inertia.svg'
import reactSvg from '/assets/react.svg'

import type { SharedProps } from '@/types'

import cs from './index.module.css'

export default function InertiaExample(
  { rails_version, ruby_version, rack_version, inertia_rails_version }:
  { rails_version: string, ruby_version: string, rack_version: string, inertia_rails_version: string }
) {
  const { auth, flash } = usePage<SharedProps>().props

  return (
    <div className={cs.root}>
      <Head title="Ruby on Rails + Inertia + React" />

      {flash.notice && (
        <p className="mx-auto mb-4 max-w-3xl rounded-lg bg-green-50 px-4 py-3 text-sm text-green-800">
          {flash.notice}
        </p>
      )}

      {auth.user && (
        <div className="mx-auto mb-6 flex max-w-3xl items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm">
          <span>
            Signed in as <strong>{auth.user.name}</strong> ({auth.user.role})
          </span>
          <button
            type="button"
            onClick={() => router.delete('/logout')}
            className="rounded-lg border border-slate-300 px-3 py-1.5 hover:bg-slate-50"
          >
            Sign out
          </button>
        </div>
      )}

      <nav className={cs.subNav}>
        <a href="https://rubyonrails.org" target="_blank">
          <img  className={`${cs.logo} ${cs.rails}`} alt="Ruby on Rails Logo" src={railsSvg} />
        </a>
        <a href="https://inertia-rails.dev" target="_blank">
          <img className={`${cs.logo} ${cs.inertia}`} src={inertiaSvg} alt="Inertia logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img
            className={`${cs.logo} ${cs.react}`}
            src={reactSvg}
            alt="React logo"
          />
        </a>
      </nav>

      <div className={cs.footer}>
        <div className={cs.card}>
          <p>
            Edit <code>app/javascript/pages/inertia_example/index.tsx</code> and save to test <abbr title="Hot Module Replacement">HMR</abbr>.
          </p>
        </div>

        <ul>
          <li>
            <ul>
              <li><strong>Rails version:</strong> {rails_version}</li>
              <li><strong>Rack version:</strong> {rack_version}</li>
            </ul>
          </li>
          <li><strong>Ruby version:</strong> {ruby_version}</li>
          <li>
            <ul>
              <li><strong>Inertia Rails version:</strong> {inertia_rails_version}</li>
              <li><strong>React version:</strong> {react_version}</li>
            </ul>
          </li>
          </ul>
      </div>
    </div>
  )
}
