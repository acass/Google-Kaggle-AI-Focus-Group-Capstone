from google.adk.workflow import Workflow, JoinNode, node
from google.adk.events.event import Event
from typing import Any
from google.adk.agents.context import Context
from ..models.state import FocusGroupState, AgentPersona
from .nodes.moderator import moderator_introduce_node, moderator_followup_node
from .nodes.participant import make_independent_response, make_discussion_response, make_vote
from .nodes.synthesizer import synthesizer_node


def build_graph(participants: list[AgentPersona]) -> Workflow:
    join_indep = JoinNode(name="collect_independent")
    join_disc = JoinNode(name="collect_discussion")
    join_vote = JoinNode(name="collect_votes")

    @node(name="moderator_introduce", rerun_on_resume=True)
    async def mod_intro(ctx: Context, node_input: Any):
        result = await moderator_introduce_node(ctx, ctx.state)
        return Event(output=result, state=result)

    @node(name="moderator_followup", rerun_on_resume=True)
    async def mod_followup(ctx: Context, node_input: Any):
        result = await moderator_followup_node(ctx, ctx.state)
        return Event(output=result, state=result)

    @node(name="synthesizer", rerun_on_resume=True)
    async def synth(ctx: Context, node_input: Any):
        result = await synthesizer_node(ctx, ctx.state)
        return Event(output=result, state=result)
    
    indep_nodes = []
    disc_nodes = []
    vote_nodes = []
    
    for p in participants:
        # We use a default argument `_p=p` to capture the loop variable properly.
        @node(name=f"independent_{p['id']}", rerun_on_resume=True)
        async def indep_node(ctx: Context, node_input: Any, _p=p):
            res = await make_independent_response(ctx, ctx.state, _p)
            return Event(output=res, state=res)
        
        indep_nodes.append(indep_node)

        @node(name=f"discussion_{p['id']}", rerun_on_resume=True)
        async def disc_node(ctx: Context, node_input: Any, _p=p):
            res = await make_discussion_response(ctx, ctx.state, _p)
            return Event(output=res, state=res)
        
        disc_nodes.append(disc_node)

        @node(name=f"vote_{p['id']}", rerun_on_resume=True)
        async def v_node(ctx: Context, node_input: Any, _p=p):
            res = await make_vote(ctx, ctx.state, _p)
            return Event(output=res, state=res)
        
        vote_nodes.append(v_node)
        
    edges = [
        ('START', mod_intro),
        (mod_intro, tuple(indep_nodes)),
        (tuple(indep_nodes), join_indep),
        (join_indep, mod_followup),
        (mod_followup, tuple(disc_nodes)),
        (tuple(disc_nodes), join_disc),
        (join_disc, tuple(vote_nodes)),
        (tuple(vote_nodes), join_vote),
        (join_vote, synth)
    ]
    
    return Workflow(
        name="focus_group_workflow",
        edges=edges,
    )
