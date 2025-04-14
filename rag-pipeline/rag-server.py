import os
import argparse
from dotenv import load_dotenv
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from openai import AzureOpenAI

# Load env variables
load_dotenv()

# Constants for Azure OpenAI
AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT")
AZURE_API_VERSION = "2025-01-01-preview"

# Razorpay integration instruction
INSTRUCTION = """
Integrate the Razorpay SDK into the following Swift file.

Use the documentation context provided to:
- Import necessary modules (e.g., Razorpay)
- Initialize Razorpay with required keys
- Trigger the Razorpay Checkout flow from the correct method (e.g., button tap)
- Ensure the view controller conforms to RazorpayPaymentCompletionProtocolWithData
- Include all required delegate methods and error handling

Keep the code clean and match existing indentation style. Do not return explanation or commentary. Respond only with the fully updated Swift code, ready to paste into the original file. I need the entire swift file in it's entirety.
"""

def get_context(query: str, k=4):
    embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    vectordb = Chroma(persist_directory="rag_db", embedding_function=embedding)
    docs = vectordb.similarity_search(query, k=k)
    return "\n\n".join([doc.page_content for doc in docs])

def build_prompt(context: str, file_content: str):
    return f"""{INSTRUCTION}

### CONTEXT:
{context}

### FILE CONTENT:
{file_content}
"""

def call_azure_openai(prompt: str) -> str:
    client = AzureOpenAI(
        api_key=AZURE_OPENAI_API_KEY,
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
        api_version=AZURE_API_VERSION,
    )

    response = client.chat.completions.create(
        model=AZURE_OPENAI_DEPLOYMENT,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3
    )

    return response.choices[0].message.content

def main():
    parser = argparse.ArgumentParser(description="Run RAG + Azure OpenAI to modify Swift file with Razorpay integration.")
    parser.add_argument("--file", required=True, help="Path to the Swift file to modify")
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"❌ File not found: {args.file}")
        return

    with open(args.file, 'r') as f:
        file_content = f.read()

    print("🔍 Retrieving context from documentation...")
    context = get_context(INSTRUCTION)

    print("🧠 Building prompt...")
    prompt = build_prompt(context, file_content)

    print("⚡ Calling Azure OpenAI...")
    result = call_azure_openai(prompt)

    print("\n✅ Generated Swift Code:\n")
    print(result)

if __name__ == "__main__":
    main()
