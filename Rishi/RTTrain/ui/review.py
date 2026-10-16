"""Review: queue, live fit plot, editable params, Accept / Save edit / Reject (blueprint wireframe, Figure 4)."""
from html import escape

import numpy as np
import plotly.graph_objects as go
import streamlit as st
import streamlit.components.v1 as components

import sp_core as sp
from rtt.tools import review_queue
from rtt.tools.gold import nearest
from sp_config import SEED_AP

RAW, FIT, AP, GOLD = "#2E8B57", "#E4572E", "#8E8E93", "#C9A227"
KEYS = """<script>
const doc = window.parent.document;
if (!doc.rttKeys) {
  doc.rttKeys = true;
  doc.addEventListener("keydown", e => {
    if (["INPUT", "TEXTAREA"].includes(e.target.tagName) || e.metaKey || e.ctrlKey) return;
    const label = {a: "Accept", e: "Save edit", r: "Reject"}[e.key.toLowerCase()];
    const btn = label && [...doc.querySelectorAll("button")].find(b => b.innerText.trim().startsWith(label));
    if (btn) { e.preventDefault(); btn.click(); }
  });
}
</script>"""

items = sorted(review_queue.waiting(), key=lambda i: (i["reason"], i["unit"]["unit_id"]))
agree = review_queue.agreement()
run_id = items[0]["run_id"] if items else "—"
st.markdown(f'<div class="rtt-bar"><b>Label Review</b><span>run {escape(run_id)}</span><span>{len(items)} waiting</span>'
            f'<span>agreement with council: {"—" if agree is None else f"{agree:.0%}"}</span></div>', unsafe_allow_html=True)
if not items:
    st.markdown('<div class="rtt-empty">Nothing waiting. Run a recording on the Upload & Run page.</div>', unsafe_allow_html=True)
    st.stop()

ids = [i["unit"]["unit_id"] for i in items]
if st.session_state.get("sel") not in ids: st.session_state.sel = ids[0]
item = items[ids.index(st.session_state.sel)]
u, uid = item["unit"], item["unit"]["unit_id"]
f, y = np.asarray(u["f"]), np.asarray(u["spectrum"])
v0 = np.array([np.nan if x is None else x for x in u["label"]], float)
if not np.isfinite(v0[:7]).all(): v0[:7] = sp.to_kernel(np.array(SEED_AP), np.empty(0))[:7]  # failed fit: start from the seed shape
key = lambda name: f"{uid}:{name}"  # widget state per unit
if key("npk") not in st.session_state: st.session_state[key("npk")] = max(1, int(np.isfinite(v0[7::3]).sum()))

left, mid, right = st.columns([1.1, 2.6, 1.3], gap="large")

with left, st.container(key="queue"):
    st.markdown("##### Queue")
    for i in items:
        iu = i["unit"]
        tag = " · synthetic" if iu["synthetic"] and i["reason"] != "synthetic" else ""
        if st.button(f"ch{iu['chan']} · t={iu['t']:.1f}  \n{i['reason']}{tag}", key=f"q:{iu['unit_id']}",
                     type="primary" if iu["unit_id"] == uid else "secondary", use_container_width=True):
            st.session_state.sel = iu["unit_id"]
            st.rerun()

with right:
    st.markdown("##### Edit params")
    v = v0.copy()
    v[0] = st.number_input("OFF (log10 power)", value=float(v0[0]), format="%.3f", key=key("OFF"))
    for j in range(3):
        a, b = st.columns(2)
        v[4 + j] = a.number_input(f"fk{j + 1} Hz", value=float(v0[4 + j]), min_value=0.01, format="%.2f", key=key(f"FC{j + 1}"))
        v[1 + j] = b.number_input(f"EXP{j + 1}", value=float(v0[1 + j]), min_value=0.0, format="%.3f", key=key(f"EXP{j + 1}"))
    for p in range(st.session_state[key("npk")]):
        s = 7 + 3 * p
        cf, pw, bw = (float(d if np.isnan(v0[s + i]) else v0[s + i]) for i, d in enumerate((10.0 * (p + 1), 0.0, 4.0)))
        c1, c2, c3 = st.columns(3)
        v[s] = c1.number_input(f"peak {p + 1} CF", value=cf, format="%.1f", key=key(f"CF{p + 1}"))
        v[s + 1] = c2.number_input("PW", value=pw, format="%.2f", key=key(f"PW{p + 1}"))
        v[s + 2] = c3.number_input("BW", value=bw, min_value=0.1, format="%.1f", key=key(f"BW{p + 1}"))
    if st.session_state[key("npk")] < sp.N_PEAKS and st.button("+ add peak", key=key("add")):
        st.session_state[key("npk")] += 1
        st.rerun()

with mid:
    show_gold = st.toggle("Gold overlays", key="gold")
    fit, ap = sp.kernel_eval(f, v)  # live redraw from the edited params
    fig = go.Figure()
    if show_gold:
        for g in nearest(f, y):
            fig.add_scatter(x=g["f"], y=g["spectrum"], name=f"gold ({g['distance']:.1f} dB)", line=dict(color=GOLD, width=1, dash="dot"))
    fig.add_scatter(x=f, y=y, name="raw", line=dict(color=RAW, width=2))
    fig.add_scatter(x=f, y=fit, name="fit", line=dict(color=FIT, width=2))
    fig.add_scatter(x=f, y=ap, name="aperiodic", line=dict(color=AP, width=1.5, dash="dash"))
    fig.update_layout(height=460, margin=dict(l=8, r=8, t=8, b=8), paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="#FFFFFF",
                      xaxis=dict(type="log", title="Hz", gridcolor="#EFEDE6"), yaxis=dict(title="dB", gridcolor="#EFEDE6"),
                      legend=dict(orientation="h", y=1.06), font=dict(family="-apple-system, Helvetica Neue, sans-serif"))
    st.plotly_chart(fig, use_container_width=True)

    qc = item["qc"]
    st.markdown(f'<p class="rtt-meta">{"synthetic, from " + escape(u["source"]) if u["synthetic"] else "real spectrum"} · '
                f'R² {qc.get("r2") or float("nan"):.3f} · MAE {qc.get("mae") or float("nan"):.2f} dB · '
                f'flags: {escape(", ".join(item["flags"]) or "none")} · attempts {item["attempts"]}</p>', unsafe_allow_html=True)
    votes = " | ".join(f"{v_['model'].removeprefix('claude-')} {v_['vote']}" + (f" ('{v_['reasons'][0]}')" if v_["vote"] != "accept" and v_["reasons"] else "")
                       for v_ in item["council"]) or "no votes (decided at Gate 1)"
    st.markdown(f'<p class="rtt-council">Council: {escape(votes)}</p><p class="rtt-analyzer">Analyzer: {escape(item["notes"] or "—")}</p>',
                unsafe_allow_html=True)

    b1, b2, b3 = st.columns(3)
    with b1, st.container(key="accept"): accept = st.button("Accept (A)", type="primary", use_container_width=True)
    with b2, st.container(key="edit"): save = st.button("Save edit (E)", use_container_width=True)
    with b3, st.container(key="reject"): reject = st.button("Reject (R)", use_container_width=True)

decision = "accept" if accept else "edit" if save else "reject" if reject else None
if decision:
    review_queue.decide(item, decision, (v if decision == "edit" else v0).tolist())
    st.session_state.pop("sel", None)
    st.rerun()

components.html(KEYS, height=0)  # A / E / R keyboard shortcuts
