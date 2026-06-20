import type { FocusGroupSession } from "../types"
import type { Paragraph as DocxParagraph } from "docx"

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

function getPhaseLabel(phase: string): string {
  if (phase === "intro") return "Introduction"
  if (phase === "independent") return "Round 1 — Independent"
  if (phase === "discussion") return "Round 2 — Discussion"
  if (phase === "voting") return "Scoring Phase"
  if (phase === "synthesis") return "Synthesis"
  return phase
}

export async function exportAsPdf(session: FocusGroupSession): Promise<void> {
  const { jsPDF } = await import("jspdf")
  const report = session.final_report!

  const doc = new jsPDF({ unit: "mm", format: "a4" })
  const margin = 20
  const pageWidth = 210
  const pageHeight = 297
  const usableWidth = pageWidth - margin * 2
  let y = margin

  const checkPage = (needed: number) => {
    if (y + needed > pageHeight - margin) {
      doc.addPage()
      y = margin
    }
  }

  const addText = (text: string, fontSize: number, isBold: boolean, color: [number, number, number], spacingAfter: number) => {
    if (!text) return
    doc.setFontSize(fontSize)
    doc.setFont("helvetica", isBold ? "bold" : "normal")
    doc.setTextColor(color[0], color[1], color[2])
    
    // Some content might have explicit newlines. We need to split by newline first.
    const rawLines = text.split('\n')
    for (const rawLine of rawLines) {
      const lines = doc.splitTextToSize(rawLine, usableWidth) as string[]
      const lineHeight = fontSize * 0.35 + 1
      checkPage(lines.length * lineHeight)
      doc.text(lines, margin, y)
      y += lines.length * lineHeight
    }
    y += spacingAfter
  }

  // Topic
  addText("Topic", 14, true, [0, 0, 0], 2)
  addText(`“${session.topic}”`, 11, false, [60, 60, 60], 10)

  // Transcript
  for (const evt of session.events) {
    if (evt.type === "agent_message") {
      addText(evt.agent_name || "Unknown", 12, true, [0, 0, 0], 2)
      addText(getPhaseLabel(evt.phase), 10, false, [100, 100, 100], 4)
      addText(evt.content, 10, false, [40, 40, 40], 10)
    }
  }

  // Scoring
  addText("Scoring Phase", 14, true, [0, 0, 0], 6)
  for (const evt of session.events) {
    if (evt.type === "score_update" && evt.scores) {
      const catArray = Object.entries(evt.scores).map(([k, v]) => `${k}=${v.toFixed(1)}`)
      addText(evt.agent_name || "Unknown", 12, true, [0, 0, 0], 2)
      addText(`Scored: ${catArray.join(', ')}`, 10, false, [60, 60, 60], 8)
    }
  }

  y += 5

  // Summary header
  addText("Status - Complete", 11, true, [0, 0, 0], 2)
  addText(`Sentiment - ${capitalize(report.sentiment)}`, 11, true, [0, 0, 0], 2)
  addText(`Consensus - ${Math.round(report.consensus_confidence * 100)}%`, 11, true, [0, 0, 0], 6)
  
  addText(report.overall_score.toFixed(1), 16, true, [0, 0, 0], 2)
  addText("Overall score / 10", 10, false, [100, 100, 100], 6)
  
  addText("Scores by category", 12, true, [0, 0, 0], 4)
  const cats = [
    ["Innovation", report.category_averages.innovation],
    ["Market Potential", report.category_averages.market],
    ["UX / Clarity", report.category_averages.ux],
    ["Feasibility", report.category_averages.feasibility],
    ["Monetization", report.category_averages.monetization],
    ["Risk (10 = safe)", report.category_averages.risk],
  ]
  for (const [k, v] of cats) {
    addText(`${k} - ${Number(v).toFixed(1)}`, 10, false, [60, 60, 60], 2)
  }
  y += 8

  // Final Report
  addText("Final Report", 18, true, [0, 0, 0], 4)
  addText(`${capitalize(report.sentiment)} — ${Math.round(report.consensus_confidence * 100)}% Consensus`, 12, true, [80, 80, 80], 2)
  addText(`${report.overall_score.toFixed(1)} / 10`, 12, true, [80, 80, 80], 6)
  addText(report.recommendation, 10, false, [40, 40, 40], 8)

  const addSection = (title: string, items: string[]) => {
    if (items.length === 0) return
    addText(title, 12, true, [0, 0, 0], 4)
    for (const item of items) {
      addText(`•  ${item}`, 10, false, [40, 40, 40], 3)
    }
    y += 4
  }

  addSection("Strengths", report.key_strengths)
  addSection("Concerns", report.key_concerns)
  addSection("Action Items", report.action_items)

  doc.save("focus-group-report.pdf")
}

