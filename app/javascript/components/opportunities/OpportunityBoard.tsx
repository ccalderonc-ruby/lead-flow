import {
  DndContext,
  DragOverlay,
  PointerSensor,
  closestCorners,
  useDroppable,
  useDraggable,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { CSS } from '@dnd-kit/utilities'
import { router } from '@inertiajs/react'
import { useEffect, useState, type ReactNode } from 'react'

import { formatCurrency, formatDate } from '@/lib/format'

import type { OpportunityDrawerRecord } from './OpportunityDrawer'

export type OpportunityCard = OpportunityDrawerRecord

export type PipelineStage = {
  id: number
  name: string
  position: number
  opportunities: OpportunityCard[]
}

type OpportunityBoardProps = {
  stages: PipelineStage[]
  returnTo: string
  onOpen: (opportunity: OpportunityCard) => void
}

function stageDropId(stageId: number) {
  return `stage-${stageId}`
}

function opportunityDragId(opportunityId: number) {
  return `opportunity-${opportunityId}`
}

function moveOpportunity(
  stages: PipelineStage[],
  opportunityId: number,
  toStageId: number,
): PipelineStage[] {
  let moving: OpportunityCard | null = null

  const without = stages.map((stage) => {
    const match = stage.opportunities.find((item) => item.id === opportunityId)
    if (!match) return stage
    moving = { ...match, stage_id: toStageId }
    return {
      ...stage,
      opportunities: stage.opportunities.filter((item) => item.id !== opportunityId),
    }
  })

  if (!moving) return stages

  return without.map((stage) =>
    stage.id === toStageId
      ? { ...stage, opportunities: [...stage.opportunities, moving as OpportunityCard] }
      : stage,
  )
}

function resolveTargetStageId(
  overId: string | number | undefined,
  stages: PipelineStage[],
): number | null {
  if (overId == null) return null
  const id = String(overId)

  if (id.startsWith('stage-')) {
    const stageId = Number(id.replace('stage-', ''))
    return Number.isNaN(stageId) ? null : stageId
  }

  if (id.startsWith('opportunity-')) {
    const opportunityId = Number(id.replace('opportunity-', ''))
    const stage = stages.find((item) =>
      item.opportunities.some((opportunity) => opportunity.id === opportunityId),
    )
    return stage?.id ?? null
  }

  return null
}

function OpportunityCardView({
  opportunity,
  dragging = false,
}: {
  opportunity: OpportunityCard
  dragging?: boolean
}) {
  return (
    <div
      className={`w-full rounded-lg border border-slate-200 bg-panel p-3 text-left shadow-sm ${
        dragging ? 'shadow-md ring-2 ring-brand-muted' : ''
      }`}
    >
      <div className="truncate font-medium text-ink">{opportunity.title || 'Untitled'}</div>
      <div className="mt-1 text-sm font-semibold text-brand-ink">
        {formatCurrency(opportunity.value)}
      </div>
      <div className="mt-2 truncate text-xs text-slate-500">
        {opportunity.lead || '—'}
        {opportunity.owner ? ` · ${opportunity.owner}` : null}
        {opportunity.close_date ? ` · Close ${formatDate(opportunity.close_date)}` : null}
      </div>
    </div>
  )
}

function DraggableOpportunityCard({
  opportunity,
  onOpen,
}: {
  opportunity: OpportunityCard
  onOpen: (opportunity: OpportunityCard) => void
}) {
  const canDrag = opportunity.can_update
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: opportunityDragId(opportunity.id),
    disabled: !canDrag,
    data: {
      type: 'opportunity',
      opportunityId: opportunity.id,
      stageId: opportunity.stage_id,
    },
  })

  const style = transform
    ? {
        transform: CSS.Translate.toString(transform),
      }
    : undefined

  return (
    <li
      ref={setNodeRef}
      style={style}
      className={`shrink-0 ${isDragging ? 'opacity-40' : ''}`}
    >
      <div className="flex items-stretch gap-1">
        {canDrag ? (
          <button
            type="button"
            className="inline-flex min-h-11 min-w-11 shrink-0 touch-none cursor-grab items-center justify-center rounded-lg border border-slate-200 bg-panel text-slate-500 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 focus-visible:ring-offset-panel active:cursor-grabbing"
            aria-label={`Drag ${opportunity.title || 'opportunity'}`}
            {...listeners}
            {...attributes}
          >
            <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor" aria-hidden>
              <circle cx="5" cy="4" r="1.25" />
              <circle cx="11" cy="4" r="1.25" />
              <circle cx="5" cy="8" r="1.25" />
              <circle cx="11" cy="8" r="1.25" />
              <circle cx="5" cy="12" r="1.25" />
              <circle cx="11" cy="12" r="1.25" />
            </svg>
          </button>
        ) : null}
        <button
          type="button"
          onClick={() => onOpen(opportunity)}
          className="min-h-11 min-w-0 flex-1 text-left transition-colors hover:border-brand-muted hover:bg-brand-subtle/40"
        >
          <OpportunityCardView opportunity={opportunity} />
        </button>
      </div>
    </li>
  )
}

