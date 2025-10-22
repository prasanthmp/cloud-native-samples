from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Initialize FastAPI
app = FastAPI(title="TinyLlama Chat API", description="Lightweight CPU-based chat model", version="1.0")

# Load model and tokenizer once at startup
model_name = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
print("⏳ Loading model, please wait...")

tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float32,
    device_map="cpu"
)

print("✅ Model loaded successfully and ready for chat!")

# Request schema
class ChatRequest(BaseModel):
    message: str
    max_new_tokens: int = 300

@app.post("/chat")
def chat(request: ChatRequest):
    try:
        # Prepare chat messages
        messages = [
            {"role": "system", "content": "You are a helpful and knowledgeable AI assistant."},
            {"role": "user", "content": request.message},
        ]

        # Create chat template
        prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)

        # Tokenize
        inputs = tokenizer(prompt, return_tensors="pt")

        # Generate
        outputs = model.generate(
            **inputs,
            max_new_tokens=request.max_new_tokens,
            temperature=0.7,
            top_p=0.9,
            repetition_penalty=1.1,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )

        # Decode response
        full_output = tokenizer.decode(outputs[0], skip_special_tokens=True)

        # Extract assistant's reply
        if "<|assistant|>" in full_output:
            response = full_output.split("<|assistant|>")[-1].strip()
        else:
            response = full_output[len(prompt):].strip()

        return {"response": response}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