export async function exportAsDocx(session: FocusGroupSession): Promise<void> {
  const { Document, Packer, Paragraph, TextRun } = await import("docx")
  const report = session.final_report!

  const children: DocxParagraph[] = []

  const addPara = (text: string, bold = false, size = 22, color = "000000", spacing = 120) => {
    // docx sizes are in half-points (22 = 11pt)
    const runs = text.split('\n').map((line, i) => {
      return new TextRun({ text: line, bold, size, color, break: i > 0 ? 1 : 0 })
    })
    
    children.push(
      new Paragraph({
        children: runs,
        spacing: { after: spacing }
      })
    )
  }

  // Topic
  addPara("Topic", false, 28, "000000", 40)
  addPara(`“${session.topic}”`, false, 22, "444444", 240)

  // Transcript
  for (const evt of session.events) {
    if (evt.type === "agent_message") {
      addPara(evt.agent_name || "Unknown", false, 24, "000000", 40)
      addPara(getPhaseLabel(evt.phase), false, 20, "666666", 80)
      addPara(evt.content, false, 20, "222222", 240)
    }
  }

  // Scoring
  addPara("Scoring Phase", false, 28, "000000", 120)
  for (const evt of session.events) {
    if (evt.type === "score_update" && evt.scores) {
      const catArray = Object.entries(evt.scores).map(([k, v]) => `${k}=${v.toFixed(1)}`)
      addPara(evt.agent_name || "Unknown", false, 24, "000000", 40)
      addPara(`Scored: ${catArray.join(', ')}`, false, 20, "444444", 160)
    }
  }

  children.push(new Paragraph({ text: "", spacing: { after: 240 } }))

  // Summary
  addPara("Status - Complete", true, 22, "000000", 40)
  addPara(`Sentiment - ${capitalize(report.sentiment)}`, true, 22, "000000", 40)
  addPara(`Consensus - ${Math.round(report.consensus_confidence * 100)}%`, true, 22, "000000", 120)

  addPara(report.overall_score.toFixed(1), true, 32, "000000", 40)
  addPara("Overall score / 10", false, 20, "666666", 120)

  addPara("Scores by category", true, 24, "000000", 80)
  const cats = [
    ["Innovation", report.category_averages.innovation],
    ["Market Potential", report.category_averages.market],
    ["UX / Clarity", report.category_averages.ux],
    ["Feasibility", report.category_averages.feasibility],
    ["Monetization", report.category_averages.monetization],
    ["Risk (10 = safe)", report.category_averages.risk],
  ]
  for (const [k, v] of cats) {
    addPara(`${k} - ${Number(v).toFixed(1)}`, false, 20, "444444", 40)
  }
  
  children.push(new Paragraph({ text: "", spacing: { after: 240 } }))

  // Final Report
  addPara("Final Report", true, 36, "000000", 80)
  addPara(`${capitalize(report.sentiment)} — ${Math.round(report.consensus_confidence * 100)}% Consensus`, true, 24, "555555", 40)
  addPara(`${report.overall_score.toFixed(1)} / 10`, true, 24, "555555", 120)
  addPara(report.recommendation, false, 20, "222222", 160)

  const addList = (title: string, items: string[]) => {
    if (items.length === 0) return
    addPara(title, true, 24, "000000", 80)
    for (const item of items) {
      children.push(
        new Paragraph({
          text: item,
          bullet: { level: 0 },
          spacing: { after: 80 }
        })
      )
    }
    children.push(new Paragraph({ text: "", spacing: { after: 80 } }))
  }

  addList("Strengths", report.key_strengths)
  addList("Concerns", report.key_concerns)
  addList("Action Items", report.action_items)

  const doc = new Document({
    sections: [{ children }]
  })

  const blob = await Packer.toBlob(doc)
  const url = URL.createObjectURL(blob)
  const a = document.createElement("a")
  a.href = url
  a.download = "focus-group-report.docx"
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
