from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, auth, database

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI(title="SMAT API - Unidad I")

# CONFIGURACIÓN CRÍTICA PARA SEMANA 5 (CONEXIÓN MÓVIL)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/token", tags=["Seguridad"])
def login():
    return {"access_token": auth.crear_token({"sub": "admin_fisi"}), "token_type": "bearer"}

@app.get("/estaciones/", response_model=list[schemas.Estacion], tags=["SMAT"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    # 1. Traemos todas las estaciones de la base de datos
    estaciones_db = db.query(models.EstacionDB).all()
    resultado = []
    
    for est in estaciones_db:
        # 2. Buscamos la última telemetría guardada para esta estación
        ultima_lectura = db.query(models.LecturaDB)\
                           .filter(models.LecturaDB.estacion_id == est.id)\
                           .order_by(models.LecturaDB.id.desc())\
                           .first()
        
        # Si existe la lectura asignamos su valor, de lo contrario se queda en 0.0
        valor_medido = ultima_lectura.valor if ultima_lectura else 0.0
        
        # 3. Mapeamos manualmente a un diccionario estructurado independiente de SQLAlchemy
        est_mapeada = {
            "id": est.id,
            "nombre": est.nombre,
            "ubicacion": est.ubicacion,
            "ultimoValor": valor_medido  # Inyección forzada y limpia del valor real
        }
        resultado.append(est_mapeada)

    # 4. Retornamos la lista mapeada que Pydantic validará perfectamente
    return resultado

@app.post("/estaciones/", tags=["SMAT"])
def crear_estacion(estacion: schemas.EstacionCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    nueva = models.EstacionDB(**estacion.dict())
    db.add(nueva)
    db.commit()
    return nueva

@app.post("/lecturas/", tags=["Telemetría"])
def registrar_lectura(lectura: schemas.LecturaCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # Reto Maestro: Validación de existencia
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    nueva_lectura = models.LecturaDB(**lectura.dict())
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura registrada con éxito"}

# === NUEVAS RUTAS LABORATORIO 6.2 (CRUD COMPLETO) ===

@app.put("/estaciones/{id}/", tags=["SMAT"])
def editar_estacion(id: int, estacion_update: schemas.EstacionCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Actualizamos los campos
    estacion.nombre = estacion_update.nombre
    estacion.ubicacion = estacion_update.ubicacion
    
    db.commit()
    db.refresh(estacion)
    return estacion

@app.delete("/estaciones/{id}/", tags=["SMAT"])
def eliminar_estacion(id: int, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    db.delete(estacion)
    db.commit()
    return {"detail": "Estación eliminada correctamente"}