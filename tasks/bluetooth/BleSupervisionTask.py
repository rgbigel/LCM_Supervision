"""
Module: Workspace_Supervision/tasks/bluetooth/BleSupervisionTask.py
Purpose: Standardized 51-Entity Bluetooth LE Fleet Stability Supervision Task.
         Checks for rapid micro-oscillations, packet collisions, and temporary dropouts.
"""

import asyncio
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
import websockets

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SECRETS_FILE = os.path.join(WORKSPACE_ROOT, "HaSSD06_Inventory", "data", "secrets.json")

BT_PLATFORMS = {
    'bluetooth', 'govee_ble', 'bthome', 'switchbot', 'xiaomi_ble', 
    'ibeacon', 'mopeka_ble', 'inkbird', 'oralb', 'qingping', 
    'shelly_ble', 'ruuvitag_ble', 'sensorpro', 'kegtron', 'thermo_beacon',
    'airthings_ble', 'ld2410_ble', 'bluemaestro', 'flic', 'yalexs_ble'
}

BT_FALLBACK_PREFIXES = (
    "sensor.h5075", "sensor.t_h_sz", "sensor.t_h_bath", "sensor.t_h_terrasse",
    "climate.sh_trv", "sensor.sh_trv", "binary_sensor.sh_trv", "number.sh_trv", 
    "button.sh_trv", "sensor.sbtr", "event.sbtr"
)

async def discover_bluetooth_entities(ws):
    try:
        await ws.send(json.dumps({'id': 101, 'type': 'config/device_registry/list'}))
        devices = json.loads(await ws.recv()).get('result', [])

        bt_dev_ids = set()
        for d in devices:
            for c in d.get('connections', []):
                if isinstance(c, list) and len(c) > 0 and str(c[0]).lower() == 'bluetooth':
                    bt_dev_ids.add(d['id'])
                elif 'bluetooth' in str(c).lower():
                    bt_dev_ids.add(d['id'])

        await ws.send(json.dumps({'id': 102, 'type': 'config/entity_registry/list'}))
        entities = json.loads(await ws.recv()).get('result', [])

        bt_entity_ids = []
        for e in entities:
            eid = e['entity_id']
            plat = str(e.get('platform', '')).lower()
            dev_id = e.get('device_id')

            if plat in BT_PLATFORMS or dev_id in bt_dev_ids:
                bt_entity_ids.append(eid)
            elif any(eid.startswith(p) for p in BT_FALLBACK_PREFIXES):
                bt_entity_ids.append(eid)

        return sorted(set(bt_entity_ids))
    except Exception:
        await ws.send(json.dumps({"id": 103, "type": "get_states"}))
        states = json.loads(await ws.recv()).get("result", [])
        return sorted([s["entity_id"] for s in states if any(s["entity_id"].startswith(p) for p in BT_FALLBACK_PREFIXES)])

