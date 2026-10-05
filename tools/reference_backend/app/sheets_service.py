# sheets_service.py — Google Sheets as the shared database.
# Credentials come from a service_account.json path in .env (never committed).

import json
import os
import threading
import time
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv

load_dotenv()

try:
    import gspread
    from gspread.worksheet import Worksheet
except ImportError:  # gspread optional so tests don't need it
    gspread = None  # type: ignore
    Worksheet = Any  # type: ignore

CACHE_TTL_SECONDS = 30
RES_CONFIGURE_MSG = (
    "Set GOOGLE_SERVICE_ACCOUNT_FILE and GOOGLE_SHEET_ID in backend/.env "
    "(service_account.json must NOT be committed). Share the sheet with the "
    "service account email."
)

_cache: Dict[str, Any] = {}
_cache_ts: Dict[str, float] = {}
_cache_lock = threading.Lock()


def _env(key: str) -> Optional[str]:
    v = os.environ.get(key)
    return v.strip() if v else None


def _client():
    creds_path = _env('GOOGLE_SERVICE_ACCOUNT_FILE')
    if not creds_path:
        raise RuntimeError(RES_CONFIGURE_MSG)
    if gspread is None:
        raise RuntimeError('gspread is not installed')
    last_err = None
    for attempt in range(3):
        try:
            return gspread.service_account(filename=creds_path)
        except Exception as exc:  # retry with backoff
            last_err = exc
            time.sleep(0.5 * (2 ** attempt))
    raise RuntimeError(f'Could not auth Sheets: {last_err}')


def _wb():
    sheet_id = _env('GOOGLE_SHEET_ID')
    if not sheet_id:
        raise RuntimeError(RES_CONFIGURE_MSG)
    return _client().open_by_key(sheet_id)


def get_tab(tab_name: str) -> Worksheet:
    wb = _wb()
    try:
        return wb.worksheet(tab_name)
    except Exception:
        # create missing tabs so first run doesn't 500
        return wb.add_worksheet(title=tab_name, rows=1000, cols=30)


def get_all(tab_name: str, force_fresh: bool = False) -> List[Dict[str, Any]]:
    key = f'all:{tab_name}'
    now = time.time()
    with _cache_lock:
        if not force_fresh and key in _cache and now - _cache_ts.get(key, 0) < CACHE_TTL_SECONDS:
            return _cache[key]
    try:
        ws = get_tab(tab_name)
        rows = ws.get_all_records()
        with _cache_lock:
            _cache[key] = rows
            _cache_ts[key] = now
        return rows
    except Exception as exc:
        with _cache_lock:
            stale = _cache.get(key)
        if stale is not None:
            return stale
        raise RuntimeError(f'Sheets read failed: {exc}')


def find_row(tab_name: str, predicate) -> Optional[int]:
    """Returns the 1-based row index of the first record matching predicate,
    or None. Header row is row 1, records start at row 2."""
    rows = get_all(tab_name, force_fresh=True)
    for idx, row in enumerate(rows):
        if predicate(row):
            return idx + 2
    return None


def put_row(tab_name: str, row: List[Any]) -> None:
    ws = get_tab(tab_name)
    last_err = None
    for attempt in range(3):
        try:
            ws.append_row(row, value_input_option='USER_ENTERED')
            _invalidate(tab_name)
            return
        except Exception as exc:
            last_err = exc
            time.sleep(0.5 * (2 ** attempt))
    raise RuntimeError(f'Sheets append failed: {last_err}')


def update_row(tab_name: str, row_index: int, values: List[Any]) -> None:
    ws = get_tab(tab_name)
    last_err = None
    for attempt in range(3):
        try:
            ws.update(f'A{row_index}:{chr(65 + len(values) - 1)}{row_index}', [values])
            _invalidate(tab_name)
            return
        except Exception as exc:
            last_err = exc
            time.sleep(0.5 * (2 ** attempt))
    raise RuntimeError(f'Sheets update failed: {last_err}')


def _invalidate(tab_name: str) -> None:
    with _cache_lock:
        _cache.pop(f'all:{tab_name}', None)
        _cache_ts.pop(f'all:{tab_name}', None)


def clear_cache() -> None:
    with _cache_lock:
        _cache.clear()
        _cache_ts.clear()
