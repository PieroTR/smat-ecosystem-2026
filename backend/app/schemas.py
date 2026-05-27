from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class EstacionBase(BaseModel):
    nombre: str
    ubicacion: str

class EstacionCreate(EstacionBase):
    pass

class Estacion(EstacionBase):
    id: int
    # --- RETO SEMANA 9: Campo dinámico necesario para enviar la telemetría a Flutter ---
    ultimoValor: float = 0.0  

    class Config:
        from_attributes = True

class LecturaBase(BaseModel):
    valor: float
    estacion_id: int

class LecturaCreate(LecturaBase):
    fecha: Optional[datetime] = None

class Lectura(LecturaBase):
    id: int
    fecha: datetime

    class Config:
        from_attributes = True