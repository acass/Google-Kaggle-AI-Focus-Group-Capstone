# domain: stream
# maps-to: backend/api/stream.py, flutter_app/lib/data/sse_client.dart, flutter_app/lib/models/
# constraint: the backend replays the full stream_events list on every SSE connect — no manual reconnect logic on the frontend
# constraint: the frontend uses one EventSource connection per session (package:web + dart:js_interop)
# constraint: the frontend must call close() immediately on receiving a done or error event type
# constraint: StreamEvent fields agent_id, agent_name, and scores are nullable because done/error/report_complete events omit them
# constraint: "done" and "error" are SSE wire-only events injected by backend/api/stream.py and are never stored in FocusGroupState.stream_events
# constraint: "report_complete" is emitted by the synthesizer node (backend/agents/nodes/synthesizer.py) and IS stored in state

Feature: SSE Streaming
  The backend streams focus group progress over Server-Sent Events.
  The frontend opens one EventSource connection per session and folds events
  into SessionNotifier state. The backend replays full history on every connect.

  Scenario: Client connects and receives replayed history
    Given a session exists with events already in state.stream_events
    When the client opens an EventSource connection to GET /sessions/{session_id}/stream
    Then the server immediately emits all existing stream_events in chronological order
    And continues emitting new events as the workflow progresses

  Scenario: Event sequence matches workflow phases
    Given a session is running with one or more participants
    When the workflow executes all phases in order
    Then SSE events arrive in this sequence:
      | type            | phase       | layer         | notes                                                      |
      | phase_change    | intro       | in-state      | moderator intro starts; stored in stream_events            |
      | agent_message   | independent | in-state      | one per participant (may arrive in parallel)                |
      | phase_change    | discussion  | in-state      | moderator followup starts; stored in stream_events         |
      | agent_message   | discussion  | in-state      | one per participant                                        |
      | score_update    | voting      | in-state      | one per participant with scores populated                  |
      | phase_change    | synthesis   | in-state      | synthesizer starts; stored in stream_events                |
      | report_complete | synthesis   | in-state      | synthesizer node completes; final_report populated in state|
      | done            | synthesis   | sse-wire-only | injected by stream.py to close the stream; never in state  |

  Scenario: done event triggers connection close on the frontend
    Given the workflow has completed and the synthesizer node has emitted report_complete
    When the SSE delivery layer (backend/api/stream.py) injects a wire-only "done" event to close the stream
    Then the frontend SseConnection calls close() on the EventSource
    And no reconnect attempt is made
    And the "done" event is not stored in FocusGroupState.stream_events

  Scenario: error event triggers connection close on the frontend
    Given an unrecoverable error occurs in the workflow
    When the SSE stream emits an event with type "error"
    Then the frontend SseConnection calls close() on the EventSource
    And the session state reflects the error condition

  Scenario: Parallel participant events may arrive out of order
    Given a session with multiple participants running in parallel fan-out
    When the independent or discussion phase executes
    Then multiple agent_message events for the same phase may arrive in any order
    And the frontend must not assume a fixed ordering for parallel node outputs

  Scenario: Reconnecting client receives full history
    Given a client disconnects mid-session (network drop or page refresh)
    When the client reconnects to GET /sessions/{session_id}/stream
    Then the server replays all events from the beginning of stream_events
    And the client does not request a Last-Event-ID or implement manual reconnect
