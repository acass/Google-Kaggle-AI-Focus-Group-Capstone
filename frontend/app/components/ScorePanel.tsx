import type { ScoreSet, Phase, FinalReport } from "../types"

const CATEGORY_LABELS: Record<keyof ScoreSet, string> = {
  innovation: "Innovation",
  market: "Market Potential",
  ux: "UX / Clarity",
  feasibility: "Feasibility",
  monetization: "Monetization",
  risk: "Risk (10 = safe)",
}

const PHASE_STATUS: Record<string, string> = {
  idle: "Waiting",
  intro: "Introducing...",
  independent: "Round 1: Independent eval",
  discussion: "Round 2: Group discussion",
  voting: "Scoring...",
  synthesis: "Synthesizing...",
  complete: "Complete",
}

function averageScores(scores: Record<string, ScoreSet>): ScoreSet | null {
  const entries = Object.values(scores)
  if (entries.length === 0) return null

  const categories = Object.keys(entries[0]) as (keyof ScoreSet)[]
  const result = {} as ScoreSet
  for (const cat of categories) {
    result[cat] = Math.round((entries.reduce((sum, s) => sum + s[cat], 0) / entries.length) * 10) / 10
  }
  return result
}

function ScoreBar({ value, max = 10 }: { value: number; max?: number }) {
  const pct = Math.min((value / max) * 100, 100)
  const color =
    value >= 7 ? "bg-emerald-500" : value >= 5 ? "bg-amber-500" : "bg-red-500"

  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 h-1.5 bg-zinc-700 rounded-full overflow-hidden">
        <div
          className={`h-full ${color} rounded-full transition-all duration-500`}
          style={{ width: `${pct}%` }}
        />
      </div>
      <span className="text-xs text-zinc-300 w-6 text-right">{value}</span>
    </div>
  )
}

interface Props {
  phase: Phase
  scores: Record<string, ScoreSet>
  report: FinalReport | null
}

export function ScorePanel({ phase, scores, report }: Props) {
  const avgScores = report ? report.category_averages : averageScores(scores)
  const overallScore = report
    ? report.overall_score
    : avgScores
    ? Math.round((Object.values(avgScores).reduce((s, v) => s + v, 0) / 6) * 10) / 10
    : null

  const sentimentColor: Record<string, string> = {
    positive: "text-emerald-400",
    neutral: "text-zinc-400",
    skeptical: "text-amber-400",
    negative: "text-red-400",
  }

  return (
    <div className="flex flex-col gap-4 p-4 h-full overflow-y-auto">
      <div>
        <div className="flex items-center justify-between mb-1">
          <span className="text-xs font-medium text-zinc-300">Status</span>
          <span
            className={`text-xs px-2 py-0.5 rounded-full ${
              phase === "complete"
                ? "bg-emerald-500/20 text-emerald-400"
                : phase !== "idle"
                ? "bg-indigo-500/20 text-indigo-400 animate-pulse"
                : "bg-zinc-700 text-zinc-400"
            }`}
          >
            {PHASE_STATUS[phase] ?? phase}
          </span>
        </div>

        {report && (
          <div className="flex items-center justify-between mt-2">
            <span className="text-xs text-zinc-400">Sentiment</span>
            <span className={`text-xs font-medium capitalize ${sentimentColor[report.sentiment] ?? "text-zinc-400"}`}>
              {report.sentiment}
            </span>
          </div>
        )}

        {report && (
          <div className="flex items-center justify-between mt-1">
            <span className="text-xs text-zinc-400">Consensus</span>
            <span className="text-xs font-medium text-white">
              {Math.round(report.consensus_confidence * 100)}%
            </span>
          </div>
        )}
      </div>

      {overallScore !== null && (
        <div className="bg-zinc-800 rounded-xl p-3 text-center">
          <div className="text-3xl font-bold text-white">{overallScore}</div>
          <div className="text-xs text-zinc-400 mt-0.5">Overall score / 10</div>
        </div>
      )}

      {avgScores && (
        <div>
          <p className="text-xs font-medium text-zinc-300 mb-2">Scores by category</p>
          <div className="flex flex-col gap-2.5">
            {(Object.entries(CATEGORY_LABELS) as [keyof ScoreSet, string][]).map(([cat, label]) => (
              <div key={cat}>
                <div className="flex justify-between text-[11px] text-zinc-400 mb-1">
                  <span>{label}</span>
                  {report?.category_std_dev[cat] !== undefined && (
                    <span className="text-zinc-500">±{report.category_std_dev[cat]}</span>
                  )}
                </div>
                <ScoreBar value={avgScores[cat]} />
              </div>
            ))}
          </div>
        </div>
      )}

      {Object.keys(scores).length > 0 && !report && (
        <div>
          <p className="text-xs font-medium text-zinc-300 mb-2">Votes received</p>
          {Object.entries(scores).map(([agentId, s]) => (
            <div key={agentId} className="text-xs text-zinc-500 mb-1">
              {agentId.replace(/_/g, " ")} — avg {Math.round((Object.values(s).reduce((a, b) => a + b, 0) / 6) * 10) / 10}
            </div>
          ))}
        </div>
      )}

      {!avgScores && (
        <div className="text-xs text-zinc-500 text-center mt-4">
          Scores will appear during the voting phase
        </div>
      )}
    </div>
  )
}
