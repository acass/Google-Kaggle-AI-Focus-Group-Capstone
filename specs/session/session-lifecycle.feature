# domain: session
# maps-to: backend/api/sessions.py, backend/models/state.py, backend/models/schemas.py
# constraint: session IDs are UUIDs; state is in-memory only — no database persistence
# constraint: participant_ids must match keys in the PERSONAS dict in backend/agents/personas.py
# constraint: 1 to 5 participants per session

Feature: Session Lifecycle
  A client submits a topic string and a list of participant IDs.
  The platform creates a session, starts the ADK workflow in a background task,
  and streams progress events until the Synthesizer node completes.

  Scenario: Successful session creation
    Given a valid topic string and at least one valid participant ID
    When the client POSTs to /sessions with topic and participant_ids
    Then the response status is 201
    And the response body contains session_id (UUID string), topic, and participant_ids
    And a background ADK workflow task begins running for that session_id

  Scenario: Session status transitions through all workflow phases
    Given a session has been created with valid participants
    When the ADK workflow runs to completion
    Then the session phase progresses: intro -> independent -> discussion -> voting -> synthesis
    And each completed node emits SSE events that are appended to state.stream_events

  Scenario: Session completes with a final report
    Given the ADK workflow has reached and completed the synthesizer node
    When the client GETs /sessions/{session_id}
    Then the response field completed is true
    And final_report is populated with overall_score, category_averages, recommendation, and citations
    And final_report is not null

  Scenario: Session creation rejected for invalid participant IDs
    Given a request body with participant_ids containing an ID not present in PERSONAS
    When the client POSTs to /sessions
    Then the response status is 400
    And the response body describes which participant_id was invalid

  Scenario: Session creation rejected for too many participants
    Given a request body with more than 5 participant_ids
    When the client POSTs to /sessions
    Then the response status is 400

  Scenario: Security test mode enables intentional trust score decay
    Given a session creation request with security_test_mode set to true
    When the ADK workflow runs
    Then participant nodes make more than MAX_TOOLS_PER_NODE (10) tool calls per node
    And the Blue Team plugin decrements trust_score by 25 for each violation
    And quarantine_flag is set to true when trust_score falls below 50
    And the Green Team plugin raises a RuntimeError halting further tool execution
