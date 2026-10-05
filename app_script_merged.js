const SHEET_NAME = 'Sheet1';

function getSheet_() {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
}

function doGet(e) {
  return doPost(e);
}

function doPost(e) {
  try {
    const p = e.parameter || {};
    const action = p.action;

    if (action === 'signup') return signup_(p);
    if (action === 'login') return login_(p);
    if (action === 'forgotPassword') return forgotPassword_(p);
    if (action === 'listDoctors') return listDoctors_();
    if (action === 'updateDoctorProfile') return updateDoctorProfile_(p);
    return json_({ ok: false, message: 'Unknown action' });
  } catch (err) {
    return json_({ ok: false, message: String(err) });
  }
}

function signup_(p) {
  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][2]).toLowerCase() === String(p.email).toLowerCase()) {
      return json_({ ok: false, message: 'Email already registered' });
    }
  }

  const id = 'u_' + Date.now();
  sheet.appendRow([
    id, p.name || '', p.email || '', p.password || '',
    p.role || 'patient', p.phone || '', p.age || '', p.gender || '',
    p.specialty || '', p.experience || '', p.languages || '', p.fee || '',
    p.bio || '', p.photoUrl || '', p.clinicAddress || '', p.modes || '',
    p.isAvailable === undefined ? 'true' : p.isAvailable, new Date().toISOString()
  ]);

  return json_({
    ok: true,
    user: { id, name: p.name, email: p.email, role: p.role, phone: p.phone, age: p.age, gender: p.gender }
  });
}

function login_(p) {
  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const emailMatch = String(row[2]).toLowerCase() === String(p.email).toLowerCase();
    const passMatch = String(row[3]) === String(p.password);
    const roleMatch = String(row[4]).toLowerCase() === String(p.role).toLowerCase();
    if (emailMatch && passMatch && roleMatch) {
      return json_({
        ok: true,
        user: { id: row[0], name: row[1], email: row[2], role: row[4], phone: row[5], age: row[6], gender: row[7] }
      });
    }
  }
  return json_({ ok: false, message: 'Invalid email, password, or role' });
}

function forgotPassword_(p) {
  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    const emailMatch = String(data[i][2]).toLowerCase() === String(p.email).toLowerCase();
    const roleMatch = String(data[i][4]).toLowerCase() === String(p.role).toLowerCase();
    if (emailMatch && roleMatch) {
      sheet.getRange(i + 1, 4).setValue(p.newPassword);
      return json_({ ok: true, message: 'Password updated' });
    }
  }
  return json_({ ok: false, message: 'No account found with that email and role' });
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function rowToDoctor(r) {
  return {
    id: r[0], name: r[1], email: r[2], role: r[4], phone: r[5], age: r[6], gender: r[7],
    specialty: r[8] || '', experience: r[9] || '', languages: r[10] || '', fee: r[11] || '',
    bio: r[12] || '', photoUrl: r[13] || '', clinicAddress: r[14] || '', modes: r[15] || '',
    isAvailable: r[16] === '' ? true : (r[16] === true || String(r[16]).toLowerCase() === 'true'),
    updatedAt: r[17] || '',
  };
}

function listDoctors_() {
  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();
  const doctors = [];
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (String(row[4]).toLowerCase() === 'doctor') {
      doctors.push(rowToDoctor(row));
    }
  }
  return ContentService.createTextOutput(JSON.stringify({ ok: true, doctors: doctors }))
    .setMimeType(ContentService.MimeType.JSON);
}

function updateDoctorProfile_(p) {
  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(p.id) && String(data[i][4]).toLowerCase() === 'doctor') {
      const row = data[i];
      if (p.name !== undefined) row[1] = p.name;
      if (p.phone !== undefined) row[5] = p.phone;
      if (p.specialty !== undefined) row[8] = p.specialty;
      if (p.experience !== undefined) row[9] = p.experience;
      if (p.languages !== undefined) row[10] = p.languages;
      if (p.fee !== undefined) row[11] = p.fee;
      if (p.bio !== undefined) row[12] = p.bio;
      if (p.photoUrl !== undefined) row[13] = p.photoUrl;
      if (p.clinicAddress !== undefined) row[14] = p.clinicAddress;
      if (p.modes !== undefined) row[15] = p.modes;
      if (p.isAvailable !== undefined) row[16] = p.isAvailable;
      row[17] = new Date().toISOString();
      sheet.getRange(i + 1, 1, 1, row.length).setValues([row]);
      return json_({ ok: true, doctor: rowToDoctor(row) });
    }
  }
  return json_({ ok: false, message: 'Doctor not found' });
}
