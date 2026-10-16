"""Light green and cream look: generous whitespace, system font, soft cards, pill buttons."""
import streamlit as st

CSS = """
<style>
:root { --cream:#FAF7EF; --card:#FFFFFF; --mint:#E3F1E6; --sage:#BFDDC7; --green:#3E8E5E; --ink:#1D1D1F; --muted:#6E6E73; --rose:#F6E4DF; --rust:#A44A3F; }
html, body, [class*="css"], .stMarkdown, button, input { font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Inter", "Helvetica Neue", sans-serif; }
.block-container { max-width: 1320px; padding-top: 2.5rem; padding-bottom: 4rem; }
h1, h2, h3, h4, h5 { color: var(--ink); letter-spacing: -0.02em; font-weight: 600; }

.rtt-hero { text-align: center; padding: 3.5rem 0 2rem; }
.rtt-hero h1 { font-size: 3.4rem; margin-bottom: .4rem; }
.rtt-hero p { color: var(--muted); font-size: 1.3rem; max-width: 640px; margin: 0 auto; line-height: 1.5; }

.rtt-bar { display: flex; gap: 2rem; align-items: center; background: var(--mint); border-radius: 20px;
           padding: 1rem 1.6rem; margin-bottom: 1.8rem; color: var(--ink); font-size: .98rem; }
.rtt-bar b { font-size: 1.1rem; }
.rtt-bar span { color: var(--muted); }
.rtt-empty { text-align: center; color: var(--muted); font-size: 1.2rem; padding: 5rem 0; }
.rtt-council { color: var(--green); margin: .2rem 0; }
.rtt-analyzer { color: #8A6D3B; margin: .2rem 0 1rem; }
.rtt-meta { color: var(--muted); font-size: .9rem; }

[data-testid="stFileUploaderDropzone"] { background: var(--card); border: 1.5px dashed var(--sage); border-radius: 24px; padding: 3rem; transition: border-color .25s ease, background .25s ease; }
[data-testid="stFileUploaderDropzone"]:hover { border-color: var(--green); background: #FDFCF8; }
[data-testid="stVerticalBlockBorderWrapper"] { border-radius: 20px; }

.stButton > button { border-radius: 980px; padding: .55rem 1.2rem; border: 1px solid var(--sage); background: var(--card);
                     color: var(--ink); transition: all .2s ease; }
.stButton > button:hover { border-color: var(--green); color: var(--green); transform: translateY(-1px); }
.stButton > button[kind="primary"] { background: var(--green); border-color: var(--green); color: #fff; }
.st-key-queue .stButton > button { border-radius: 14px; justify-content: flex-start; text-align: left; }
.st-key-edit .stButton > button { background: var(--mint); border-color: var(--sage); }
.st-key-reject .stButton > button { background: var(--rose); border-color: var(--rose); color: var(--rust); }
</style>
"""


def apply_style():
    st.markdown(CSS, unsafe_allow_html=True)
