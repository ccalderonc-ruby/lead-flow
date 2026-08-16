import type { ButtonHTMLAttributes, ReactNode } from 'react'
import { Link } from '@inertiajs/react'

const variants = {
  primary:
    'bg-brand text-white hover:bg-brand-hover disabled:opacity-50 disabled:cursor-not-allowed',
  secondary:
    'border border-slate-300 bg-panel text-slate-700 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed',
  ghost: 'text-brand-ink hover:text-brand disabled:opacity-50 disabled:cursor-not-allowed',
} as const

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-sm',
  lg: 'px-4 py-2.5 text-sm',
} as const

type ButtonVariant = keyof typeof variants
type ButtonSize = keyof typeof sizes

type CommonProps = {
  variant?: ButtonVariant
  size?: ButtonSize
  className?: string
  children: ReactNode
}

type ButtonAsButton = CommonProps & {
  href?: undefined
  type?: ButtonHTMLAttributes<HTMLButtonElement>['type']
  disabled?: boolean
  onClick?: ButtonHTMLAttributes<HTMLButtonElement>['onClick']
  form?: string
  name?: string
  value?: string | number | readonly string[]
}

type ButtonAsLink = CommonProps & {
  href: string
  disabled?: boolean
}

export type ButtonProps = ButtonAsButton | ButtonAsLink

function buttonClassName({
  variant = 'primary',
  size = 'md',
  className,
}: Pick<CommonProps, 'variant' | 'size' | 'className'>) {
  return [
    'inline-flex items-center justify-center rounded-lg font-medium transition-colors',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel',
    variants[variant],
    sizes[size],
    className,
  ]
    .filter(Boolean)
    .join(' ')
}

export default function Button(props: ButtonProps) {
  const { variant = 'primary', size = 'md', className, children } = props
  const classes = buttonClassName({ variant, size, className })

  if ('href' in props && props.href) {
    if (props.disabled) {
      return (
        <span role="link" aria-disabled="true" className={`${classes} pointer-events-none opacity-50`}>
          {children}
        </span>
      )
    }

    return (
      <Link href={props.href} className={classes}>
        {children}
      </Link>
    )
  }

  const { type = 'button', disabled, onClick, form, name, value } = props as ButtonAsButton

  return (
    <button
      type={type}
      className={classes}
      disabled={disabled}
      onClick={onClick}
      form={form}
      name={name}
      value={value}
    >
      {children}
    </button>
  )
}
