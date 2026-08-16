import type { ReactNode, TdHTMLAttributes, ThHTMLAttributes } from 'react'

function cx(...parts: Array<string | false | null | undefined>) {
  return parts.filter(Boolean).join(' ')
}

type DataTableProps = {
  children: ReactNode
  className?: string
}

/** Shared bordered list-table shell used across CRM index pages. */
export function DataTable({ children, className }: DataTableProps) {
  return (
    <div className={cx('overflow-x-auto rounded-xl border border-slate-200 bg-panel', className)}>
      <table className="min-w-full divide-y divide-slate-200 text-left text-sm">{children}</table>
    </div>
  )
}

export function DataTableHead({ children }: { children: ReactNode }) {
  return (
    <thead className="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
      {children}
    </thead>
  )
}

export function DataTableBody({ children }: { children: ReactNode }) {
  return <tbody className="divide-y divide-slate-100">{children}</tbody>
}

type DataTableRowProps = {
  children: ReactNode
  hover?: boolean
  className?: string
}

export function DataTableRow({ children, hover = true, className }: DataTableRowProps) {
  return (
    <tr className={cx(hover && 'hover:bg-slate-50', className)}>
      {children}
    </tr>
  )
}

type Align = 'left' | 'right'

type DataTableHeaderCellProps = ThHTMLAttributes<HTMLTableCellElement> & {
  align?: Align
}

export function DataTableHeaderCell({
  align = 'left',
  className,
  children,
  ...rest
}: DataTableHeaderCellProps) {
  return (
    <th
      {...rest}
      className={cx('px-4 py-3', align === 'right' && 'text-right', className)}
    >
      {children}
    </th>
  )
}

type DataTableCellProps = TdHTMLAttributes<HTMLTableCellElement> & {
  align?: Align
}

export function DataTableCell({
  align = 'left',
  className,
  children,
  ...rest
}: DataTableCellProps) {
  return (
    <td {...rest} className={cx('px-4 py-3', align === 'right' && 'text-right', className)}>
      {children}
    </td>
  )
}

type DataTableEmptyProps = {
  colSpan: number
  children: ReactNode
}

/** Full-width empty row for in-table EmptyState (or other empty content). */
export function DataTableEmpty({ colSpan, children }: DataTableEmptyProps) {
  return (
    <tr>
      <td colSpan={colSpan} className="p-0">
        {children}
      </td>
    </tr>
  )
}
