"use client"

import { useFocusGroup } from "./hooks/useFocusGroup"
import { TopicInput } from "./components/TopicInput"
import { DiscussionThread } from "./components/DiscussionThread"
import { ScorePanel } from "./components/ScorePanel"
import { FinalReport } from "./components/FinalReport"

export default function Home() {
  const { session, isLoading, error, start, reset } = useFocusGroup()

  const isRunning = session !== null && !session.completed
  const showReport = session?.completed && session.final_report !== null

  return (
    <div className="h-screen bg-zinc-950 text-white flex flex-col">
      <div className="flex-shrink-0 h-10 border-b border-zinc-800 flex items-center px-4 gap-3">
        <span className="text-sm font-semibold text-white">AI Focus Group</span>
        {error && (
          <span className="text-xs text-red-400 ml-auto">{error}</span>
        )}
      </div>

      <div className="flex-1 flex overflow-hidden">
        <div className="w-64 flex-shrink-0 border-r border-zinc-800 overflow-y-auto">
          <TopicInput
            onStart={start}
            isLoading={isLoading}
            disabled={isRunning}
          />
        </div>

        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex-1 overflow-y-auto">
            <DiscussionThread
              events={session?.events ?? []}
              phase={session?.phase ?? "idle"}
              sessionId={session?.session_id ?? null}
            />
          </div>
          {showReport && session?.final_report && (
            <div className="flex-shrink-0 border-t border-zinc-800 max-h-96 overflow-y-auto">
              <FinalReport report={session.final_report} onReset={reset} />
            </div>
          )}
        </div>

        <div className="w-56 flex-shrink-0 border-l border-zinc-800 overflow-y-auto">
          <ScorePanel
            phase={session?.phase ?? "idle"}
            scores={session?.scores ?? {}}
            report={session?.final_report ?? null}
          />
        </div>
      </div>
    </div>
  )
}
