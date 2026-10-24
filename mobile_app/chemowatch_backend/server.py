import os

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from openai import OpenAI

app = FastAPI(title="ChemoWatch Assistant API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://organic-parakeet-x5p9pv5qpjq73pp44-8080.app.github.dev"
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)

# Set OPENAI_API_KEY in the backend environment.
# Never put this key in main.dart or commit it to GitHub.
api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=api_key) if api_key else None


class AssistantRequest(BaseModel):
    question: str = Field(min_length=1, max_length=2000)
    recentReadings: list[dict] = Field(default_factory=list, max_length=10)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "ai_configured": client is not None,
    }


@app.post("/assistant")
def assistant(request: AssistantRequest):
    if client is None:
        raise HTTPException(
            status_code=503,
            detail="The AI service has not been configured.",
        )

    # Do not treat model output as a medical diagnosis.
    # Reading data is included only as context for general information.
    prompt = (
        "You are the general-information assistant for ChemoWatch, "
        "an app that records temperature and heart rate for people "
        "receiving chemotherapy. You are not a doctor and must not "
        "diagnose, rule out an emergency, or say that a patient is safe. "
        "If the user mentions fever, possible infection, or feeling "
        "unwell after chemotherapy, clearly tell them to follow their "
        "oncology team's instructions and contact the oncology team "
        "urgently as directed. Do not tell them to wait for an app, "
        "wearable, or AI response. Never invent readings or medical history. "
        "Explain that the app's readings may be inaccurate and are not "
        "a substitute for clinical measurement. Keep responses clear "
        "and concise. If the question describes a possible emergency, "
        "prioritize seeking urgent medical help.\n\n"
        f"User question:\n{request.question}\n\n"
        f"Recent app readings (unverified context):\n"
        f"{request.recentReadings}"
    )

    try:
        response = client.responses.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4.1-mini"),
            input=prompt,
        )
        answer = response.output_text

        return {"answer": answer}

    except Exception as exc:
        # Avoid returning secrets or detailed provider errors to the app.
        print(f"AI request failed: {type(exc).__name__}")
        raise HTTPException(
            status_code=502,
            detail="The AI service could not complete the request.",
        )