function StageColumn({
  stage,
  children,
}: {
  stage: PipelineStage
  children: ReactNode
}) {
  const { setNodeRef, isOver } = useDroppable({
    id: stageDropId(stage.id),
    data: {
      type: 'stage',
      stageId: stage.id,
    },
  })

  return (
    <section
      className={`flex min-h-0 w-[min(18rem,85vw)] shrink-0 flex-col rounded-xl border bg-panel md:w-auto md:min-w-0 ${
        isOver ? 'border-brand bg-brand-subtle/40' : 'border-slate-200'
      }`}
      aria-label={`${stage.name} stage`}
    >
      <header className="flex shrink-0 items-center justify-between gap-2 border-b border-slate-100 bg-surface/80 px-3 py-3">
        <h2 className="truncate text-sm font-semibold text-ink">{stage.name}</h2>
        <span className="shrink-0 rounded-full bg-brand-muted px-2 py-0.5 text-xs font-medium text-brand-ink">
          {stage.opportunities.length}
        </span>
      </header>

      <ul
        ref={setNodeRef}
        className="flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto p-3"
      >
        {children}
        {stage.opportunities.length === 0 ? (
          <li className="rounded-lg border border-dashed border-slate-200 bg-panel px-3 py-6 text-center text-xs text-slate-400">
            Drop here
          </li>
        ) : null}
      </ul>
    </section>
  )
}

export default function OpportunityBoard({ stages, returnTo, onOpen }: OpportunityBoardProps) {
  const [board, setBoard] = useState(stages)
  const [activeId, setActiveId] = useState<number | null>(null)
  const [savingId, setSavingId] = useState<number | null>(null)

  useEffect(() => {
    setBoard(stages)
  }, [stages])

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { delay: 160, tolerance: 6 },
    }),
  )

  const activeOpportunity =
    activeId == null
      ? null
      : board.flatMap((stage) => stage.opportunities).find((item) => item.id === activeId) ?? null

  function handleDragStart(event: DragStartEvent) {
    const id = String(event.active.id)
    if (!id.startsWith('opportunity-')) return
    setActiveId(Number(id.replace('opportunity-', '')))
  }

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event
    setActiveId(null)

    if (!over) return

    const opportunityId = Number(String(active.id).replace('opportunity-', ''))
    if (Number.isNaN(opportunityId)) return

    const fromStage = board.find((stage) =>
      stage.opportunities.some((item) => item.id === opportunityId),
    )
    const opportunity = fromStage?.opportunities.find((item) => item.id === opportunityId)
    if (!fromStage || !opportunity || !opportunity.can_update) return

    const toStageId = resolveTargetStageId(over.id, board)
    if (toStageId == null || toStageId === fromStage.id) return

    const previous = board
    setBoard(moveOpportunity(board, opportunityId, toStageId))
    setSavingId(opportunityId)

    router.patch(
      `/opportunities/${opportunityId}`,
      {
        stage_id: toStageId,
        return_to: returnTo,
      },
      {
        preserveScroll: true,
        onError: () => setBoard(previous),
        onFinish: () => setSavingId(null),
      },
    )
  }

  function handleDragCancel() {
    setActiveId(null)
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragCancel={handleDragCancel}
    >
      <div className="mt-6 flex min-h-0 min-w-0 flex-1 gap-3 overflow-x-auto pb-2 md:grid md:grid-cols-2 md:overflow-x-visible lg:grid-cols-3 xl:grid-cols-5">
        {board.map((stage) => (
          <StageColumn key={stage.id} stage={stage}>
            {stage.opportunities.map((opportunity) => (
              <DraggableOpportunityCard
                key={opportunity.id}
                opportunity={opportunity}
                onOpen={onOpen}
              />
            ))}
          </StageColumn>
        ))}
      </div>

      <DragOverlay dropAnimation={null}>
        {activeOpportunity ? <OpportunityCardView opportunity={activeOpportunity} dragging /> : null}
      </DragOverlay>

      {savingId != null ? <span className="sr-only">Updating opportunity stage</span> : null}
    </DndContext>
  )
}
