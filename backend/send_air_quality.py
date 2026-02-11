import firebase_admin
from firebase_admin import credentials, db
import time
import random   # remove later when sensors added

cred = credentials.Certificate("serviceAccountKey.json")

firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://driveiq-cc5f5-default-rtdb.firebaseio.com'
})

ref_current = db.reference("air_quality/current")
ref_history = db.reference("air_quality/history")

while True:
    # TEMPORARY dummy values (replace with sensors later)
    temperature = random.randint(20, 35)
    humidity = random.randint(30, 70)
    co2 = random.randint(400, 1200)
    tvoc = random.randint(0, 500)

    if co2 < 600:
        status = "Good"
    elif co2 < 1000:
        status = "Moderate"
    else:
        status = "Poor"

    data = {
        "temperature": temperature,
        "humidity": humidity,
        "co2": co2,
        "tvoc": tvoc,
        "quality_status": status,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
    }

    # Live data
    ref_current.set(data)

    # History log
    ref_history.push(data)

    print("Air quality data updated")
    time.sleep(5)
