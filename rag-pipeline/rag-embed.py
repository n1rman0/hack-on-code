from langchain_community.document_loaders import TextLoader
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os

def load_docs(folder="docs"):
    docs = []
    for file in os.listdir(folder):
        if file.endswith(".md") or file.endswith(".swift"):
            file_path = os.path.join(folder, file)
            print(f"📄 Loading: {file}")
            loader = TextLoader(file_path)
            file_docs = loader.load()
            if file_docs:
                print(f"📏 {file} size: {len(file_docs[0].page_content)} characters")
                print(f"📝 Preview: {file_docs[0].page_content[:200]}...\n")
                docs.extend(file_docs)
            else:
                print(f"⚠️ Skipped {file}: No content loaded.")
    return docs

def embed_docs():
    raw_docs = load_docs()
    print(f"📦 Loaded {len(raw_docs)} documents")

    splitter = RecursiveCharacterTextSplitter(chunk_size=200, chunk_overlap=30)
    chunks = splitter.split_documents(raw_docs)
    print(f"✂️ Split into {len(chunks)} chunks")

    if not chunks:
        print("⚠️ No chunks to embed. Check your input files.")
        return

    embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    Chroma.from_documents(chunks, embedding, persist_directory="rag_db")
    print("✅ Embedding complete! Vector DB auto-saved to `rag_db/`")

if __name__ == "__main__":
    embed_docs()
