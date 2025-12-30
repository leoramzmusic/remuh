import os
import shutil
import uuid
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import PlainTextResponse
import subprocess

app = FastAPI(title="REMUH Lyrics Sync Service")

UPLOAD_DIR = "temp_sync"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/sync")
async def sync_lyrics(
    audio: UploadFile = File(...),
    text: str = Form(...),
    lang: str = Form("spa")
):
    """
    Sincroniza el texto con el audio usando Aeneas.
    Retorna el contenido del archivo .lrc generado.
    """
    job_id = str(uuid.uuid4())
    job_dir = os.path.join(UPLOAD_DIR, job_id)
    os.makedirs(job_dir, exist_ok=True)

    audio_path = os.path.join(job_dir, "audio.mp3")
    text_path = os.path.join(job_dir, "lyrics.txt")
    output_path = os.path.join(job_dir, "output.lrc")

    try:
        # 1. Guardar archivos temporales
        with open(audio_path, "wb") as buffer:
            shutil.copyfileobj(audio.file, buffer)
        
        with open(text_path, "w", encoding="utf-8") as f:
            f.write(text)

        # 2. Ejecutar Aeneas (requiere estar instalado en el sistema/container)
        # Comando base: python -m aeneas.tools.execute_task
        command = [
            "python3", "-m", "aeneas.tools.execute_task",
            audio_path,
            text_path,
            f"task_language={lang}|is_text_type=plain|os_task_file_format=lrc",
            output_path
        ]

        # Nota: En un entorno real, esto debería ser asíncrono o usar un Task Queue (Celery)
        result = subprocess.run(command, capture_output=True, text=True)

        if result.returncode != 0:
            raise HTTPException(status_code=500, detail=f"Aeneas error: {result.stderr}")

        # 3. Leer y retornar el resultado
        if os.path.exists(output_path):
            with open(output_path, "r", encoding="utf-8") as f:
                lrc_content = f.read()
            return PlainTextResponse(content=lrc_content)
        else:
            raise HTTPException(status_code=500, detail="Output file was not generated")

    finally:
        # Limpieza (opcional: podrías querer mantener los logs de error)
        shutil.rmtree(job_dir, ignore_errors=True)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
