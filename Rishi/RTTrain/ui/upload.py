"""Upload & Run: drop one nexDTS .h5 recording and run the pipeline on it."""
import time

import streamlit as st

from rtt.configuration import CONFIG, DIRS
from rtt.graph import run
from rtt.utils import spend


def show_spend(box, rows: list[dict]):
    """Live counter: LLM calls, tokens in/out, dollars."""
    s = spend(rows)
    with box.container():
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("LLM calls", f"{s['calls']} / {CONFIG.max_llm_calls}")
        c2.metric("Input tokens", f"{s['input']:,}")
        c3.metric("Output tokens", f"{s['output']:,}")
        c4.metric("Spent", f"${s['usd']:.4f}")


def describe(node: str, u: dict) -> str | None:
    """One readable line per graph update."""
    match node:
        case "collector": return f"**Collected** {u['run_id']} · {u['checks']}"
        case "planner": return f"**Planned** {len(u['pending'])} real spectra"
        case "next_unit": return f"→ {u['unit']['unit_id']}" if u.get("unit") else None
        case "analyzer": return f"**Analyzer** · {u.get('notes', '')}"
        case "labeler": return f"**Labeler** · R² {u['qc']['r2']:.3f} · MAE {u['qc']['mae']:.2f} dB · {u['qc']['n_peaks']} peaks"
        case "synthesizer": return f"**Synthesized** {CONFIG.n_synthetic} spectra" if u else None
        case "gate": return f"**Gate 1** · {u['verdict']} ({u['reason']})"
        case "judge": return f"**{u['council'][0]['model']}** · {u['council'][0]['vote']}"
        case "tally": return f"**Council** · {u['verdict']} ({u['reason']})"
        case "write_training" | "queue_review": return f"**{u['results'][0]['route']}** · {u['results'][0]['unit_id']}"
    return None


st.markdown('<div class="rtt-hero"><h1>RTTrain</h1><p>Drop one recording. The agents fit, check and label its spectra, '
            'and you review the ones they are unsure about.</p></div>', unsafe_allow_html=True)

_, mid, _ = st.columns([1, 2, 1])
with mid:
    up = st.file_uploader("nexDTS recording (.h5)", type=["h5"], label_visibility="collapsed")
    n_real = st.slider("Real spectra to sample", 1, 20, CONFIG.n_real,
                       help=f"Each real spectrum also yields {CONFIG.n_synthetic} synthetic spectra; all of them go through the council.")
    go = st.button("Run pipeline", type="primary", disabled=up is None, use_container_width=True)

if go:
    path = DIRS["uploads"] / up.name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(up.getbuffer())
    report, usage = "", []
    counter = st.empty()
    show_spend(counter, usage)
    with st.status("Running the pipeline…", expanded=True) as status:
        for node, update in run(str(path), n_real, thread_id=f"{path.stem}-{int(time.time())}"):
            update = update or {}
            report = update.get("report_md", report)
            if update.get("usage"):
                usage += update["usage"]
                show_spend(counter, usage)
            if line := describe(node, update): st.markdown(line)
        status.update(label="Run complete", state="complete", expanded=False)
    st.dataframe([dict(model=m, **v) for m, v in spend(usage)["per_model"].items()], hide_index=True,
                 column_config={"usd": st.column_config.NumberColumn("$", format="%.4f")})
    st.markdown(report)
    st.page_link("ui/review.py", label="Open the review queue →")
