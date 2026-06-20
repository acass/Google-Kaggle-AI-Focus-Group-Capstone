"use client"

import { useState, useEffect } from "react"
import type { PersonaMeta } from "../types"

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000"

interface Props {
  onStart: (topic: string, participantIds: string[]) => void
  isLoading: boolean
  disabled: boolean
}

export function TopicInput({ onStart, isLoading, disabled }: Props) {
  const [topic, setTopic] = useState("")
  const [personas, setPersonas] = useState<PersonaMeta[]>([])
  const [selected, setSelected] = useState<Set<string>>(new Set())

  useEffect(() => {
    fetch(`${API_BASE}/personas`)
      .then((r) => r.json())
      .then((data: Record<string, PersonaMeta>) => {
        const list = Object.values(data)
        setPersonas(list)
        setSelected(new Set(list.map((p) => p.id)))
      })
      .catch(() => { })
  }, [])

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        if (next.size > 1) next.delete(id)
      } else {
        if (next.size < 5) next.add(id)
      }
      return next
    })
  }

  const handleSubmit = () => {
    if (!topic.trim() || selected.size === 0) return
    onStart(topic.trim(), Array.from(selected))
  }

  return (
    <div className="flex flex-col gap-4 p-4 h-full">
      <div>
        <h1 className="text-lg font-semibold text-white mb-1">AI Focus Group</h1>
        <p className="text-xs text-zinc-400">Submit a topic and get synthetic expert feedback</p>
      </div>

      <div>
        <label className="text-xs font-medium text-zinc-300 mb-1 block">Topic</label>
        <textarea
          className="w-full bg-zinc-800 border border-zinc-700 rounded-lg p-3 text-sm text-white placeholder-zinc-500 resize-none focus:outline-none focus:border-zinc-500 h-28"
          placeholder="e.g. 'Business product or service'"
          value={topic}
          onChange={(e) => setTopic(e.target.value)}
          disabled={disabled}
        />
      </div>

      <div>
        <label className="text-xs font-medium text-zinc-300 mb-2 block">
          Panel ({selected.size} selected)
        </label>
        <div className="flex flex-col gap-2">
          {personas.map((p) => (
            <button
              key={p.id}
              onClick={() => toggle(p.id)}
              disabled={disabled}
              className={`text-left p-2.5 rounded-lg border text-xs transition-all ${selected.has(p.id)
                  ? "border-indigo-500 bg-indigo-500/10 text-white"
                  : "border-zinc-700 bg-zinc-800/50 text-zinc-400 hover:border-zinc-600"
                }`}
            >
              <div className="font-medium">{p.name}</div>
              <div className="text-zinc-500 mt-0.5">{p.role}</div>
            </button>
          ))}
        </div>
      </div>

      <button
        onClick={handleSubmit}
        disabled={disabled || isLoading || !topic.trim() || selected.size === 0}
        className="mt-auto w-full py-2.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 disabled:opacity-40 disabled:cursor-not-allowed text-white text-sm font-medium transition-colors"
      >
        {isLoading ? "Starting..." : "Run Focus Group"}
      </button>
    </div>
  )
}
