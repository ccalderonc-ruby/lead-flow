import { ChangeEvent, InputHTMLAttributes, ReactNode, TextareaHTMLAttributes } from 'react'

const fieldClassName =
  'mt-1 block w-full rounded-lg border border-slate-300 bg-panel px-3 py-2 text-sm text-slate-900 focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand-muted'

const fieldErrorClassName =
  'mt-1 block w-full rounded-lg border border-red-300 bg-panel px-3 py-2 text-sm text-slate-900 focus:border-red-500 focus:outline-none focus:ring-2 focus:ring-red-200'

export function RequiredMark() {
  return (
    <span className="text-red-600" aria-hidden="true">
      {' '}
      *
    </span>
  )
}

type FieldErrorProps = {
  error?: string | null
}

export function FieldError({ error }: FieldErrorProps) {
  if (!error) return null
  return (
    <p className="mt-1 text-sm text-red-600" role="alert">
      {error}
    </p>
  )
}

export function FormErrorBanner({ message }: { message?: string | null }) {
  if (!message) return null
  return (
    <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
      {message}
    </p>
  )
}

export function RequiredFieldsHint() {
  return (
    <p className="text-sm text-slate-500">
      Required fields are marked with <RequiredMark />
    </p>
  )
}

type TextFieldProps = {
  id: string
  label: string
  required?: boolean
  error?: string | null
  value: string
  onChange: (value: string) => void
  prefix?: string
} & Omit<InputHTMLAttributes<HTMLInputElement>, 'id' | 'value' | 'onChange'>

export function TextField({
  id,
  label,
  required = false,
  error,
  value,
  onChange,
  type = 'text',
  prefix,
  className,
  ...rest
}: TextFieldProps) {
  const inputClassName = [
    error ? fieldErrorClassName : fieldClassName,
    prefix ? 'pl-7' : null,
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-slate-700">
        {label}
        {required && <RequiredMark />}
      </label>
      <div className="relative">
        {prefix ? (
          <span className="pointer-events-none absolute inset-y-0 left-0 mt-1 flex items-center pl-3 text-sm text-slate-500">
            {prefix}
          </span>
        ) : null}
        <input
          id={id}
          type={type}
          value={value}
          onChange={(event: ChangeEvent<HTMLInputElement>) => onChange(event.target.value)}
          className={inputClassName}
          aria-invalid={error ? true : undefined}
          aria-required={required || undefined}
          {...rest}
        />
      </div>
      <FieldError error={error} />
    </div>
  )
}

type TextAreaFieldProps = {
  id: string
  label: string
  required?: boolean
  error?: string | null
  value: string
  onChange: (value: string) => void
  rows?: number
} & Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'id' | 'value' | 'onChange'>

export function TextAreaField({
  id,
  label,
  required = false,
  error,
  value,
  onChange,
  rows = 5,
  ...rest
}: TextAreaFieldProps) {
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-slate-700">
        {label}
        {required && <RequiredMark />}
      </label>
      <textarea
        id={id}
        rows={rows}
        value={value}
        onChange={(event: ChangeEvent<HTMLTextAreaElement>) => onChange(event.target.value)}
        className={error ? fieldErrorClassName : fieldClassName}
        aria-invalid={error ? true : undefined}
        aria-required={required || undefined}
        {...rest}
      />
      <FieldError error={error} />
    </div>
  )
}

type SelectFieldProps = {
  id: string
  label: string
  required?: boolean
  error?: string | null
  value: string
  onChange: (value: string) => void
  disabled?: boolean
  children: ReactNode
}

export function SelectField({
  id,
  label,
  required = false,
  error,
  value,
  onChange,
  disabled = false,
  children,
}: SelectFieldProps) {
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-slate-700">
        {label}
        {required && <RequiredMark />}
      </label>
      <select
        id={id}
        value={value}
        disabled={disabled}
        onChange={(event: ChangeEvent<HTMLSelectElement>) => onChange(event.target.value)}
        className={error ? fieldErrorClassName : fieldClassName}
        aria-invalid={error ? true : undefined}
        aria-required={required || undefined}
      >
        {children}
      </select>
      <FieldError error={error} />
    </div>
  )
}
