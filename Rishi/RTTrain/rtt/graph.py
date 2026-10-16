"""The RTT StateGraph: collector -> planner -> per unit (analyzer -> labeler -> synthesizer -> council) -> report."""
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph import END, START, StateGraph

from rtt.configuration import CHECKPOINTS
from rtt.nodes import (analyzer, collector, gate, judge, labeler, next_unit, planner, queue_review, report,
                       route_council, route_gate, route_next, synthesizer, tally, write_training)
from rtt.state import State

builder = StateGraph(State)
for node in (collector, planner, next_unit, analyzer, labeler, synthesizer, gate, judge, tally, write_training, queue_review, report):
    builder.add_node(node.__name__, node)

builder.add_edge(START, "collector")
builder.add_edge("collector", "planner")
builder.add_edge("planner", "next_unit")
builder.add_conditional_edges("next_unit", route_next, ["analyzer", "gate", "report"])  # real -> analyzer, synthetic -> gate
builder.add_edge("analyzer", "labeler")
builder.add_edge("labeler", "synthesizer")
builder.add_edge("synthesizer", "gate")
builder.add_conditional_edges("gate", route_gate, ["judge", "analyzer", "write_training", "queue_review"])
builder.add_edge("judge", "tally")  # waits for all three judges
builder.add_conditional_edges("tally", route_council, ["analyzer", "write_training", "queue_review"])
builder.add_edge("write_training", "next_unit")
builder.add_edge("queue_review", "next_unit")
builder.add_edge("report", END)

graph = builder.compile()  # for `langgraph dev` / Studio
graph.name = "rttrain"


def run(h5_path: str, n_real: int, thread_id: str):
    """Stream (node, update) pairs for one recording; SQLite checkpoints let a crashed run resume on the same thread_id."""
    with SqliteSaver.from_conn_string(str(CHECKPOINTS)) as checkpointer:
        app = builder.compile(checkpointer=checkpointer)
        config = {"configurable": {"thread_id": thread_id}, "recursion_limit": 5000}  # one step per node per unit adds up
        for update in app.stream({"h5_path": h5_path, "n_real": n_real}, config, stream_mode="updates"):
            yield from update.items()
