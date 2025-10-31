import os
import re
import requests
import pandas as pd
import streamlit as st
from bs4 import BeautifulSoup
from urllib.parse import urlparse

# Use OpenAI if API key present; otherwise fallback to simple summarizer
USE_OPENAI = bool(os.getenv("OPENAI_API_KEY"))

st.set_page_config(page_title="AI Assistant: Summaries & Trends", layout="wide")
st.title("🤖 AI Assistant — Summarizer • Web • Crypto Trends")

# --------------------- Fallback summarizer (simple, no heavy deps)
def simple_summarize(text: str, max_sentences: int = 5) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    sentences = re.split(r"(?<=[.!?])\s+", text)
    if len(sentences) <= max_sentences:
        return text
    words = re.findall(r"[a-zA-Zà-ùÀ-Ù0-9']+", text.lower())
    freq = {}
    for w in words:
        if len(w) <= 2: continue
        freq[w] = freq.get(w, 0) + 1
    scores = []
    for s in sentences:
        sw = re.findall(r"[a-zA-Zà-ùÀ-Ù0-9']+", s.lower())
        score = sum(freq.get(w, 0) for w in sw) / (len(sw) + 1e-6)
        scores.append((score, s))
    top = sorted(scores, key=lambda x: -x[0])[:max_sentences]
    ordered = [s for _, s in sorted(top, key=lambda x: sentences.index(x[1]))]
    return " ".join(ordered)

def openai_summarize(text: str, max_words: int = 180) -> str:
    try:
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        prompt = (f"Summarize in clear, concise English (approx. {max_words} words). "
                  f"Use bullet points if helpful.\n\nText:\n{text}")
        resp = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role":"user","content":prompt}],
            temperature=0.3,
            max_tokens=400
        )
        return resp.choices[0].message['content'].strip()
    except Exception:
        return simple_summarize(text)

def summarize(text: str) -> str:
    if USE_OPENAI and len(text) > 0:
        return openai_summarize(text)
    return simple_summarize(text)

# --------------------- Scraper (ethical: public pages only)
def scrape_url(url: str, timeout=20) -> str:
    parsed = urlparse(url)
    if not parsed.scheme.startswith("http"):
        raise ValueError("Invalid URL (must start with http/https)")
    headers = {"User-Agent": "Mozilla/5.0"}
    r = requests.get(url, timeout=timeout, headers=headers)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    title = soup.title.get_text(strip=True) if soup.title else ""
    paragraphs = [p.get_text(" ", strip=True) for p in soup.find_all("p")]
    body = " ".join(paragraphs)
    return (title + "\n\n" + body).strip()

# --------------------- CoinGecko top movers
@st.cache_data(ttl=300)
def coingecko_top(n=10, vs="eur"):
    url = "https://api.coingecko.com/api/v3/coins/markets"
    r = requests.get(url, params={
        "vs_currency": vs,
        "order": "market_cap_desc",
        "per_page": 100, "page": 1, "sparkline": "false", "price_change_percentage": "24h"
    }, timeout=30)
    r.raise_for_status()
    df = pd.DataFrame(r.json())
    df = df[["id", "symbol", "name", "current_price", "price_change_percentage_24h", "market_cap", "total_volume"]]
    return df.sort_values("price_change_percentage_24h", ascending=False).head(n)

# --------------------- UI
with st.sidebar:
    st.header("Settings")
    use_openai = st.checkbox("Use OpenAI if available", value=USE_OPENAI)
    if use_openai and not USE_OPENAI:
        st.info("Set the OPENAI_API_KEY environment variable to enable the LLM.")

st.markdown("Select a module:")

tab1, tab2, tab3 = st.tabs(["📝 Summarize text/URL", "📈 Crypto Trends", "🧰 Utilities"])

with tab1:
    st.subheader("Summarize text or a web page")
    mode = st.radio("Source", ["Text", "URL"], horizontal=True)
    if mode == "Text":
        text = st.text_area("Paste the text here", height=220, placeholder="Put the article/text to summarize…")
        if st.button("Generate summary", type="primary"):
            if not text.strip():
                st.warning("Please enter some text.")
            else:
                with st.spinner("Summarizing…"):
                    out = openai_summarize(text) if use_openai and USE_OPENAI else simple_summarize(text)
                st.success("Done!")
                st.write(out)
    else:
        url = st.text_input("Public URL (http/https)", placeholder="https://...")
        if st.button("Summarize URL", type="primary"):
            try:
                with st.spinner("Downloading and summarizing…"):
                    raw = scrape_url(url)
                    out = openai_summarize(raw) if use_openai and USE_OPENAI else simple_summarize(raw)
                st.success("Done!")
                st.write(out)
            except Exception as e:
                st.error(f"Error: {e}")

with tab2:
    st.subheader("Top movers 24h (CoinGecko)")
    colA, colB = st.columns([1, 3])
    with colA:
        vs = st.selectbox("Currency", ["eur", "usd"], index=0)
        n = st.slider("Number of assets", 5, 25, 10)
    if st.button("Refresh", use_container_width=True):
        st.experimental_rerun()

    df = coingecko_top(n=n, vs=vs)
    st.dataframe(df, use_container_width=True)

    st.markdown("**Auto commentary:**")
    if len(df):
        gainers = df.head(3)[["name", "price_change_percentage_24h"]]
        bullets = "\n".join(
            f"- {row['name']}: {row['price_change_percentage_24h']:.2f}%"
            for _, row in gainers.iterrows()
        )
        commentary = f"In the last 24h top performers are:\n{bullets}\n\nNote: data is volatile."
        st.write(commentary)
