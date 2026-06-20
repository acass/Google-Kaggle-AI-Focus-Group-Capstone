"use client"

import { useState, useCallback, useRef } from "react"
import type { FocusGroupSession, StreamEvent, Phase } from "../types"

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000"

export function useFocusGroup() {
  const [session, setSession] = useState<FocusGroupSession | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const esRef = useRef<EventSource | null>(null)

  const start = useCallback(async (topic: string, participantIds: string[]) => {
    setIsLoading(true)
    setError(null)
    esRef.current?.close()

    try {
      const res = await fetch(`${API_BASE}/sessions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic, participant_ids: participantIds }),
      })

      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.detail ?? "Failed to create session")
      }

      const data = await res.json()
      const sessionId: string = data.session_id

      setSession({
        session_id: sessionId,
        topic: topic,
        phase: "intro",
        events: [],
        scores: {},
        final_report: null,
        completed: false,
      })

      const es = new EventSource(`${API_BASE}/sessions/${sessionId}/stream`)
      esRef.current = es

      es.onmessage = (e) => {
        try {
          const event: StreamEvent = JSON.parse(e.data)

          setSession((prev) => {
            if (!prev) return prev

            const events = [...prev.events, event]
            let phase: Phase = prev.phase
            let scores = { ...prev.scores }
            let final_report = prev.final_report
            let completed = prev.completed

            if (event.type === "phase_change" || event.type === "agent_message") {
              phase = event.phase as Phase
            }
            if (event.type === "score_update" && event.agent_id && event.scores) {
              scores[event.agent_id] = event.scores
              phase = "voting"
            }
            if (event.type === "report_complete") {
              phase = "synthesis"
            }
            if (event.type === "error") {
              setError(event.content || "Session failed")
              es.close()
            }
            if (event.type === "done") {
              completed = true
              phase = "complete"
              es.close()
            }

            return { ...prev, events, phase, scores, final_report, completed }
          })

          // Fetch full state once complete to get final_report
          if (event.type === "done") {
            fetch(`${API_BASE}/sessions/${sessionId}`)
              .then((r) => r.json())
              .then((state) => {
                setSession((prev) =>
                  prev ? { ...prev, final_report: state.final_report, completed: true } : prev
                )
              })
              .catch(() => {})
          }
        } catch {
          // ignore parse errors
        }
      }

      es.onerror = () => {
        setError("Stream connection lost")
        es.close()
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error")
    } finally {
      setIsLoading(false)
    }
  }, [])

  const reset = useCallback(() => {
    esRef.current?.close()
    setSession(null)
    setError(null)
    setIsLoading(false)
  }, [])

  return { session, isLoading, error, start, reset }
}
