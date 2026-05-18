"""
Testa o endpoint qwen27b-sglang na Vast.ai.
Requer: pip install vastai
"""
import asyncio
import os

VAST_API_KEY = os.environ.get("VAST_API_KEY", open(os.path.expanduser("~/.config/vastai/vast_api_key")).read().strip())
ENDPOINT_NAME = "qwen27b-sglang"

async def main():
    from vastai import Serverless

    client = Serverless(api_key=VAST_API_KEY)
    print(f"Conectando ao endpoint '{ENDPOINT_NAME}'...")

    endpoint = await client.get_endpoint(name=ENDPOINT_NAME)

    payload = {
        "model": "qwen3.6-27b",
        "messages": [{"role": "user", "content": "Olá! Qual é 2+2?"}],
        "max_tokens": 100,
        "temperature": 0.7,
    }

    print("Enviando request...")
    result = await endpoint.request("/v1/chat/completions", payload, cost=200)
    print("Resposta:", result)
    await client.close()

if __name__ == "__main__":
    asyncio.run(main())
