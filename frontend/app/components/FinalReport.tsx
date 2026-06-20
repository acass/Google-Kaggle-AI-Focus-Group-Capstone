import { useState } from "react"
import type { FinalReport as FinalReportType } from "../types"

interface Props {
  session: any
  onReset: () => void
}

const sentimentColors: Record<string, string> = {
  positive: "border-emerald-500/30 bg-emerald-500/5",
  neutral: "border-zinc-500/30 bg-zinc-500/5",
  skeptical: "border-amber-500/30 bg-amber-500/5",
  negative: "border-red-500/30 bg-red-500/5",
}

export function FinalReport({ session, onReset }: Props) {
  const report = session.final_report as FinalReportType;
  const borderColor = sentimentColors[report.sentiment] ?? sentimentColors.neutral
  const [pdfLoading, setPdfLoading] = useState(false)
  const [docxLoading, setDocxLoading] = useState(false)

  const handlePdf = async () => {
    setPdfLoading(true)
    const { exportAsPdf } = await import("../utils/exportReport")
    await exportAsPdf(session)
    setPdfLoading(false)
  }

  const handleDocx = async () => {
    setDocxLoading(true)
    const { exportAsDocx } = await import("../utils/exportReport")
    await exportAsDocx(session)
    setDocxLoading(false)
  }

  return (
    <div className={`border rounded-xl p-4 mx-4 my-3 ${borderColor}`}>
      <div className="flex items-start justify-between mb-3">
        <div>
          <h2 className="text-base font-semibold text-white">Final Report</h2>
          <p className="text-xs text-zinc-400 mt-0.5 capitalize">
            {report.sentiment} — {Math.round(report.consensus_confidence * 100)}% consensus
          </p>
        </div>
        <div className="text-right">
          <div className="text-2xl font-bold text-white">{report.overall_score}</div>
          <div className="text-[10px] text-zinc-400">/ 10</div>
        </div>
      </div>

      <p className="text-sm text-zinc-200 leading-relaxed mb-4">{report.recommendation}</p>

      <div className="grid grid-cols-1 gap-3">
        {report.key_strengths.length > 0 && (
          <Section title="Strengths" color="text-emerald-400" items={report.key_strengths} />
        )}
        {report.key_concerns.length > 0 && (
          <Section title="Concerns" color="text-amber-400" items={report.key_concerns} />
        )}
        {report.action_items.length > 0 && (
          <Section title="Action Items" color="text-blue-400" items={report.action_items} />
        )}
      </div>

      <div className="mt-4 flex gap-2">
        <button
          onClick={handlePdf}
          disabled={pdfLoading}
          className="flex-1 py-2 rounded-lg border border-zinc-700 text-xs text-zinc-400 hover:text-white hover:border-zinc-500 transition-colors disabled:opacity-50"
        >
          {pdfLoading ? "Generating..." : "Download PDF"}
        </button>
        <button
          onClick={handleDocx}
          disabled={docxLoading}
          className="flex-1 py-2 rounded-lg border border-zinc-700 text-xs text-zinc-400 hover:text-white hover:border-zinc-500 transition-colors disabled:opacity-50"
        >
          {docxLoading ? "Generating..." : "Download DOCX"}
        </button>
      </div>

      <button
        onClick={onReset}
        className="mt-2 w-full py-2 rounded-lg border border-zinc-700 text-xs text-zinc-400 hover:text-white hover:border-zinc-500 transition-colors"
      >
        Start new session
      </button>
    </div>
  )
}

function Section({
  title,
  color,
  items,
}: {
  title: string
  color: string
  items: string[]
}) {
  return (
    <div>
      <p className={`text-xs font-semibold mb-1.5 ${color}`}>{title}</p>
      <ul className="space-y-1">
        {items.map((item, i) => (
          <li key={i} className="text-xs text-zinc-300 flex gap-2">
            <span className="text-zinc-600 flex-shrink-0">&#x2022;</span>
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
