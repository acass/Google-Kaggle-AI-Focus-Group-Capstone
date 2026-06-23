# domain: security
# maps-to: backend/plugins/blue_team_plugin.py, backend/plugins/green_team_plugin.py
# constraint: MAX_TOOLS_PER_NODE = 10 (from backend/plugins/blue_team_plugin.py and MAX_TOOLS_PER_NODE file)
# constraint: trust_score deduction is exactly 25 per violation; floor is 0
# constraint: quarantine threshold is trust_score < 50 (strict less-than)
# constraint: Green Team raises RuntimeError — it does not return a dict or set a flag; it raises

Feature: Security Plugin Behavior
  Two ADK plugins run on every session.
  BlueTeamAnalyticsPlugin tracks per-node tool call counts and manages the trust score.
  GreenTeamQuarantinePlugin blocks all further tool execution once quarantine is active.

  Scenario: Blue Team records each tool call after it completes
    Given a session is running with any participant configuration
    When any ADK tool call completes in any workflow node
    Then the Blue Team after_tool_callback fires
    And a record is appended to state.agbom with node, tool, args, and status fields
    And the same record is appended to state.agbom_per_node[node_path]

  Scenario: Blue Team does not penalize nodes under the tool-call threshold
    Given a workflow node has made 10 or fewer tool calls (MAX_TOOLS_PER_NODE = 10)
    When the after_tool_callback fires for any of those calls
    Then trust_score remains unchanged
    And quarantine_flag remains false

  Scenario: Blue Team deducts trust score when a node exceeds the threshold
    Given a workflow node has already made exactly 10 tool calls
    When the 11th tool call completes in that same node
    Then trust_score is decremented by 25
    And the new trust_score = previous_trust_score - 25 (floor 0)
    And each subsequent excess call in that node also triggers a -25 deduction

  Scenario: Blue Team activates quarantine when trust score falls below 50
    Given trust_score has been decremented to below 50 (e.g. 25 after three violations)
    When the Blue Team after_tool_callback processes the violation
    Then quarantine_flag is set to true in session state
    And this flag persists for the remainder of the session

  Scenario: Green Team blocks all tool calls when quarantine is active
    Given quarantine_flag is true in session state
    When any ADK tool call is about to execute in any node
    Then the Green Team before_tool_callback raises RuntimeError
    And the RuntimeError message contains "Green Team Stateful Quarantine"
    And the tool is never executed
    And session state remains intact for forensic analysis (not cleared or corrupted)

  Scenario: Green Team allows tool calls when quarantine is not active
    Given quarantine_flag is false in session state
    When any ADK tool call is about to execute
    Then the Green Team before_tool_callback returns None
    And the tool executes normally

  Scenario: Security test mode triggers the full security response
    Given a session was created with security_test_mode = true
    When the workflow runs
    Then participant nodes are prompted to make more than 10 tool calls per node
    And the Blue Team plugin detects the excess and decrements trust_score
    And if trust_score drops below 50, quarantine_flag is set to true
    And if quarantine_flag is true, the Green Team raises RuntimeError halting the workflow