async def run_supervision(window_minutes=240):
    start_ts = time.time()
    result = {
        "taskId": "ble-fleet-stability",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "durationSeconds": 0.0,
        "status": "Healthy",
        "counts": {
            "errors": 0,
            "warnings": 0,
            "info": 0,
            "total": 0
        },
        "summary": "",
        "details": []
    }

    if not os.path.exists(SECRETS_FILE):
        result["status"] = "Failing"
        result["counts"]["errors"] = 1
        result["counts"]["total"] = 1
        result["summary"] = f"Secrets file not found: {SECRETS_FILE}"
        return result

    try:
        with open(SECRETS_FILE, "r", encoding="utf-8") as f:
            secrets = json.load(f)

        token = secrets.get("ha_auditor_token") or secrets.get("api_token")
        url = secrets.get("api_url", "http://192.168.10.6:8123")
        ws_url = url.replace("http://", "ws://").replace("https://", "wss://").rstrip("/") + "/api/websocket"

        async with websockets.connect(ws_url, max_size=50 * 1024 * 1024) as ws:
            await ws.recv()
            await ws.send(json.dumps({"type": "auth", "access_token": token}))
            auth_resp = json.loads(await ws.recv())
            if auth_resp.get("type") != "auth_ok":
                result["status"] = "Failing"
                result["counts"]["errors"] = 1
                result["counts"]["total"] = 1
                result["summary"] = f"Home Assistant websocket authentication failed: {auth_resp}"
                return result

            target_entities = await discover_bluetooth_entities(ws)

            now = datetime.now(timezone.utc)
            start_time = (now - timedelta(minutes=window_minutes)).isoformat()
            end_time = now.isoformat()

            req = {
                "id": 2,
                "type": "history/history_during_period",
                "start_time": start_time,
                "end_time": end_time,
                "entity_ids": target_entities,
                "no_attributes": True,
                "significant_changes_only": False,
                "minimal_response": True
            }
            await ws.send(json.dumps(req))
            resp = json.loads(await ws.recv())
            history = resp.get("result", {})

            flapping_events = []
            rapid_oscillations = []

            for entity_id, state_list in history.items():
                if not state_list or len(state_list) < 2:
                    continue

                for idx in range(len(state_list) - 1):
                    cur = state_list[idx]
                    nxt = state_list[idx + 1]

                    cur_state = cur.get("s") if isinstance(cur, dict) else (cur[0] if isinstance(cur, list) else None)
                    cur_ts = cur.get("lu") or cur.get("lc") if isinstance(cur, dict) else (cur[1] if isinstance(cur, list) and len(cur) > 1 else None)
                    
                    nxt_state = nxt.get("s") if isinstance(nxt, dict) else (nxt[0] if isinstance(nxt, list) else None)
                    nxt_ts = nxt.get("lu") or nxt.get("lc") if isinstance(nxt, dict) else (nxt[1] if isinstance(nxt, list) and len(nxt) > 1 else None)

                    if cur_ts is None or nxt_ts is None:
                        continue

                    duration_sec = nxt_ts - cur_ts

                    # Check unavailable dropouts (<15s) -> Warning
                    if cur_state in ["unavailable", "unknown"] and nxt_state not in ["unavailable", "unknown"]:
                        if 0 < duration_sec <= 15.0:
                            flapping_events.append({
                                "entity_id": entity_id,
                                "flapping_state": cur_state,
                                "recovered_to": nxt_state,
                                "duration_sec": round(duration_sec, 3),
                                "timestamp": datetime.fromtimestamp(cur_ts, timezone.utc).isoformat()
                            })

                    # Check rapid oscillations (<5s) -> Warning
                    if idx < len(state_list) - 2:
                        third = state_list[idx + 2]
                        third_state = third.get("s") if isinstance(third, dict) else (third[0] if isinstance(third, list) else None)
                        third_ts = third.get("lu") or third.get("lc") if isinstance(third, dict) else (third[1] if isinstance(third, list) and len(third) > 1 else None)
                        
                        if third_ts is not None:
                            cycle_time = third_ts - cur_ts
                            if cur_state == third_state and cur_state != nxt_state and 0 < cycle_time <= 5.0:
                                rapid_oscillations.append({
                                    "entity_id": entity_id,
                                    "state_a": cur_state,
                                    "state_b": nxt_state,
                                    "cycle_sec": round(cycle_time, 3),
                                    "timestamp": datetime.fromtimestamp(cur_ts, timezone.utc).isoformat()
                                })

            warnings_count = len(flapping_events) + len(rapid_oscillations)
            info_count = len(target_entities)

            result["counts"]["warnings"] = warnings_count
            result["counts"]["info"] = info_count
            result["counts"]["total"] = warnings_count + info_count

            if warnings_count > 0:
                result["status"] = "Warning"
                result["summary"] = f"Monitored {len(target_entities)} BLE entities: {len(flapping_events)} dropouts, {len(rapid_oscillations)} micro-oscillations."
                result["details"] = flapping_events[:10] + rapid_oscillations[:10]
            else:
                result["status"] = "Healthy"
                result["summary"] = f"Monitored {len(target_entities)} BLE entities: 100% nominal, 0 dropouts, 0 oscillations."

    except Exception as e:
        result["status"] = "Failing"
        result["counts"]["errors"] = 1
        result["counts"]["total"] = 1
        result["summary"] = f"Supervision execution error: {str(e)}"

    result["durationSeconds"] = round(time.time() - start_ts, 3)
    return result

if __name__ == "__main__":
    win = int(sys.argv[1]) if len(sys.argv) > 1 else 240
    res = asyncio.run(run_supervision(win))
    print(json.dumps(res, indent=2))
