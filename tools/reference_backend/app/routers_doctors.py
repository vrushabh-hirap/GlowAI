import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException

from app import sheets_service as sheets
from app.api_schemas import DoctorProfileIn, SlotSetIn

router = APIRouter(prefix='/doctors', tags=['doctors'])

DOCTOR_COLS = [
    'doctorId', 'name', 'specialty', 'experience', 'languages', 'fee', 'bio',
    'photoUrl', 'phone', 'clinicAddress', 'modes', 'rating', 'isAvailable', 'updatedAt',
]


def _row_to_doctor(row):
    return {k: row.get(k, '') for k in DOCTOR_COLS}


@router.get('')
def list_doctors():
    rows = sheets.get_all('Doctors')
    return {'doctors': [_row_to_doctor(r) for r in rows]}


@router.get('/{doctor_id}')
def get_doctor(doctor_id: str):
    rows = sheets.get_all('Doctors')
    for r in rows:
        if str(r.get('doctorId')) == doctor_id:
            return _row_to_doctor(r)
    raise HTTPException(status_code=404, detail='Doctor not found')


@router.put('/{doctor_id}')
def update_doctor(doctor_id: str, body: DoctorProfileIn):
    rows = sheets.get_all('Doctors', force_fresh=True)
    for idx, r in enumerate(rows):
        if str(r.get('doctorId')) == doctor_id:
            r.update(body.model_dump())
            r['updatedAt'] = datetime.utcnow().isoformat(timespec='seconds')
            r['languages'] = ','.join(body.languages)
            r['modes'] = ','.join(body.modes)
            values = [r.get(k, '') for k in DOCTOR_COLS]
            sheets.update_row('Doctors', idx + 2, values)
            return {'ok': True, 'doctor': r}
    raise HTTPException(status_code=404, detail='Doctor not found')


@router.get('/{doctor_id}/slots')
def list_slots(doctor_id: str, date: Optional[str] = None):
    rows = sheets.get_all('Slots')
    out = []
    for r in rows:
        if str(r.get('doctorId')) != doctor_id:
            continue
        if date and str(r.get('date')) != date:
            continue
        out.append(r)
    return {'slots': out}


@router.put('/{doctor_id}/slots')
def set_slots(doctor_id: str, body: SlotSetIn):
    # Replace this doctor's slots for each affected date.
    rows = sheets.get_all('Slots', force_fresh=True)
    affected = {s.date for s in body.slots}
    kept = [r for r in rows if not (str(r.get('doctorId')) == doctor_id and str(r.get('date')) in affected and r.get('status') != 'Booked')]

    # Rewrite the whole Slots tab batch-wise: clear & re-append.
    from app import sheets_service as s
    ws = s.get_tab('Slots')
    # Only wipe rows that belonged to this doctor on affected dates and weren't Booked.
    new_rows = []
    for r in rows:
        if str(r.get('doctorId')) == doctor_id and str(r.get('date')) in affected and r.get('status') != 'Booked':
            continue
        new_rows.append(r)
    for sl in body.slots:
        new_rows.append({
            'slotId': f'slot_{uuid.uuid4().hex[:8]}',
            'doctorId': doctor_id,
            'date': sl.date,
            'startTime': sl.startTime,
            'endTime': sl.endTime,
            'status': sl.status,
            'appointmentId': '',
        })
    header = ['slotId', 'doctorId', 'date', 'startTime', 'endTime', 'status', 'appointmentId']
    # Fast path: clear and rewrite data rows in one batch
    ws.clear()
    ws.update('A1', [header] + [[r.get(c, '') for c in header] for r in new_rows])
    s.clear_cache()
    return {'ok': True, 'slots_written': len(body.slots)}
