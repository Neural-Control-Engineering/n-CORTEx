"""RTTrain app. Run from this folder:  streamlit run app.py"""
import streamlit as st

from ui.style import apply_style

st.set_page_config(page_title="RTTrain", page_icon="🌿", layout="wide")
apply_style()
st.navigation([st.Page("ui/upload.py", title="Upload & Run", default=True),
               st.Page("ui/review.py", title="Review"),
               st.Page("ui/browse.py", title="Browse")], position="top").run()
