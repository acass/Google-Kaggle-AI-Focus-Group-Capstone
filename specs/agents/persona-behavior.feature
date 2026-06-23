# domain: agents
# maps-to: backend/agents/nodes/participant.py, backend/agents/personas.py, backend/agents/nodes/moderator.py
# constraint: participant nodes use gemini-2.5-flash; do NOT change to gemini-2.5-pro
# constraint: the voting node (make_vote) uses output_schema=ScoreSet for structured JSON; do not add search tools to it
# constraint: each participant node captures its loop variable via _p=p default arg to avoid closure bugs

Feature: Agent Persona Behavior
  Five distinct AI personas participate in a structured three-phase discussion.
  Each phase runs participant nodes in parallel (fan-out) and produces a specific
  output type written into session state.

  Scenario: Independent evaluation phase runs without cross-contamination
    Given a session has started with at least one participant
    And the moderator_introduce node has produced a moderator_intro string in state
    When each independent_{persona_id} node runs in parallel
    Then each node calls make_independent_response with its own persona dict
    And the result is merged into state.independent_responses[persona_id]
    And no participant node's prompt includes another participant's independent response

  Scenario: Moderator follow-up is generated after all independent responses are collected
    Given all parallel independent nodes have completed
    And state.independent_responses contains one entry per participant
    When the collect_independent JoinNode completes
    Then the moderator_followup node runs next (sequential)
    And it reads all independent_responses to generate targeted follow-up questions
    And the result is written to state.moderator_followup

  Scenario: Discussion phase allows cross-participant awareness
    Given state.moderator_followup is populated
    When each discussion_{persona_id} node runs in parallel
    Then each node calls make_discussion_response with its own persona dict
    And each participant's prompt includes the moderator's follow-up questions
    And each participant's prompt may include other participants' independent responses
    And the result is merged into state.discussion_responses[persona_id]

  Scenario: Voting phase produces structured scores via Gemini output schema
    Given state.discussion_responses contains one entry per participant
    And the collect_discussion JoinNode has completed
    When each vote_{persona_id} node runs in parallel
    Then each node calls make_vote with its own persona dict
    And the LLM call uses output_schema=ScoreSet for structured JSON output
    And the result is merged into state.scores[persona_id]
    And each ScoreSet contains exactly six float fields: innovation, market, ux, feasibility, monetization, risk

  Scenario: Each persona uses its configured LLM temperature
    Given any generative node (independent, discussion, or moderator)
    When the LLM call is made for a given persona
    Then the request uses that persona's temperature value from the PERSONAS dict
    And higher-temperature personas (e.g. Zoe Park at 0.9) produce more varied outputs
    And lower-temperature personas (e.g. David Okafor at 0.6) produce more consistent outputs

  Scenario: Moderator and Synthesizer use gemini-2.5-pro
    Given any moderator or synthesizer node
    When the LLM call is made
    Then the model is gemini-2.5-pro
    And participant nodes use gemini-2.5-flash (not gemini-2.5-pro)
