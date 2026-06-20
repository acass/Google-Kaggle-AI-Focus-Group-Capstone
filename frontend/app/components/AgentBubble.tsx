import type { StreamEvent } from "../types"

const PHASE_LABELS: Record<string, string> = {
  intro: "Introduction",
  independent: "Round 1 — Independent",
  discussion: "Round 2 — Discussion",
  voting: "Scoring",
  synthesis: "Synthesis",
}

const PHASE_COLORS: Record<string, string> = {
  intro: "text-blue-400 bg-blue-500/10 border-blue-500/20",
  independent: "text-amber-400 bg-amber-500/10 border-amber-500/20",
  discussion: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
  voting: "text-purple-400 bg-purple-500/10 border-purple-500/20",
  synthesis: "text-rose-400 bg-rose-500/10 border-rose-500/20",
}

const AGENT_COLORS: Record<string, string> = {
  moderator: "bg-blue-600",
  synthesizer: "bg-rose-600",
  skeptical_investor: "bg-red-600",
  early_adopter: "bg-green-600",
  enterprise_cto: "bg-slate-600",
  ux_researcher: "bg-violet-600",
  growth_marketer: "bg-orange-600",
}

function getInitials(name: string | null): string {
  if (!name) return "?"
  const parts = name.split(" ")
  return parts
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase()
}

interface Props {
  event: StreamEvent
}

export function AgentBubble({ event }: Props) {
  const avatarColor = AGENT_COLORS[event.agent_id ?? ""] ?? "bg-zinc-600"
  const phaseColor = PHASE_COLORS[event.phase] ?? "text-zinc-400 bg-zinc-500/10 border-zinc-500/20"
  const phaseLabel = PHASE_LABELS[event.phase] ?? event.phase

  return (
    <div className="flex gap-3 py-3 border-b border-zinc-800/60 last:border-0">
      <div
        className={`flex-shrink-0 w-8 h-8 rounded-full ${avatarColor} flex items-center justify-center text-xs font-bold text-white`}
      >
        {getInitials(event.agent_name)}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1 flex-wrap">
          <span className="text-sm font-medium text-white">{event.agent_name}</span>
          <span className={`text-[10px] px-1.5 py-0.5 rounded border ${phaseColor}`}>
            {phaseLabel}
          </span>
        </div>
        <p className="text-sm text-zinc-300 leading-relaxed whitespace-pre-wrap">{event.content}</p>
        {event.scores && (
          <div className="mt-2 flex flex-wrap gap-2">
            {Object.entries(event.scores).map(([cat, score]) => (
              <span key={cat} className="text-[10px] text-zinc-400 bg-zinc-800 px-2 py-0.5 rounded">
                {cat} {score}/10
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
