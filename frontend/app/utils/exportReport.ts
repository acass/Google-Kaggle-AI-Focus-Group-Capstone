import type { FinalReport } from "../types"

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

const formattedDate = () =>
  new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })

export async function exportAsPdf(report: FinalReport): Promise<void> {
  const { jsPDF } = await import("jspdf")

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

  doc.setFontSize(18)
  doc.setFont("helvetica", "bold")
  doc.setTextColor(0, 0, 0)
  doc.text("AI Focus Group — Final Report", margin, y)
  y += 9

  doc.setFontSize(9)
  doc.setFont("helvetica", "normal")
  doc.setTextColor(120, 120, 120)
  doc.text(`Generated: ${formattedDate()}`, margin, y)
  y += 12

  doc.setFontSize(14)
  doc.setFont("helvetica", "bold")
  doc.setTextColor(0, 0, 0)
  doc.text(`Overall Score: ${report.overall_score} / 10`, margin, y)
  y += 7

  doc.setFontSize(10)
  doc.setFont("helvetica", "normal")
  doc.setTextColor(80, 80, 80)
  doc.text(
    `Sentiment: ${capitalize(report.sentiment)}  |  Consensus: ${Math.round(report.consensus_confidence * 100)}%`,
    margin,
    y
  )
  y += 14

  doc.setFontSize(12)
  doc.setFont("helvetica", "bold")
  doc.setTextColor(0, 0, 0)
  doc.text("Recommendation", margin, y)
  y += 7

  doc.setFontSize(10)
  doc.setFont("helvetica", "normal")
  const recLines = doc.splitTextToSize(report.recommendation, usableWidth) as string[]
  checkPage(recLines.length * 5)
  doc.text(recLines, margin, y)
  y += recLines.length * 5 + 12

  const addSection = (title: string, items: string[]) => {
    if (items.length === 0) return
    checkPage(24)
    doc.setFontSize(12)
    doc.setFont("helvetica", "bold")
    doc.setTextColor(0, 0, 0)
    doc.text(title, margin, y)
    y += 7
    doc.setFontSize(10)
    doc.setFont("helvetica", "normal")
    for (const item of items) {
      const lines = doc.splitTextToSize(`•  ${item}`, usableWidth - 4) as string[]
      checkPage(lines.length * 5 + 3)
      doc.text(lines, margin + 2, y)
      y += lines.length * 5 + 3
    }
    y += 8
  }

  addSection("Strengths", report.key_strengths)
  addSection("Concerns", report.key_concerns)
  addSection("Action Items", report.action_items)

  doc.save("focus-group-report.pdf")
}

export async function exportAsDocx(report: FinalReport): Promise<void> {
  const { Document, Packer, Paragraph, TextRun, HeadingLevel } = await import("docx")

  const bulletItems = (items: string[]) =>
    items.map(
      (item) =>
        new Paragraph({
          text: item,
          bullet: { level: 0 },
        })
    )

  const sectionChildren: InstanceType<typeof Paragraph>[] = []

  const pushSection = (title: string, items: string[]) => {
    if (items.length === 0) return
    sectionChildren.push(
      new Paragraph({ text: title, heading: HeadingLevel.HEADING_2 }),
      ...bulletItems(items),
      new Paragraph({ text: "" })
    )
  }

  pushSection("Strengths", report.key_strengths)
  pushSection("Concerns", report.key_concerns)
  pushSection("Action Items", report.action_items)

  const doc = new Document({
    sections: [
      {
        children: [
          new Paragraph({ text: "AI Focus Group — Final Report", heading: HeadingLevel.HEADING_1 }),
          new Paragraph({
            children: [new TextRun({ text: `Generated: ${formattedDate()}`, color: "888888", size: 18 })],
          }),
          new Paragraph({ text: "" }),
          new Paragraph({
            children: [
              new TextRun({ text: `Overall Score: ${report.overall_score} / 10`, bold: true, size: 28 }),
            ],
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: `Sentiment: ${capitalize(report.sentiment)}  |  Consensus: ${Math.round(report.consensus_confidence * 100)}%`,
                color: "555555",
                size: 20,
              }),
            ],
          }),
          new Paragraph({ text: "" }),
          new Paragraph({ text: "Recommendation", heading: HeadingLevel.HEADING_2 }),
          new Paragraph({ text: report.recommendation }),
          new Paragraph({ text: "" }),
          ...sectionChildren,
        ],
      },
    ],
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
