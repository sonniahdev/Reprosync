import firebase_admin
from firebase_admin import credentials, firestore

# Path to your downloaded key
cred = credentials.Certificate("firebase-service-account.json.json")
# cred = credentials.Certificate("firebase/serviceAccountKey.json")
# Initialize the app (only once)
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()
