This project is a multi-purpose AI-powered assistant built with Python and Streamlit.
It combines three powerful tools in a single interactive web app:

Text & Web Summarizer – Summarizes long text or any public webpage using either

an OpenAI model (if API key available), or

a built-in lightweight fallback summarizer (no external dependencies).

Crypto Trends Dashboard – Fetches and displays the top performing cryptocurrencies from the CoinGecko API in the last 24 hours.

Live price updates

Percentage change

Market cap & trading volume

Utilities Panel – (optional section for expansion, e.g. analytics, extra tools, etc.)

Tech Stack

Python 3

Streamlit – interactive web app framework

Requests – API & web requests

BeautifulSoup – webpage text scraping

Pandas – data manipulation and tables

CoinGecko API – real-time crypto data

OpenAI API (optional) – for LLM-based summarization

Main Features

Summarize long text or online articles automatically

Scrape public webpages and generate concise summaries

View real-time crypto market movers

Fallback summarizer when OpenAI API key isn’t available

Ethical scraping (respects robots.txt, public pages only)

Runs locally via Streamlit with a clean, tabbed interface

How to Run

Install dependencies:

pip install streamlit requests pandas beautifulsoup4 openai


(Optional) Set your OpenAI API key (for smarter summaries):

export OPENAI_API_KEY="your_api_key_here"


Run the app:

streamlit run app.py


Open the link shown in your terminal — typically
http://localhost:8501

How It Works

If you provide a text or URL, the app fetches the content, cleans it, and summarizes it using either OpenAI or a simple algorithm.

The Crypto Trends tab calls the CoinGecko API to show current market movers in your selected currency (EUR/USD).

The sidebar lets you toggle OpenAI mode, set limits, and refresh data easily.

Example Use Cases

Quickly summarize long articles or news reports

Get an overview of today’s crypto market trends

Use as a foundation for building your own AI dashboard

Future Improvements

Add news sentiment analysis for crypto markets

Integrate RSS feed summarization

Store user summaries in a database

Add multilingual support
