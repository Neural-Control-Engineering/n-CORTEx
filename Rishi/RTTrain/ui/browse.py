"""Browse: click through the exported ground-truth .h5 files in DATA_RTTRAIN and inspect each spectrum and its true params."""
import h5py
import numpy as np
import plotly.graph_objects as go
import streamlit as st

from groundtruthgen import paramspec
from groundtruthgen.kernel import aperiodic
from groundtruthgen.noise import noise_db_spread
from rtt.configuration import EXPORT_DIR
from rtt.tools.h5io import find_group

NOISY, CLEAN, AP = "#2E8B57", "#3A6EA5", "#8E8E93"


def step(key: str, delta: int, n: int):
    """Prev/next button callback: move a selection index, wrapping around."""
    st.session_state[key] = (st.session_state[key] + delta) % n


def load(path, ch: int):
    """One channel of one file: f, noisy (df), clean, true params, N, sample_id."""
    with h5py.File(path, "r") as h:
        g = h[find_group(h)]
        gt = h["groundtruth"]
        amp = float(gt["noiseAmp"][ch, 0]) if "noiseAmp" in gt else float("nan")  # files exported before noiseAmp existed lack it
        return (g["f"][:, 0], g["df"][0, :, ch], gt["psd_clean"][0, :, ch], gt["true_params"][ch], int(gt["N"][ch, 0]),
                gt["sample_id"][ch].decode(), amp, find_group(h))


folders = sorted(p.name for p in EXPORT_DIR.glob("N*") if p.is_dir())
if not folders:
    st.markdown(f'<div class="rtt-empty">No exported files in {EXPORT_DIR} yet. Generate and export some on Upload & Run.</div>',
                unsafe_allow_html=True)
    st.stop()

top = st.columns([1, 3, 1, 1])
folder = top[0].selectbox("Prior", folders)
files = sorted((EXPORT_DIR / folder).glob("*.h5"), key=lambda p: int(p.stem.rsplit("seed", 1)[-1]))
fkey = f"browse_file_{folder}"
st.session_state.setdefault(fkey, 0)
st.session_state[fkey] %= len(files)
top[1].selectbox("File", range(len(files)), format_func=lambda i: files[i].name, key=fkey)
top[2].button("◀ file", on_click=step, args=(fkey, -1, len(files)), width="stretch")
top[3].button("file ▶", on_click=step, args=(fkey, 1, len(files)), width="stretch")
path = files[st.session_state[fkey]]

with h5py.File(path, "r") as h: n_ch = h[find_group(h)]["df"].shape[2]
st.session_state.setdefault("browse_ch", 0)
st.session_state["browse_ch"] %= n_ch
row = st.columns([4, 1, 1])
row[0].slider("Channel (one generated spectrum each)", 0, n_ch - 1, key="browse_ch", format="ch %d")
row[1].button("◀ ch", on_click=step, args=("browse_ch", -1, n_ch), width="stretch")
row[2].button("ch ▶", on_click=step, args=("browse_ch", 1, n_ch), width="stretch")

f, noisy, clean, v, N, sample_id, amp, group = load(path, st.session_state["browse_ch"])
OFF, EXP, FC, peaks = paramspec.from_vector(v)
ap = aperiodic(f, OFF, paramspec.exp_to_d(EXP), FC)
peaks = peaks[~np.isnan(peaks).any(1)]

left, right = st.columns([2.6, 1.2], gap="large")
with left:
    m = f > 0  # log axis
    fig = go.Figure()
    fig.add_scatter(x=f[m], y=noisy[m], name="noisy (df)", line=dict(color=NOISY, width=1.5))
    fig.add_scatter(x=f[m], y=clean[m], name="true clean", line=dict(color=CLEAN, width=2.5))
    fig.add_scatter(x=f[m], y=ap[m], name="true aperiodic", line=dict(color=AP, width=1.5, dash="dash"))
    for k in range(N):
        fig.add_vline(x=FC[k], line=dict(color=AP, width=1, dash="dot"), annotation_text=f"FC{k + 1}", annotation_position="top")
    fig.update_layout(height=480, margin=dict(l=8, r=8, t=24, b=8), paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="#FFFFFF",
                      xaxis=dict(type="log", title="Hz", gridcolor="#EFEDE6"), yaxis=dict(title="dB", gridcolor="#EFEDE6"),
                      legend=dict(orientation="h", y=1.08), font=dict(family="-apple-system, Helvetica Neue, sans-serif"))
    st.plotly_chart(fig, width="stretch")
    if not np.isfinite(noisy).all():
        st.warning("This spectrum has infinite values (a very large peak overflowed), so parts of it can't be drawn.")
    st.caption(f"{path.name} · {sample_id} · {group}")

with right:
    show = lambda x: "Inf" if np.isinf(x) else "NaN" if np.isnan(x) else f"{x:.3f}"
    st.markdown(f"##### True params · N = {N}")
    st.dataframe([dict(param="OFF", value=show(OFF))]
                 + [dict(param=f"EXP{k + 1}", value=show(EXP[k])) for k in range(3)]
                 + [dict(param=f"FC{k + 1} Hz", value=show(FC[k])) for k in range(3)],
                 hide_index=True, width="stretch")
    st.markdown("##### Noise")
    st.dataframe([dict(param="noiseAmp (noise / signal)", value=show(amp)),
                  dict(param="spread in dB (±1 std)", value=show(noise_db_spread(2 / amp ** 2)) if np.isfinite(amp) else "—")],
                 hide_index=True, width="stretch")
    st.markdown(f"##### Peaks · {len(peaks)}")
    if len(peaks):
        st.dataframe([dict(peak=i + 1, CF=show(cf), PW=show(pw), dB=show(10 * pw), BW=show(bw)) for i, (cf, pw, bw) in enumerate(peaks)],
                     hide_index=True, width="stretch")
    else:
        st.caption("No peaks in this spectrum.")
