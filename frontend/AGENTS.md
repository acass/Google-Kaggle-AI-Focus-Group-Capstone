<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# Frontend Developer Guidelines

For full repository-level rules and architecture details, see the main [AGENTS.md](../AGENTS.md) at the root.

## ⚛️ Frontend Codebase Conventions
- **State Management**: Use `useFocusGroup` hook (`frontend/app/hooks/useFocusGroup.ts`) for managing all SSE stream states, API interactions, and resetting sessions. Do not implement ad-hoc SSE parsing in pages or individual components.
- **Client Components**: Prefix all client-side pages and components with `"use client"`.
- **Styling**: Styled using Tailwind CSS v4. Use standard classes. Feel free to use the variables defined in `frontend/app/globals.css`.
- **Exporting Reports**:
  - PDF export utilizes `jspdf` and is implemented in `frontend/app/utils/exportReport.ts`.
  - DOCX export utilizes `docx` and is also implemented in `frontend/app/utils/exportReport.ts`.
  - When modifying the reports, make sure both options remain supported and function client-side.
