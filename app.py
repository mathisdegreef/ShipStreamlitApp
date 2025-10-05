import streamlit as st

# Set the page config
st.set_page_config(page_title="Buddy Matching Tool", page_icon="buddy.ico")

# Title
st.title("Dummy Streamlit App")

# Button that shows a message
if st.button("Click me!"):
    st.write("Hello from your standalone app! 🚀")