"use client"

import { useEffect, useRef } from "react"
import { AgentBubble } from "./AgentBubble"
import type { StreamEvent, Phase } from "../types"

const PHASE_BANNERS: Partial<Record<string, string>> = {
  discussion: "Round 2 — Shared Discussion",
  voting: "Scoring Phase",
  synthesis: "Synthesis",
}

interface Props {
  events: StreamEvent[]
  phase: Phase
  sessionId: string | null
}

export function DiscussionThread({ events, phase, sessionId }: Props) {
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [events.length])

  if (!sessionId) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-zinc-500 gap-3">
        <div className="text-4xl">&#x1F4AC;</div>
        <p className="text-sm">Submit a topic to start the focus group</p>
      </div>
    )
  }

  const phasesSeen = new Set<string>()
  const renderedItems: React.ReactNode[] = []

  for (const evt of events) {
    if (evt.type === "done") continue

    const bannerLabel = PHASE_BANNERS[evt.phase]
    if (bannerLabel && !phasesSeen.has(evt.phase) && evt.phase !== "intro") {
      phasesSeen.add(evt.phase)
      renderedItems.push(
        <div
          key={`banner-${evt.phase}`}
          className="flex items-center gap-3 py-3"
        >
          <div className="flex-1 h-px bg-zinc-700" />
          <span className="text-xs text-zinc-400 font-medium">{bannerLabel}</span>
          <div className="flex-1 h-px bg-zinc-700" />
        </div>
      )
    }

    renderedItems.push(
      <AgentBubble key={`${evt.agent_id}-${renderedItems.length}`} event={evt} />
    )
  }

  const isRunning = phase !== "idle" && phase !== "complete"

  return (
    <div className="flex flex-col h-full overflow-y-auto px-4 py-2">
      {renderedItems}
      {isRunning && (
        <div className="flex items-center gap-2 py-3 text-xs text-zinc-500">
          <div className="flex gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-zinc-500 animate-bounce [animation-delay:0ms]" />
            <span className="w-1.5 h-1.5 rounded-full bg-zinc-500 animate-bounce [animation-delay:150ms]" />
            <span className="w-1.5 h-1.5 rounded-full bg-zinc-500 animate-bounce [animation-delay:300ms]" />
          </div>
          Thinking...
        </div>
      )}
      <div ref={bottomRef} />
    </div>
  )
}
