import time
import joblib
import numpy as np
import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    "databaseURL": "https://smart-irrigation-b9260-default-rtdb.asia-southeast1.firebasedatabase.app/"
})

model = joblib.load("irrigation_model.pkl")
label_encoder = joblib.load("label_encoder.pkl")

sensor_ref = db.reference("sensorData")
prediction_ref = db.reference("prediction")

def predict_and_push():
    data = sensor_ref.get()
    if not data:
        print("No sensor data yet")
        return

    features = np.array([[
        data.get("soilMoisture", 0),
        data.get("temperature", 0),
        data.get("humidity", 0),
        data.get("totalLiters", 0),
        1 if data.get("rainStatus") else 0
    ]])

    pred_num = model.predict(features)[0]
    pred_label = label_encoder.inverse_transform([pred_num])[0]

    prediction_ref.set({"irrigationNeed": pred_label})
    print("Predicted:", pred_label)

while True:
    predict_and_push()
    time.sleep(10)