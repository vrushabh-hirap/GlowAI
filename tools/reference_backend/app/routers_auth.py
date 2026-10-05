import hashlib
import os
import secrets
import uuid

from fastapi import APIRouter, HTTPException

from app import sheets_service as sheets
from app.api_schemas import AuthLoginIn, AuthRegisterIn

router = APIRouter(prefix='/auth', tags=['auth'])

HEADER = ['userId', 'name', 'email', 'role', 'passwordHash', 'salt', 'phone', 'age', 'gender']


def _hash(password: str, salt: str) -> str:
    return hashlib.sha256(f'{salt}:{password}'.encode()).hexdigest()


def _find(email: str, role: str):
    rows = sheets.get_all('Users', force_fresh=True)
    for i, r in enumerate(rows):
        if str(r.get('email', '')).lower() == email.lower() and str(r.get('role', '')).lower() == role.lower():
            return i + 2, r
    return None, None


@router.post('/register')
def register(body: AuthRegisterIn):
    _, existing = _find(body.email, body.role)
    if existing is not None:
        raise HTTPException(status_code=409, detail='Email already registered')
    salt = secrets.token_hex(8)
    sheet_id = f'u_{uuid.uuid4().hex[:8]}'
    sheets.put_row('Users', [
        sheet_id, body.name, body.email, body.role, _hash(body.password, salt), salt,
        body.phone, body.age, body.gender,
    ])
    return {'ok': True, 'user': {'id': sheet_id, 'name': body.name, 'email': body.email, 'role': body.role, 'phone': body.phone, 'age': body.age, 'gender': body.gender}}


@router.post('/login')
def login(body: AuthLoginIn):
    _, row = _find(body.email, body.role)
    if row is None:
        raise HTTPException(status_code=401, detail='Invalid email, password, or role')
    if row.get('passwordHash') and row.get('salt'):
        expected = _hash(body.password, str(row['salt']))
        if expected != row.get('passwordHash'):
            raise HTTPException(status_code=401, detail='Invalid email, password, or role')
    elif str(row.get('password', '')) != body.password:  # legacy plain-text column fallback
        raise HTTPException(status_code=401, detail='Invalid email, password, or role')
    return {'ok': True, 'user': {'id': row.get('userId') or row.get('id'), 'name': row.get('name'), 'email': row.get('email'), 'role': row.get('role'), 'phone': row.get('phone', ''), 'age': row.get('age', ''), 'gender': row.get('gender', '')}}
