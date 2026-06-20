# AI Focus Group — Frontend Client

This is the Next.js frontend client for the **AI Focus Group** application. It provides a real-time, responsive user interface for initiating research panels, monitoring agent discussions, visualizing category scores, and exporting final synthesis reports.

---

## 🛠️ Stack & Technologies

- **Framework**: [Next.js 16](https://nextjs.org/) (App Router)
- **UI & React**: React 19
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/) (using `@tailwindcss/postcss`)
- **Language**: TypeScript
- **Export Utilities**:
  - [jsPDF](https://github.com/parallax/jsPDF) — client-side PDF document generation
  - [docx](https://docx.js.org/) — client-side Word document (.docx) generation

---

## 📁 Directory Structure

```
frontend/
├── app/
│   ├── components/
│   │   ├── AgentBubble.tsx      # Renders a single agent's message card with styling matching their role
│   │   ├── DiscussionThread.tsx # Orchestrates the flow of live chat and phase changes
│   │   ├── FinalReport.tsx     # Summary report card with actions to export PDF/DOCX
│   │   ├── ScorePanel.tsx      # Sidebar displaying live scores and consensus confidence
│   │   └── TopicInput.tsx      # Left panel form to configure topic and select personas
│   ├── hooks/
│   │   └── useFocusGroup.ts    # SSE connection and core state machine management hook
│   ├── utils/
│   │   └── exportReport.ts     # Document layout, styles, and builder for PDF & DOCX
│   ├── globals.css             # Main styling, custom Tailwind configuration and animations
│   ├── layout.tsx              # Root HTML wrapper and Geist font configuration
│   └── page.tsx                # Main workspace container layout
├── package.json
└── tsconfig.json
```

---

## 📡 Real-time Streaming Architecture

The client interacts with the FastAPI backend using a hybrid API approach:
1. **Creation (`POST /sessions`)**: Initiates a new session with the chosen topic and list of participant personas.
2. **Streaming (`GET /sessions/{id}/stream`)**: Uses Server-Sent Events (`EventSource`) to receive real-time updates. The hook `useFocusGroup` listens to this event stream and updates the state.
3. **Completion**: When the stream issues the `done` event, the client fetches the final synthesized report from `GET /sessions/{id}` to complete the workflow.

---

## 🚀 Running the Client

### 1. Installation
Install project dependencies:
```bash
npm install
```

### 2. Configuration
By default, the client points to `http://localhost:8000`. You can configure a custom backend endpoint by defining an environment variable:
```bash
# Create a .env.local file in the frontend directory
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 3. Start Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to view the client.

### 4. Code Quality & Formatting
Run ESLint to check for code quality issues:
```bash
npm run lint
```

Run build to check TypeScript compiler correctness and generate a production bundle:
```bash
npm run build
```
