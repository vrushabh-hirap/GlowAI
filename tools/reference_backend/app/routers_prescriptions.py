import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query

from app import sheets_service as sheets
from app.api_schemas import PrescriptionIn

router = APIRouter(prefix='/prescriptions', tags=['prescriptions'])

HEADER = ['prescriptionId', 'appointmentId', 'doctorId', 'patientId', 'date', 'notes', 'followUpDate', 'medicinesJson', 'pdfPath']


@router.post('')
def create(body: PrescriptionIn):
    rid = f'rx_{uuid.uuid4().hex[:6]}'
    sheets.put_row('Prescriptions', [
        rid, body.appointmentId, body.doctorId, body.patientId, body.date or datetime.utcnow().date().isoformat(),
        body.notes, body.followUpDate, body.medicinesJson, body.pdfPath,
    ])
    return {'ok': True, 'prescriptionId': rid}


@router.get('')
def list_prescriptions(patientId: str = Query(default=''), doctorId: str = Query(default='')):
    rows = sheets.get_all('Prescriptions')
    out = []
    for r in rows:
        if patientId and str(r.get('patientId')) != patientId:
            continue
        if doctorId and str(r.get('doctorId')) != doctorId:
            continue
        out.append(r)
    return {'prescriptions': out}
