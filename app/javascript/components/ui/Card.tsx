import type { HTMLAttributes, ReactNode } from 'react'

type CardProps = {
  children: ReactNode
  className?: string
  padding?: 'none' | 'sm' | 'md'
} & Omit<HTMLAttributes<HTMLDivElement>, 'className' | 'children'>

const paddingClass = {
  none: '',
  sm: 'p-4',
  md: 'p-5',
} as const

export default function Card({ children, className, padding = 'md', ...rest }: CardProps) {
  return (
    <div
      className={[
        'rounded-xl border border-slate-200 bg-panel shadow-sm',
        paddingClass[padding],
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      {...rest}
    >
      {children}
    </div>
  )
}
