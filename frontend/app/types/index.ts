export interface ScoreSet {
  innovation: number
  market: number
  ux: number
  feasibility: number
  monetization: number
  risk: number
}

export interface FinalReport {
  overall_score: number
  scores_by_agent: Record<string, ScoreSet>
  category_averages: ScoreSet
  category_std_dev: ScoreSet
  consensus_confidence: number
  key_concerns: string[]
  key_strengths: string[]
  action_items: string[]
  recommendation: string
  sentiment: "positive" | "neutral" | "skeptical" | "negative"
}

export interface StreamEvent {
  type: "agent_message" | "phase_change" | "score_update" | "report_complete" | "done"
  agent_id: string | null
  agent_name: string | null
  phase: string
  content: string
  scores: ScoreSet | null
}

export interface PersonaMeta {
  id: string
  name: string
  role: string
  communication_style: string
}

export type Phase = "idle" | "intro" | "independent" | "discussion" | "voting" | "synthesis" | "complete"

export interface FocusGroupSession {
  session_id: string
  phase: Phase
  events: StreamEvent[]
  scores: Record<string, ScoreSet>
  final_report: FinalReport | null
  completed: boolean
}
