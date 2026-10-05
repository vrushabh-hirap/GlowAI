import threading
import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query

from app import sheets_service as sheets
from app.api_schemas import AppointmentIn

router = APIRouter(prefix='/appointments', tags=['appointments'])

_lock = threading.Lock()

HEADER = ['appointmentId', 'patientId', 'doctorId', 'dateTime', 'mode', 'status', 'scanId', 'jitsiRoom', 'createdAt']
SLOT_HEADER = ['slotId', 'doctorId', 'date', 'startTime', 'endTime', 'status', 'appointmentId']


@router.post('')
def book(body: AppointmentIn):
    with _lock:  # one booking at a time so a slot can't be double-booked
        slots = sheets.get_all('Slots', force_fresh=True)
        match = None
        match_idx = None
        if body.slotId:
            for i, r in enumerate(slots):
                if str(r.get('slotId')) == body.slotId:
                    match, match_idx = r, i
                    break
        if match is not None and match.get('status') != 'Available':
            raise HTTPException(status_code=409, detail='Slot is no longer available')

        appointment_id = f'app_{uuid.uuid4().hex[:8]}'
        if match is not None:
            match['status'] = 'Booked'
            match['appointmentId'] = appointment_id
            ws = sheets.get_tab('Slots')
            ws.update(f'A{match_idx + 2}:G{match_idx + 2}', [[match.get(c, '') for c in SLOT_HEADER]])
            sheets.clear_cache()

        jitsi = f'https://meet.jit.si/GlowAI-{appointment_id}'
        sheets.put_row('Appointments', [
            appointment_id, body.patientId, body.doctorId, body.dateTime, body.mode,
            'Booked', body.scanId or '', jitsi, datetime.utcnow().isoformat(timespec='seconds'),
        ])
        return {'ok': True, 'appointmentId': appointment_id, 'jitsiRoom': jitsi, 'status': 'Booked'}


@router.patch('/{appointment_id}')
def cancel(appointment_id: str):
    rows = sheets.get_all('Appointments', force_fresh=True)
    for idx, r in enumerate(rows):
        if str(r.get('appointmentId')) == appointment_id:
            r['status'] = 'Cancelled'
            sheets.update_row('Appointments', idx + 2, [r.get(c, '') for c in HEADER])
            slots = sheets.get_all('Slots', force_fresh=True)
            for si, s in enumerate(slots):
                if str(s.get('appointmentId')) == appointment_id:
                    s['status'] = 'Available'
                    s['appointmentId'] = ''
                    sheets.update_row('Slots', si + 2, [s.get(c, '') for c in SLOT_HEADER])
            return {'ok': True, 'status': 'Cancelled'}
    raise HTTPException(status_code=404, detail='Appointment not found')


@router.get('')
def list_appointments(doctorId: str = Query(default=''), patientId: str = Query(default='')):
    rows = sheets.get_all('Appointments')
    out = []
    for r in rows:
        if doctorId and str(r.get('doctorId')) != doctorId:
            continue
        if patientId and str(r.get('patientId')) != patientId:
            continue
        out.append(r)
    return {'appointments': out}
