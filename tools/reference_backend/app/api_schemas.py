# api_schemas.py — request/response shapes for the shared-data API.
from typing import List, Optional
from pydantic import BaseModel, Field


class DoctorProfileIn(BaseModel):
    name: str = ''
    specialty: str = ''
    experience: str = ''
    languages: List[str] = Field(default_factory=list)
    fee: float = 0
    bio: str = ''
    photoUrl: str = ''
    phone: str = ''
    clinicAddress: str = ''
    modes: List[str] = Field(default_factory=list)
    isAvailable: bool = True


class SlotIn(BaseModel):
    date: str
    startTime: str
    endTime: str
    status: str = 'Available'


class SlotSetIn(BaseModel):
    slots: List[SlotIn] = Field(default_factory=list)


class AppointmentIn(BaseModel):
    patientId: str
    doctorId: str
    dateTime: str
    mode: str = 'video'
    slotId: Optional[str] = None
    scanId: Optional[str] = None


class PrescriptionIn(BaseModel):
    appointmentId: str = ''
    doctorId: str
    patientId: str
    date: str
    notes: str = ''
    followUpDate: str = ''
    medicinesJson: str = '[]'
    pdfPath: str = ''


class AuthLoginIn(BaseModel):
    email: str
    password: str
    role: str


class AuthRegisterIn(BaseModel):
    name: str
    email: str
    password: str
    role: str = 'patient'
    phone: str = ''
    age: str = ''
    gender: str = ''
