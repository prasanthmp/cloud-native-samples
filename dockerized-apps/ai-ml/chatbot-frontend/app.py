import os
import requests
import streamlit as st

# API URL from environment variable or default
API_URL = os.getenv("CHATBOT_API_URL", "http://127.0.0.1:8000/chat")

st.set_page_config(page_title="CPU Chatbot", layout="wide")

# --- Home / Information Section ---
st.title("🧠 CPU Chatbot (Streamlit Frontend)")

st.markdown(f"""
Welcome to the **CPU Chatbot**! This app is a simple AI assistant that interacts with a chat backend.

### How It Works
- The app uses a **chat API URL**, configured via environment variable `CHATBOT_API_URL`.  
  Default: `{API_URL}`
- The speed of responses depends on the model behind the API. Since this demo runs on **CPU**, responses may be slower for complex queries.

Type your message below and press **Send** or hit **Enter** to interact with the assistant.
""")

# --- Tips / Example Prompts ---
st.info("""
**💡 Tips & Example Prompts**
- Ask about cloud services: "Explain OCI in simple terms."
- Get coding help: "How do I write a Python function to sort a list?"
- Ask general knowledge: "Tell me about the Brooklyn Bridge."
- Ask for definitions or explanations: "What is Kubernetes and why is it used?"
""")

# --- Initialize session state ---
if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

if "button_disabled" not in st.session_state:
    st.session_state.button_disabled = False

# Placeholder for status message
status_placeholder = st.empty()

# Placeholder for chat display
chat_placeholder = st.empty()

# Render chat history without HTML
def render_chat_markdown():
    chat_md = ""
    for user_msg, bot_msg in st.session_state.chat_history:
        chat_md += f"**You:** {user_msg}\n\n"
        chat_md += f"**Assistant:** {bot_msg}\n\n"
    chat_placeholder.markdown(chat_md)

# Send message callback
def send_message():
    user_input = st.session_state.user_input
    if not user_input.strip():
        st.warning("Please enter a message before sending.")
        return

    st.session_state.button_disabled = True
    status_placeholder.info("⏳ Getting results, please wait...")

    try:
        response = requests.post(API_URL, json={"message": user_input})
        if response.status_code == 200:
            reply = response.json().get("response", "No response")
        else:
            reply = f"Error {response.status_code}: {response.text}"
    except Exception as e:
        reply = f"Failed to reach API: {e}"
    finally:
        # Append to chat history
        st.session_state.chat_history.append((user_input, reply))
        render_chat_markdown()
        st.session_state.user_input = ""  # clear input
        st.session_state.button_disabled = False
        status_placeholder.empty()

# Clear chat callback
def clear_chat():
    st.session_state.chat_history = []
    render_chat_markdown()

# --- Input area with on_change ---
st.text_area(
    "Your message:",
    key="user_input",
    height=100,
    on_change=send_message  # Trigger send when Enter pressed
)

# Buttons: Send and Clear
col1, col2 = st.columns([1, 1])
with col1:
    st.button(
        "Send",
        on_click=send_message,
        disabled=st.session_state.button_disabled
    )
with col2:
    st.button(
        "Clear Chat",
        on_click=clear_chat
    )

# Render chat history
render_chat_markdown()
