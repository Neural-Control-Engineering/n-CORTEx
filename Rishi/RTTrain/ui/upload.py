"""Upload & Run: run the pipeline on one nexDTS .h5 recording, or generate a ground-truth dataset (groundtruthgen)."""
import time

import numpy as np
import plotly.graph_objects as go
import streamlit as st

from groundtruthgen import generate_ground_truth
from rtt.configuration import CONFIG, DIRS, EXPORT_DIR, GT_CONFIGS
from rtt.graph import run
from rtt.utils import spend

CLEAN, NOISY = "#E4572E", "#2E8B57"


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
        case "planner": return f"**Planned** {len(u['pending'])} spectra"
        case "next_unit": return f"→ {u['unit']['unit_id']}" if u.get("unit") else None
        case "analyzer": return f"**Analyzer** · {u.get('notes', '')}"
        case "labeler": return f"**Labeler** · R² {u['qc']['r2']:.3f} · MAE {u['qc']['mae']:.2f} dB · {u['qc']['n_peaks']} peaks"
        case "gate": return f"**Gate 1** · {u['verdict']} ({u['reason']})"
        case "judge": return f"**{u['council'][0]['model']}** · {u['council'][0]['vote']}"
        case "tally": return f"**Council** · {u['verdict']} ({u['reason']})"
        case "write_training" | "queue_review": return f"**{u['results'][0]['route']}** · {u['results'][0]['unit_id']}"
    return None


def preview(ds, k=3):
    """First k samples: clean vs noisy curve, plus their true aperiodic params."""
    fig = go.Figure()
    for i, r in enumerate(ds.rows[:k]):
        m = np.asarray(r.f) > 0  # log axis: leave out the f = 0 bin
        f, noisy, clean = (np.asarray(x)[m] for x in (r.f, r.psd_noisy, r.psd_clean))
        fig.add_scatter(x=f, y=noisy, name=f"{r.sample_id} noisy", line=dict(color=NOISY, width=1), opacity=0.5 + 0.5 * (i == 0))
        fig.add_scatter(x=f, y=clean, name=f"{r.sample_id} clean", line=dict(color=CLEAN, width=2, dash="dash" if i else "solid"))
    fig.update_layout(height=380, margin=dict(l=8, r=8, t=8, b=8), paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="#FFFFFF",
                      xaxis=dict(type="log", title="Hz", gridcolor="#EFEDE6"), yaxis=dict(title="dB", gridcolor="#EFEDE6"),
                      legend=dict(orientation="h", y=1.1), font=dict(family="-apple-system, Helvetica Neue, sans-serif"))
    st.plotly_chart(fig, width="stretch")
    names = ["OFF", "EXP1", "EXP2", "EXP3", "FC1", "FC2", "FC3"]
    st.dataframe([dict(sample=r.sample_id, N=r.N, **{n: str(round(x, 3)) for n, x in zip(names, r.true_params)},
                       peaks=(len(r.true_params) - 7) // 3) for r in ds.rows[:k]], hide_index=True)


def run_agents(inputs: dict, name: str):
    """Run the graph with a live log, token/$ counter and timer."""
    report, usage, t0 = "", [], time.time()
    counter = st.empty()
    if CONFIG.agents_enabled: show_spend(counter, usage)
    with st.status("Running the pipeline…", expanded=True) as status:
        for node, update in run(inputs, thread_id=f"{name}-{int(t0)}"):
            update = update or {}
            report = update.get("report_md", report)
            if update.get("usage"):
                usage += update["usage"]
                show_spend(counter, usage)
            if line := describe(node, update): st.markdown(line)
        status.update(label=f"Run complete in {time.time() - t0:.0f} s", state="complete", expanded=False)
    st.dataframe([dict(model=m, **v) for m, v in spend(usage)["per_model"].items()], hide_index=True,
                 column_config={"usd": st.column_config.NumberColumn("$", format="%.4f")})
    st.markdown(report)
    st.page_link("ui/review.py", label="Open the review queue →")


if not CONFIG.agents_enabled: st.info("Agents are off (rtt/configuration.py: agents_enabled). Runs fit and check spectra in code only, with no API calls; anything unclear goes to Review.")
st.markdown('<div class="rtt-hero"><h1>RTTrain</h1><p>Drop one recording to fit, check and label its spectra, '
            'or generate a ground-truth set with known parameters.</p></div>', unsafe_allow_html=True)

left, right = st.columns(2, gap="large")
with left, st.container(border=True):
    st.markdown("##### Run a recording")
    up = st.file_uploader("nexDTS recording (.h5)", type=["h5"], label_visibility="collapsed")
    n_real = st.slider("Spectra to sample", 1, 20, 2, help="Each one is fitted and checked; with agents on it also goes through the analyzer and council.")
    go_run = st.button("Run pipeline", type="primary", disabled=up is None, width="stretch")

with right, st.container(border=True):
    st.markdown("##### Generate ground truth")
    a, b, c = st.columns(3)
    N = a.selectbox("Knees (N)", (1, 2, 3), index=1)
    M = b.number_input("Samples (M)", 1, 100000, 2)
    seed = c.number_input("Seed", 0, 2**31 - 1, 42)
    cfg_path = GT_CONFIGS / f"priors_N{N}.yaml"
    with st.expander(f"Priors · {cfg_path.name}"):
        st.code(cfg_path.read_text(), language="yaml")
    go_gt = st.button("Generate dataset", width="stretch")

if go_gt:
    ds = generate_ground_truth(N, int(M), str(cfg_path), int(seed))
    out = DIRS["groundtruth"] / f"gt_N{N}_M{int(M)}_seed{int(seed)}.parquet"
    out.parent.mkdir(parents=True, exist_ok=True)
    ds.to_parquet(out)
    st.session_state.gt = (ds, out)

go_gt_run = False
if "gt" in st.session_state and not go_run:
    ds, out = st.session_state.gt
    st.markdown(f"##### {out.name} · {len(ds.rows)} samples · noise χ² df={ds.config['noise']['df']}")
    preview(ds)
    a, b, c, d = st.columns(4)
    n_gt = a.number_input("Spectra to run through the pipeline", 1, len(ds.rows), min(2, len(ds.rows)),
                          help="Agents off: no API cost. With agents on, each spectrum costs up to 16 LLM calls (4 analyzer + 12 judge).")
    go_gt_run = b.button("Run through the pipeline", type="primary", width="stretch")
    go_h5 = c.button("Export .h5", width="stretch",
                     help=f"Writes {out.stem}.h5 to {EXPORT_DIR} in the nexDTS_specparam_fitScope layout (df = noisy spectra, one channel per sample).")
    d.download_button("Download parquet", out.read_bytes(), file_name=out.name, width="stretch")
    if go_h5:
        EXPORT_DIR.mkdir(parents=True, exist_ok=True)
        group = ds.to_nexdts_h5(EXPORT_DIR / f"{out.stem}.h5")
        st.success(f"Saved {EXPORT_DIR / (out.stem + '.h5')}  ·  data in {group}")
    if go_gt_run: run_agents({"gt_path": str(out), "n_real": int(n_gt)}, out.stem)

if go_run:
    path = DIRS["uploads"] / up.name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(up.getbuffer())
    run_agents({"h5_path": str(path), "n_real": n_real}, path.stem)
