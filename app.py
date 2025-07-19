import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score, GridSearchCV
from sklearn.metrics import classification_report
from imblearn.over_sampling import SMOTE
import pickle
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from datetime import datetime, timedelta
import logging
import joblib
import bcrypt
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin
import requests
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import schedule
import time
import threading
import json
import jwt
from functools import wraps
import pytz

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Ensure the data directory exists
data_dir = os.path.abspath("data")
os.makedirs(data_dir, exist_ok=True)

# Initialize Firebase
try:
    cred = credentials.Certificate(os.path.join(data_dir, "firebase-service-account.json"))
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    logger.info("Firebase initialized successfully.")
except Exception as e:
    logger.error(f"Error initializing Firebase: {e}")
    raise

# Africa's Talking credentials (replace with your credentials)
AFRICAS_TALKING_USERNAME = "your_username"
AFRICAS_TALKING_API_KEY = "your_api_key"

# JWT Secret Key (replace with a secure key in production)
JWT_SECRET = "your_jwt_secret_key"
JWT_ALGORITHM = "HS256"

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load datasets
logger.info("Loading datasets...")
try:
    cervical_data = pd.read_excel(os.path.join(data_dir, "Cervical Cancer Datasets_.xlsx"))
    ovarian_data = pd.read_excel(os.path.join(data_dir, "Ovarian Cyst Track Data.xlsx"))
    inventory_data = pd.read_excel(os.path.join(data_dir, "Resources Inventory Cost Sheet.xlsx"))
    costs_data = pd.read_excel(os.path.join(data_dir, "Treatment Costs Sheet.xlsx"))
except Exception as e:
    logger.error(f"Error loading datasets: {e}")
    raise

# Symptoms for ovarian cyst dataset
symptoms = ["Pelvic Pain", "Bloating", "Nausea", "Fatigue", "Irregular Periods"]

# Validate region based on logged-in user's data
def validate_region(user_uid, region=None):
    try:
        # Fetch the user's document to get their region
        user_doc = db.collection("users").document(user_uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            valid_region = user_data.get("region", "").title().strip()
            if not valid_region:
                raise ValueError(f"No region found for user {user_uid} in Firebase.")
            return valid_region
        else:
            raise ValueError(f"User {user_uid} not found in Firebase.")
    except Exception as e:
        logger.error(f"Error validating region for user {user_uid}: {e}")
        raise ValueError(f"Unable to validate region due to an error: {str(e)}")

# Step 1: Clean Cervical Cancer Dataset
logger.info("Cleaning Cervical Cancer data...")
cervical_data = cervical_data.rename(columns={"Insrance Covered": "Insurance Covered"})
cervical_data["Region"] = cervical_data["Region"].str.strip().str.title().replace({
    "Pumwani ": "Pumwani",
    "Kakamega ": "Kakamega",
    "Machakos ": "Machakos"
})
cervical_data["HPV Test Result"] = cervical_data["HPV Test Result"].str.strip().str.title().replace({
    "Negagtive": "Negative", "Negativee": "Negative", "Pos": "Positive", "Possitive": "Positive"
})
cervical_data["Pap Smear Result"] = cervical_data["Pap Smear Result"].str.strip().str.title().replace({
    "N": "Negative", "Y": "Positive", "Neg": "Negative", "Negagtive": "Negative"
})
cervical_data["Smoking Status"] = cervical_data["Smoking Status"].str.strip().str.title().replace({"N": "No", "Y": "Yes"})
cervical_data["STDs History"] = cervical_data["STDs History"].str.strip().str.title().replace({"N": "No", "Y": "Yes"})
cervical_data["Insurance Covered"] = cervical_data["Insurance Covered"].str.strip().str.title().replace({"N": "No", "Y": "Yes"})
cervical_data["Screening Type Last"] = cervical_data["Screening Type Last"].str.strip().str.upper().replace({
    "Pap Smear": "PAP SMEAR", "Hpv Dna": "HPV DNA", "Via": "VIA"
})
cervical_data["Recommended Action"] = cervical_data["Recommended Action"].str.strip().str.title().replace({
    "Coloscopy": "Colposcopy",
    "Biospy": "Biopsy",
    "Colposocpy": "Colposcopy",
    "Repeat In 3 Years": "Repeat Pap Smear In 3 Years",
    "Follow-Up": "Repeat Pap Smear In 3 Years",
    "Follow Up": "Repeat Pap Smear In 3 Years",
    "For Annual Follow Up And Pap Smear In 3 Years": "Annual Follow Up And Pap Smear In 3 Years",
    "For Anual Follow Up And Pap Smear In 3 Years": "Annual Follow Up And Pap Smear In 3 Years",
    "For Colposcopy Biospy, Cytology": "Colposcopy, Biopsy, Cytology",
    "For Coloscopy Biosy, Cytology": "Colposcopy, Biopsy, Cytology",
    "Forcolposcopy, Cytology Then Laser Therapy": "Colposcopy, Cytology, Laser Therapy",
    "For Biopsy And Cytology With Tah Not Recommended": "Colposcopy, Biopsy, Cytology",
    "For Colposcopy Cytology": "Colposcopy, Biopsy, Cytology",
    "For Hpv Vaccine And Sexual Education": "Hpv Vaccine And Sexual Education",
    "For Hpv Vaccination And Sexual Education": "Hpv Vaccine And Sexual Education",
    "For Colposcopy Biopsy, Cytology +/- Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biopsy, Cytology +/-Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biospy, Cytology +/- Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biosy, Cytology+/- Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biopsy And Cytology+/- Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcpy Biopsy, Cytology": "Colposcopy, Biopsy, Cytology",
    "For Colposocpy Biopsy, Cytology With Tah Not Recommended": "Colposcopy, Biopsy, Cytology",
    "For Laser Therapy": "Laser Therapy",
    "For Pap Smear": "Repeat Pap Smear In 3 Years",
    "Repeat Pap Smear In 3Years": "Repeat Pap Smear In 3 Years",
    "Repeat Pap Smear In 3 Years And For Hpv Vaccine": "Repeat Pap Smear In 3 Years",
    "For Repeat Hpv Testing Annually And Pap Smear In 3 Years": "Repeat Pap Smear In 3 Years",
    "For Hpv Vaccine, Lifestyle And Sexual Education": "Hpv Vaccine And Sexual Education",
    "For Colposcopy Biopsy, Cytology +/-Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biopsy And Cytology+/- Tah": "Colposcopy, Biopsy, Cytology +/- Tah",
    "For Colposcopy Biospy, Cytology": "Colposcopy, Biopsy, Cytology",
    "Repeat Pap Smear In 3Years": "Repeat Pap Smear In 3 Years"
})

# Handle missing values
cervical_data = cervical_data.fillna({
    "Age": cervical_data["Age"].median(),
    "Sexual Partners": cervical_data["Sexual Partners"].median(),
    "First Sexual Activity Age": cervical_data["First Sexual Activity Age"].median(),
    "HPV Test Result": "Negative",
    "Pap Smear Result": "Negative",
    "Smoking Status": "No",
    "STDs History": "No",
    "Insurance Covered": "No",
    "Screening Type Last": "PAP SMEAR",
    "Recommended Action": "Repeat Pap Smear In 3 Years",
    "Region": ""  # Placeholder for region, validated in API
})

# Encode categorical variables
le_hpv = LabelEncoder()
le_pap = LabelEncoder()
le_smoking = LabelEncoder()
le_std = LabelEncoder()
le_insurance = LabelEncoder()
le_screening = LabelEncoder()
le_action = LabelEncoder()

cervical_data["HPV Test Result"] = le_hpv.fit_transform(cervical_data["HPV Test Result"])
cervical_data["Pap Smear Result"] = le_pap.fit_transform(cervical_data["Pap Smear Result"])
cervical_data["Smoking Status"] = le_smoking.fit_transform(cervical_data["Smoking Status"])
cervical_data["STDs History"] = le_std.fit_transform(cervical_data["STDs History"])
cervical_data["Insurance Covered"] = le_insurance.fit_transform(cervical_data["Insurance Covered"])
cervical_data["Screening Type Last"] = le_screening.fit_transform(cervical_data["Screening Type Last"])
cervical_data["Recommended Action"] = le_action.fit_transform(cervical_data["Recommended Action"])

# Save encoders
for le, name in [
    (le_hpv, "le_hpv"), (le_pap, "le_pap"), (le_smoking, "le_smoking"),
    (le_std, "le_std"), (le_insurance, "le_insurance"), (le_screening, "le_screening"),
    (le_action, "le_action")
]:
    pickle.dump(le, open(os.path.join(data_dir, f"{name}.pkl"), "wb"))

cervical_data.to_csv(os.path.join(data_dir, "cervical_cleaned.csv"), index=False)
logger.info("Cervical data cleaned!")

# Step 2: Clean Ovarian Cyst Dataset
logger.info("Cleaning Ovarian Cyst data...")
ovarian_data.loc[ovarian_data["Age"] < 40, "Menopause Status"] = "Pre-Menopausal"
ovarian_data["Menopause Status"] = ovarian_data["Menopause Status"].str.strip().str.title()
ovarian_data["Ultrasound Features"] = ovarian_data["Ultrasound Features"].str.strip().str.title()
ovarian_data["Recommended Management"] = ovarian_data["Recommended Management"].str.strip().str.title()
ovarian_data["Region"] = ovarian_data["Region"].str.strip().str.title()

# Create binary columns for symptoms
for symptom in symptoms:
    ovarian_data[symptom] = ovarian_data["Reported Symptoms"].apply(
        lambda x: 1 if symptom.lower() in str(x).lower() else 0
    )

ovarian_data = ovarian_data.fillna({
    "Age": ovarian_data["Age"].median(),
    "Cyst Size cm": ovarian_data["Cyst Size cm"].median(),
    "Cyst Growth Rate cm/month": ovarian_data["Cyst Growth Rate cm/month"].median(),
    "CA 125 Level": ovarian_data["CA 125 Level"].median(),
    "Menopause Status": "Pre-Menopausal",
    "Ultrasound Features": "Simple Cyst",
    "Recommended Management": "Observation",
    "Reported Symptoms": "",
    "Date of Exam": pd.Timestamp.now().floor("D"),
    "Region": ""  # Placeholder for region, validated in API
})

le_menopause = LabelEncoder()
le_ultrasound = LabelEncoder()
le_management = LabelEncoder()

ovarian_data["Menopause Status"] = le_menopause.fit_transform(ovarian_data["Menopause Status"])
ovarian_data["Ultrasound Features"] = le_ultrasound.fit_transform(ovarian_data["Ultrasound Features"])
ovarian_data["Recommended Management"] = le_management.fit_transform(ovarian_data["Recommended Management"])

for le, name in [
    (le_menopause, "le_menopause"), (le_ultrasound, "le_ultrasound"), (le_management, "le_management")
]:
    pickle.dump(le, open(os.path.join(data_dir, f"{name}.pkl"), "wb"))

ovarian_data.to_csv(os.path.join(data_dir, "ovarian_cleaned.csv"), index=False)
logger.info("Ovarian data cleaned!")

# Step 3: Clean Inventory and Costs Datasets
logger.info("Cleaning Inventory and Costs data...")
inventory_data["Facility"] = inventory_data["Facility"].str.strip().str.title()
inventory_data["Region"] = inventory_data["Region"].str.strip().str.title()
costs_data["Facility"] = costs_data["Facility"].str.strip().str.title()
costs_data["Region"] = costs_data["Region"].str.strip().str.title()
costs_data["Service"] = costs_data["Service"].str.strip().str.title()
costs_data["Category"] = costs_data["Category"].str.strip().str.title()
costs_data["NHIF Covered"] = costs_data["NHIF Covered"].str.strip().str.title().replace({"N": "No", "Y": "Yes"})

inventory_data = inventory_data.fillna({
    "Available Stock": 0,
    "Cost (KES)": inventory_data["Cost (KES)"].median()
})
costs_data = costs_data.fillna({
    "Base Cost (KES)": costs_data["Base Cost (KES)"].median(),
    "Insurance Copay (KES)": 0,
    "Out-of-Pocket (KES)": costs_data["Out-of-Pocket (KES)"].median()
})

costs_data["Base Cost (KES)"] = costs_data["Base Cost (KES)"].round(2)
costs_data["Insurance Copay (KES)"] = costs_data["Insurance Copay (KES)"].round(2)
costs_data["Out-of-Pocket (KES)"] = costs_data["Out-of-Pocket (KES)"].round(2)

inventory_data.to_csv(os.path.join(data_dir, "inventory_cleaned.csv"), index=False)
costs_data.to_csv(os.path.join(data_dir, "costs_cleaned.csv"), index=False)
logger.info("Inventory and Costs data cleaned!")

# Step 4: Train Cervical Cancer Model
logger.info("Training Cervical Cancer model...")
cervical_data = pd.read_csv(os.path.join(data_dir, "cervical_cleaned.csv"))
features = [
    "Age", "Sexual Partners", "First Sexual Activity Age",
    "HPV Test Result", "Pap Smear Result", "Smoking Status", "STDs History",
    "Screening Type Last"
]
target = "Recommended Action"
X = cervical_data[features]
y = cervical_data[target]

class_counts = y.value_counts()
valid_classes = class_counts[class_counts >= 2].index
if len(valid_classes) < len(class_counts):
    logger.info(f"Filtering out classes with fewer than 2 samples: {list(class_counts[class_counts < 2].index)}")
    valid_mask = y.isin(valid_classes)
    X = X[valid_mask]
    y = y[valid_mask]
    cervical_data = cervical_data[valid_mask]

min_samples = min(y.value_counts()) if not y.empty else 2
cv_folds = min(5, max(2, min_samples))
if min_samples >= 2:
    smote = SMOTE(random_state=42, k_neighbors=min(5, min_samples-1))
    try:
        X_resampled, y_resampled = smote.fit_resample(X, y)
    except ValueError as e:
        logger.error(f"SMOTE failed: {e}. Falling back to original data.")
        X_resampled, y_resampled = X, y
else:
    logger.warning("Not enough samples for SMOTE. Using original data.")
    X_resampled, y_resampled = X, y
    cv_folds = 2

param_grid = {
    "n_estimators": [100, 200],
    "max_depth": [5, 10, None],
    "min_samples_split": [2, 5],
    "min_samples_leaf": [1, 2]
}
cervical_model = RandomForestClassifier(random_state=42)
grid_search = GridSearchCV(cervical_model, param_grid, cv=cv_folds, scoring="accuracy", n_jobs=-1)
grid_search.fit(X_resampled, y_resampled)
cervical_model = grid_search.best_estimator_
logger.info(f"Best parameters: {grid_search.best_params_}")

if cv_folds >= 2:
    cv_scores = cross_val_score(cervical_model, X_resampled, y_resampled, cv=cv_folds, scoring="accuracy")
    logger.info(f"Cervical Model Cross-Validation Accuracy: {cv_scores.mean() * 100:.2f}% ± {cv_scores.std() * 100:.2f}%")
else:
    logger.info("Cross-validation skipped due to insufficient samples.")

cervical_model.fit(X_resampled, y_resampled)
predictions = cervical_model.predict(X)
logger.info("Cervical Model Classification Report:")
logger.info(classification_report(y, predictions, target_names=le_action.classes_[valid_classes], zero_division=0))
pickle.dump(cervical_model, open(os.path.join(data_dir, "cervical_model.pkl"), "wb"))

# Train Insurance Covered Model
logger.info("Training Insurance Covered model...")
insurance_features = [
    "Age", "Sexual Partners", "First Sexual Activity Age",
    "HPV Test Result", "Pap Smear Result", "Smoking Status", "STDs History",
    "Screening Type Last"
]
insurance_target = "Insurance Covered"
X_insurance = cervical_data[insurance_features]
y_insurance = cervical_data[insurance_target]

min_samples_insurance = min(y_insurance.value_counts()) if not y_insurance.empty else 2
cv_folds_insurance = min(5, max(2, min_samples_insurance))
if min_samples_insurance >= 2:
    smote_insurance = SMOTE(random_state=42, k_neighbors=min(5, min_samples_insurance-1))
    try:
        X_insurance_resampled, y_insurance_resampled = smote_insurance.fit_resample(X_insurance, y_insurance)
    except ValueError as e:
        logger.error(f"SMOTE failed for insurance: {e}. Falling back to original data.")
        X_insurance_resampled, y_insurance_resampled = X_insurance, y_insurance
else:
    logger.warning("Not enough samples for SMOTE in insurance data. Using original data.")
    X_insurance_resampled, y_insurance_resampled = X_insurance, y_insurance
    cv_folds_insurance = 2

insurance_model = RandomForestClassifier(random_state=42)
grid_search_insurance = GridSearchCV(insurance_model, param_grid, cv=cv_folds_insurance, scoring="accuracy", n_jobs=-1)
grid_search_insurance.fit(X_insurance_resampled, y_insurance_resampled)
insurance_model = grid_search_insurance.best_estimator_
logger.info(f"Insurance Model Best parameters: {grid_search_insurance.best_params_}")

if cv_folds_insurance >= 2:
    cv_scores_insurance = cross_val_score(insurance_model, X_insurance_resampled, y_insurance_resampled, cv=cv_folds_insurance, scoring="accuracy")
    logger.info(f"Insurance Model Cross-Validation Accuracy: {cv_scores_insurance.mean() * 100:.2f}% ± {cv_scores_insurance.std() * 100:.2f}%")
else:
    logger.info("Cross-validation skipped for insurance model due to insufficient samples.")

insurance_model.fit(X_insurance_resampled, y_insurance_resampled)
pickle.dump(insurance_model, open(os.path.join(data_dir, "insurance_model.pkl"), "wb"))

# Step 5: Train Ovarian Cyst Models
logger.info("Training Ovarian Cyst models...")
ovarian_data = pd.read_csv(os.path.join(data_dir, "ovarian_cleaned.csv"))
features = [
    "Age", "Menopause Status", "Cyst Size cm", "Cyst Growth Rate cm/month", "CA 125 Level",
    "Pelvic Pain", "Bloating", "Nausea", "Fatigue", "Irregular Periods"
]
target_management = "Recommended Management"
target_ultrasound = "Ultrasound Features"

X_management = ovarian_data[features]
y_management = ovarian_data[target_management]

min_samples_management = min(y_management.value_counts()) if not y_management.empty else 2
cv_folds_management = min(5, max(2, min_samples_management))
if min_samples_management >= 2:
    smote_management = SMOTE(random_state=42, k_neighbors=min(5, min_samples_management-1))
    try:
        X_management_resampled, y_management_resampled = smote_management.fit_resample(X_management, y_management)
    except ValueError as e:
        logger.error(f"SMOTE failed for management: {e}. Falling back to original data.")
        X_management_resampled, y_management_resampled = X_management, y_management
else:
    logger.warning("Not enough samples for SMOTE in management data. Using original data.")
    X_management_resampled, y_management_resampled = X_management, y_management
    cv_folds_management = 2

management_model = RandomForestClassifier(random_state=42)
grid_search_management = GridSearchCV(management_model, param_grid, cv=cv_folds_management, scoring="accuracy", n_jobs=-1)
grid_search_management.fit(X_management_resampled, y_management_resampled)
management_model = grid_search_management.best_estimator_
logger.info(f"Management Model Best parameters: {grid_search_management.best_params_}")

if cv_folds_management >= 2:
    cv_scores_management = cross_val_score(management_model, X_management_resampled, y_management_resampled, cv=cv_folds_management, scoring="accuracy")
    logger.info(f"Management Model Cross-Validation Accuracy: {cv_scores_management.mean() * 100:.2f}% ± {cv_scores_management.std() * 100:.2f}%")
else:
    logger.info("Cross-validation skipped for management model due to insufficient samples.")

management_model.fit(X_management_resampled, y_management_resampled)
predictions_management = management_model.predict(X_management)
logger.info("Management Model Classification Report:")
logger.info(classification_report(y_management, predictions_management, target_names=le_management.classes_, zero_division=0))
pickle.dump(management_model, open(os.path.join(data_dir, "management_model.pkl"), "wb"))

X_ultrasound = ovarian_data[features]
y_ultrasound = ovarian_data[target_ultrasound]

min_samples_ultrasound = min(y_ultrasound.value_counts()) if not y_ultrasound.empty else 2
cv_folds_ultrasound = min(5, max(2, min_samples_ultrasound))
if min_samples_ultrasound >= 2:
    smote_ultrasound = SMOTE(random_state=42, k_neighbors=min(5, min_samples_ultrasound-1))
    try:
        X_ultrasound_resampled, y_ultrasound_resampled = smote_ultrasound.fit_resample(X_ultrasound, y_ultrasound)
    except ValueError as e:
        logger.error(f"SMOTE failed for ultrasound: {e}. Falling back to original data.")
        X_ultrasound_resampled, y_ultrasound_resampled = X_ultrasound, y_ultrasound
else:
    logger.warning("Not enough samples for SMOTE in ultrasound data. Using original data.")
    X_ultrasound_resampled, y_ultrasound_resampled = X_ultrasound, y_ultrasound
    cv_folds_ultrasound = 2

ultrasound_model = RandomForestClassifier(random_state=42)
grid_search_ultrasound = GridSearchCV(ultrasound_model, param_grid, cv=cv_folds_ultrasound, scoring="accuracy", n_jobs=-1)
grid_search_ultrasound.fit(X_ultrasound_resampled, y_ultrasound_resampled)
ultrasound_model = grid_search_ultrasound.best_estimator_
logger.info(f"Ultrasound Model Best parameters: {grid_search_ultrasound.best_params_}")

if cv_folds_ultrasound >= 2:
    cv_scores_ultrasound = cross_val_score(ultrasound_model, X_ultrasound_resampled, y_ultrasound_resampled, cv=cv_folds_ultrasound, scoring="accuracy")
    logger.info(f"Ultrasound Model Cross-Validation Accuracy: {cv_scores_ultrasound.mean() * 100:.2f}% ± {cv_scores_ultrasound.std() * 100:.2f}%")
else:
    logger.info("Cross-validation skipped for ultrasound model due to insufficient samples.")

ultrasound_model.fit(X_ultrasound_resampled, y_ultrasound_resampled)
predictions_ultrasound = ultrasound_model.predict(X_ultrasound)
logger.info("Ultrasound Model Classification Report:")
logger.info(classification_report(y_ultrasound, predictions_ultrasound, target_names=le_ultrasound.classes_, zero_division=0))
pickle.dump(ultrasound_model, open(os.path.join(data_dir, "ultrasound_model.pkl"), "wb"))

# Load models and encoders
try:
    cervical_model = pickle.load(open(os.path.join(data_dir, "cervical_model.pkl"), "rb"))
    insurance_model = pickle.load(open(os.path.join(data_dir, "insurance_model.pkl"), "rb"))
    management_model = pickle.load(open(os.path.join(data_dir, "management_model.pkl"), "rb"))
    ultrasound_model = pickle.load(open(os.path.join(data_dir, "ultrasound_model.pkl"), "rb"))
    encoders = {
        "le_hpv": pickle.load(open(os.path.join(data_dir, "le_hpv.pkl"), "rb")),
        "le_pap": pickle.load(open(os.path.join(data_dir, "le_pap.pkl"), "rb")),
        "le_smoking": pickle.load(open(os.path.join(data_dir, "le_smoking.pkl"), "rb")),
        "le_std": pickle.load(open(os.path.join(data_dir, "le_std.pkl"), "rb")),
        "le_insurance": pickle.load(open(os.path.join(data_dir, "le_insurance.pkl"), "rb")),
        "le_screening": pickle.load(open(os.path.join(data_dir, "le_screening.pkl"), "rb")),
        "le_action": pickle.load(open(os.path.join(data_dir, "le_action.pkl"), "rb")),
        "le_menopause": pickle.load(open(os.path.join(data_dir, "le_menopause.pkl"), "rb")),
        "le_ultrasound": pickle.load(open(os.path.join(data_dir, "le_ultrasound.pkl"), "rb")),
        "le_management": pickle.load(open(os.path.join(data_dir, "le_management.pkl"), "rb"))
    }
    logger.info("Models and encoders loaded successfully.")
except Exception as e:
    logger.error(f"Error loading models or encoders: {e}")
    raise

# Helper functions for input normalization
def normalize_hpv_result(value):
    value = str(value).strip().lower()
    if value in ['negative', 'neg', 'negagtive', 'negativee', 'n', 'no', '-']:
        return 'Negative'
    elif value in ['positive', 'pos', 'possitive', 'p', 'yes', '+']:
        return 'Positive'
    elif value.title() in ['Negative', 'Positive']:
        return value.title()
    else:
        raise ValueError(f"Invalid HPV result: {value}")

def normalize_pap_result(value):
    value = str(value).strip().lower()
    if value in ['negative', 'neg', 'negagtive', 'negativee', 'n', 'no', 'normal']:
        return 'Negative'
    elif value in ['positive', 'pos', 'possitive', 'p', 'yes', 'abnormal', 'y']:
        return 'Positive'
    elif value.title() in ['Negative', 'Positive']:
        return value.title()
    else:
        raise ValueError(f"Invalid Pap smear result: {value}")

def normalize_yes_no(value):
    value = str(value).strip().lower()
    if value in ['no', 'n', 'false', '0', 'negative', 'neg']:
        return 'No'
    elif value in ['yes', 'y', 'true', '1', 'positive', 'pos']:
        return 'Yes'
    elif value.title() in ['Yes', 'No']:
        return value.title()
    else:
        raise ValueError(f"Invalid Yes/No value: {value}")

def normalize_screening_type(value):
    value = str(value).strip().upper()
    if value in ['PAP SMEAR', 'PAP', 'PAPSMEAR', 'PAP_SMEAR', 'PAPS']:
        return 'PAP SMEAR'
    elif value in ['HPV DNA', 'HPV', 'HPVDNA', 'HPV_DNA', 'DNA']:
        return 'HPV DNA'
    elif value in ['VIA', 'VISUAL INSPECTION', 'VISUAL']:
        return 'VIA'
    elif value in ['PAP SMEAR', 'HPV DNA', 'VIA']:
        return value
    else:
        raise ValueError(f"Invalid screening type: {value}")

# Token verification decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({'status': 'error', 'message': 'Bearer token malformed'}), 401

        if not token:
            return jsonify({'status': 'error', 'message': 'Token is missing'}), 401

        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            user_uid = data['user_uid']
            token_doc = db.collection("users").document(user_uid).collection("tokens").document(token).get()
            if not token_doc.exists or token_doc.to_dict().get('expires_at') < datetime.now(pytz.UTC):
                return jsonify({'status': 'error', 'message': 'Token is invalid or expired'}), 401
        except jwt.ExpiredSignatureError:
            return jsonify({'status': 'error', 'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'status': 'error', 'message': 'Invalid token'}), 401

        return f(user_uid, *args, **kwargs)
    return decorated

# WHO/ASCCP Guidelines Validation
def validate_recommendation_guidelines(user_uid, patient_data, predicted_recommendation):
    try:
        guidelines = {
            "HPV Positive and Pap Positive": {
                "condition": lambda data: data["hpv_result"] == "Positive" and data["pap_smear_result"] == "Positive",
                "recommendation": "Colposcopy, Biopsy, Cytology",
                "risk_level": "High",
                "min_age": 30,
                "rationale": "High-risk HPV with abnormal Pap smear requires immediate investigation (ASCCP 2019)."
            },
            "HPV Positive and Pap Negative, Young": {
                "condition": lambda data: data["hpv_result"] == "Positive" and data["pap_smear_result"] == "Negative" and data["age"] < 25,
                "recommendation": "Hpv Vaccine And Sexual Education",
                "risk_level": "Moderate",
                "min_age": 0,
                "rationale": "Young patients with HPV+ but normal Pap should focus on prevention (WHO 2022)."
            },
            "HPV Positive and Pap Negative, Older": {
                "condition": lambda data: data["hpv_result"] == "Positive" and data["pap_smear_result"] == "Negative" and data["age"] >= 25,
                "recommendation": "Annual Follow Up And Pap Smear In 3 Years",
                "risk_level": "Moderate",
                "min_age": 25,
                "rationale": "HPV+ with normal Pap in older patients requires closer monitoring (ASCCP 2019)."
            },
            "HPV Negative and Pap Negative": {
                "condition": lambda data: data["hpv_result"] == "Negative" and data["pap_smear_result"] == "Negative",
                "recommendation": "Repeat Pap Smear In 3 Years",
                "risk_level": "Low",
                "min_age": 0,
                "rationale": "Normal results indicate low risk; standard screening interval applies (WHO 2022)."
            },
            "HPV Negative and Pap Positive": {
                "condition": lambda data: data["hpv_result"] == "Negative" and data["pap_smear_result"] == "Positive",
                "recommendation": "Colposcopy, Biopsy, Cytology",
                "risk_level": "Moderate",
                "min_age": 0,
                "rationale": "Abnormal Pap without HPV requires further evaluation (ASCCP 2019)."
            }
        }

        normalized_data = {
            "age": patient_data["age"],
            "hpv_result": normalize_hpv_result(patient_data["hpv_result"]),
            "pap_smear_result": normalize_pap_result(patient_data["pap_smear_result"])
        }

        applied_guideline = None
        for guideline_name, rule in guidelines.items():
            if rule["condition"](normalized_data) and normalized_data["age"] >= rule["min_age"]:
                applied_guideline = guideline_name
                break

        if applied_guideline:
            guideline = guidelines[applied_guideline]
            is_compliant = predicted_recommendation == guideline["recommendation"]
            result = {
                "validated_recommendation": guideline["recommendation"],
                "risk_level": guideline["risk_level"],
                "guideline_applied": guideline_name,
                "rationale": guideline["rationale"],
                "is_compliant": is_compliant
            }
        else:
            result = {
                "validated_recommendation": predicted_recommendation,
                "risk_level": "Unknown",
                "guideline_applied": "None",
                "rationale": "No matching WHO/ASCCP guideline found.",
                "is_compliant": True
            }

        db.collection("patient_history").document(user_uid).collection("validations").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "patient_data": patient_data,
            "predicted_recommendation": predicted_recommendation,
            "validation_result": result
        })
        return result
    except Exception as e:
        logger.error(f"Error in validate_recommendation_guidelines: {e}")
        return {"error": str(e), "is_compliant": False}

# Risk Comparison Engine
def calculate_percentile_risk(user_uid, patient_data, condition_type):
    try:
        risk_scores = []
        if condition_type == "cervical":
            for _, record in cervical_data.iterrows():
                patient_df = pd.DataFrame([{
                    "Age": record["Age"],
                    "Sexual Partners": record["Sexual Partners"],
                    "First Sexual Activity Age": record["First Sexual Activity Age"],
                    "HPV Test Result": record["HPV Test Result"],
                    "Pap Smear Result": record["Pap Smear Result"],
                    "Smoking Status": record["Smoking Status"],
                    "STDs History": record["STDs History"],
                    "Screening Type Last": record["Screening Type Last"]
                }])
                probs = cervical_model.predict_proba(patient_df)[0]
                risk_score = max(probs) * 100
                risk_scores.append(risk_score)
            patient_df = pd.DataFrame([{
                "Age": patient_data["age"],
                "Sexual Partners": patient_data["sexual_partners"],
                "First Sexual Activity Age": patient_data["first_sexual_activity_age"],
                "HPV Test Result": encoders["le_hpv"].transform([normalize_hpv_result(patient_data["hpv_result"])])[0],
                "Pap Smear Result": encoders["le_pap"].transform([normalize_pap_result(patient_data["pap_smear_result"])])[0],
                "Smoking Status": encoders["le_smoking"].transform([normalize_yes_no(patient_data["smoking_status"])])[0],
                "STDs History": encoders["le_std"].transform([normalize_yes_no(patient_data["stds_history"])])[0],
                "Screening Type Last": encoders["le_screening"].transform([normalize_screening_type(patient_data["screening_type_last"])])[0]
            }])
            patient_probs = cervical_model.predict_proba(patient_df)[0]
            patient_risk = max(patient_probs) * 100
        else:  # ovarian
            for _, record in ovarian_data.iterrows():
                patient_df = pd.DataFrame([{
                    "Age": record["Age"],
                    "Menopause Status": record["Menopause Status"],
                    "Cyst Size cm": record["Cyst Size cm"],
                    "Cyst Growth Rate cm/month": record["Cyst Growth Rate cm/month"],
                    "CA 125 Level": record["CA 125 Level"],
                    "Pelvic Pain": record["Pelvic Pain"],
                    "Bloating": record["Bloating"],
                    "Nausea": record["Nausea"],
                    "Fatigue": record["Fatigue"],
                    "Irregular Periods": record["Irregular Periods"]
                }])
                probs = management_model.predict_proba(patient_df)[0]
                risk_score = max(probs) * 100
                risk_scores.append(risk_score)
            symptom_values = [1 if s.lower() in [x.lower() for x in patient_data.get("symptoms", [])] else 0 for s in symptoms]
            patient_df = pd.DataFrame([{
                "Age": patient_data["age"],
                "Menopause Status": encoders["le_menopause"].transform([patient_data["menopause_status"]])[0],
                "Cyst Size cm": patient_data["cyst_size"],
                "Cyst Growth Rate cm/month": patient_data.get("cyst_growth_rate", ovarian_data["Cyst Growth Rate cm/month"].median()),
                "CA 125 Level": patient_data["ca125_level"],
                "Pelvic Pain": symptom_values[0],
                "Bloating": symptom_values[1],
                "Nausea": symptom_values[2],
                "Fatigue": symptom_values[3],
                "Irregular Periods": symptom_values[4]
            }])
            patient_probs = management_model.predict_proba(patient_df)[0]
            patient_risk = max(patient_probs) * 100

        percentile = (sum(r < patient_risk for r in risk_scores) / len(risk_scores)) * 100
        risk_category = "Top 10%" if percentile >= 90 else "Top 25%" if percentile >= 75 else "Top 50%" if percentile >= 50 else "Bottom 50%"
        
        result = {
            "risk_score": patient_risk,
            "percentile": percentile,
            "risk_category": risk_category
        }
        
        db.collection("patient_history").document(user_uid).collection("risk_comparisons").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "condition_type": condition_type,
            "risk_result": result
        })
        return result
    except Exception as e:
        logger.error(f"Error in calculate_percentile_risk: {e}")
        return {"error": str(e)}

# Myth-Busting & Education Content
def get_education_content(user_uid, patient_data, recommendation):
    try:
        faqs = [
            {"question": "Can virgin women get HPV?", "answer": "While rare, HPV can be transmitted non-sexually, e.g., through skin-to-skin contact."},
            {"question": "Does a negative Pap smear mean I'm safe?", "answer": "A negative Pap smear reduces risk but doesn't eliminate it. Regular screening is essential."},
            {"question": "Is cervical cancer always caused by HPV?", "answer": "Most cases are linked to HPV, but other factors like smoking can contribute."}
        ]
        
        content = {
            "what_this_means": "",
            "why_it_matters": "",
            "faqs": [faq for faq in faqs if "HPV" in faq["question"] and patient_data.get("hpv_result") == "Positive"]
        }
        
        if recommendation == "Repeat Pap Smear In 3 Years":
            content["what_this_means"] = "Your results are normal. Regular screening helps catch changes early."
            content["why_it_matters"] = "Early detection through regular screening significantly reduces cervical cancer risk."
        elif "Colposcopy" in recommendation:
            content["what_this_means"] = "Abnormal results require further testing to assess potential risks."
            content["why_it_matters"] = "Colposcopy helps identify precancerous changes for timely intervention."
        
        db.collection("patient_history").document(user_uid).collection("education").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "patient_data": patient_data,
            "recommendation": recommendation,
            "content": content
        })
        return content
    except Exception as e:
        logger.error(f"Error in get_education_content: {e}")
        return {"error": str(e)}

def generate_pdf_report(user_uid, patient_data, recommendation, filename="report.pdf"):
    try:
        c = canvas.Canvas(os.path.join(data_dir, filename), pagesize=letter)
        c.drawString(100, 750, "Health Screening Report")
        c.drawString(100, 730, f"Patient UID: {user_uid}")
        c.drawString(100, 710, f"Date: {datetime.now().strftime('%Y-%m-%d')}")
        c.drawString(100, 690, "Patient Data:")
        y = 670
        for key, value in patient_data.items():
            c.drawString(120, y, f"{key}: {value}")
            y -= 20
        c.drawString(100, y-20, f"Recommendation: {recommendation}")
        c.save()
        return filename
    except Exception as e:
        logger.error(f"Error in generate_pdf_report: {e}")
        return None

def get_specialist_contacts(region):
    try:
        validate_region("", region)  # Validate region directly since no user_uid is available
        specialists = db.collection("specialists").where("region", "==", region.title()).get()
        return [{"name": s.to_dict().get("name"), "contact": s.to_dict().get("contact")} for s in specialists]
    except Exception as e:
        logger.error(f"Error in get_specialist_contacts: {e}")
        return []

def aggregate_anonymized_data():
    try:
        cervical_counts = {
            "hpv_positive": len(cervical_data[cervical_data["HPV Test Result"] == encoders["le_hpv"].transform(["Positive"])[0]]),
            "pap_positive": len(cervical_data[cervical_data["Pap Smear Result"] == encoders["le_pap"].transform(["Positive"])[0]])
        }
        ovarian_counts = {
            "high_ca125": len(ovarian_data[ovarian_data["CA 125 Level"] > ovarian_data["CA 125 Level"].quantile(0.75)])
        }
        return {"cervical": cervical_counts, "ovarian": ovarian_counts}
    except Exception as e:
        logger.error(f"Error in aggregate_anonymized_data: {e}")
        return {"error": str(e)}

# Reminder Service
def send_sms_reminder(phone, message):
    try:
        url = "https://api.africastalking.com/version1/messaging"
        headers = {
            "ApiKey": AFRICAS_TALKING_API_KEY,
            "Content-Type": "application/x-www-form-urlencoded"
        }
        data = {
            "username": AFRICAS_TALKING_USERNAME,
            "to": phone,
            "message": message
        }
        response = requests.post(url, headers=headers, data=data)
        return response.status_code == 201
    except Exception as e:
        logger.error(f"Error in send_sms_reminder: {e}")
        return False

def schedule_reminders():
    try:
        follow_ups = db.collection_group("follow_ups").where("follow_up_date", "<=", datetime.now() + timedelta(days=1)).get()
        for follow_up in follow_ups:
            data = follow_up.to_dict()
            user_uid = follow_up.reference.parent.parent.id
            user = db.collection("users").document(user_uid).get()
            if user.exists and user.to_dict().get("phone"):
                message = f"Reminder: Your follow-up appointment is scheduled for {data['follow_up_date'].strftime('%Y-%m-%d')}. Action: {data['action']}"
                if send_sms_reminder(user.to_dict()["phone"], message):
                    db.collection("patient_history").document(user_uid).collection("reminders").add({
                        "timestamp": firestore.SERVER_TIMESTAMP,
                        "message": message,
                        "status": "sent"
                    })
    except Exception as e:
        logger.error(f"Error in schedule_reminders: {e}")

def run_scheduler():
    schedule.every().day.at("08:00").do(schedule_reminders)
    while True:
        schedule.run_pending()
        time.sleep(60)

# Doctor Features
def generate_clinical_alerts(user_uid, patient_data, condition_type):
    try:
        alerts = []
        if condition_type == "cervical":
            if patient_data.get("hpv_result") == "Positive" and patient_data.get("pap_smear_result") == "Positive" and patient_data.get("age", 0) > 30:
                alerts.append({
                    "level": "High",
                    "message": "High-risk HPV+ and abnormal Pap smear in patient >30",
                    "action": "Immediate colposcopy recommended",
                    "timeline": "Within 2 weeks"
                })
        elif condition_type == "ovarian":
            if patient_data.get("cyst_size", 0) > 5 or patient_data.get("ca125_level", 0) > 35:
                alerts.append({
                    "level": "High",
                    "message": "Large cyst or elevated CA-125 detected",
                    "action": "Urgent specialist referral",
                    "timeline": "Within 1 week"
                })
        
        db.collection("patient_history").document(user_uid).collection("alerts").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "condition_type": condition_type,
            "alerts": alerts
        })
        return alerts
    except Exception as e:
        logger.error(f"Error in generate_clinical_alerts: {e}")
        return []

def plan_resources(user_uid, recommendation, condition_type):
    try:
        resources = {
            "cervical": {
                "Repeat Pap Smear In 3 Years": ["Pap Smear Kit"],
                "Colposcopy, Biopsy, Cytology": ["Colposcopy Equipment", "Pathology Lab"],
                "Hpv Vaccine And Sexual Education": ["HPV Vaccine", "Educational Materials"],
                "Annual Follow Up And Pap Smear In 3 Years": ["Pap Smear Kit", "Follow-up Scheduling"],
                "Colposcopy, Biopsy, Cytology +/- Tah": ["Colposcopy Equipment", "Pathology Lab", "Surgical Tools"],
                "Colposcopy, Cytology, Laser Therapy": ["Colposcopy Equipment", "Laser Therapy Equipment"],
                "Laser Therapy": ["Laser Therapy Equipment"]
            },
            "ovarian": {
                "Observation": ["Ultrasound Machine"],
                "Medical Management": ["Medications", "Ultrasound Machine"],
                "Surgery": ["Surgical Tools", "Operating Theater"],
                "Further Testing": ["Ultrasound Machine", "Lab Testing Equipment"]
            }
        }
        needed = resources.get(condition_type, {}).get(recommendation, ["General Equipment"])
        
        db.collection("patient_history").document(user_uid).collection("resources").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "condition_type": condition_type,
            "recommendation": recommendation,
            "resources_needed": needed
        })
        return needed
    except Exception as e:
        logger.error(f"Error in plan_resources: {e}")
        return []

def track_population_health(region=None):
    try:
        insights = {
            "high_risk_cervical": len(cervical_data[cervical_data["HPV Test Result"] == encoders["le_hpv"].transform(["Positive"])[0]]),
            "high_risk_ovarian": len(ovarian_data[ovarian_data["CA 125 Level"] > 35])
        }
        if region:
            insights["region"] = region
            insights["high_risk_cervical"] = len(cervical_data[(cervical_data["HPV Test Result"] == encoders["le_hpv"].transform(["Positive"])[0]) & (cervical_data["Region"] == region)])
            insights["high_risk_ovarian"] = len(ovarian_data[(ovarian_data["CA 125 Level"] > 35) & (ovarian_data["Region"] == region)])
        return insights
    except Exception as e:
        logger.error(f"Error in track_population_health: {e}")
        return {}

def generate_automated_care_plan(user_uid, recommendation, patient_data, condition_type):
    try:
        care_plan = {
            "follow_up": "3 months" if "Repeat" in recommendation or "Observation" in recommendation else "1 month",
            "resources_needed": plan_resources(user_uid, recommendation, condition_type),
            "educational_tip": "Regular screening is key!" if "Repeat" in recommendation or "Observation" in recommendation else "Follow specialist advice."
        }
        
        db.collection("patient_history").document(user_uid).collection("care_plans").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "condition_type": condition_type,
            "recommendation": recommendation,
            "care_plan": care_plan
        })
        return care_plan
    except Exception as e:
        logger.error(f"Error in generate_automated_care_plan: {e}")
        return {}

# Longitudinal Tracking
def generate_patient_history_timeline(user_uid):
    try:
        history = {
            "user_uid": user_uid,
            "cervical_timeline": [],
            "ovarian_timeline": [],
            "risk_progression": []
        }
        
        cervical_records = db.collection("patient_history").document(user_uid).collection("cervical").get()
        for record in cervical_records:
            data = record.to_dict()
            patient_df = pd.DataFrame([{
                "Age": data["age"],
                "Sexual Partners": data["sexual_partners"],
                "First Sexual Activity Age": data["first_sexual_activity_age"],
                "HPV Test Result": encoders["le_hpv"].transform([normalize_hpv_result(data["hpv_result"])])[0],
                "Pap Smear Result": encoders["le_pap"].transform([normalize_pap_result(data["pap_smear_result"])])[0],
                "Smoking Status": encoders["le_smoking"].transform([normalize_yes_no(data["smoking_status"])])[0],
                "STDs History": encoders["le_std"].transform([normalize_yes_no(data["stds_history"])])[0],
                "Screening Type Last": encoders["le_screening"].transform([normalize_screening_type(data["screening_type_last"])])[0]
            }])
            probs = cervical_model.predict_proba(patient_df)[0]
            risk_score = max(probs) * 100
            history["cervical_timeline"].append({
                "date": data["date"].strftime("%Y-%m-%d") if data.get("date") else datetime.now().strftime("%Y-%m-%d"),
                "hpv_result": data["hpv_result"],
                "pap_smear_result": data["pap_smear_result"],
                "insurance_covered": data["insurance_covered"],
                "screening_type_last": data["screening_type_last"],
                "recommended_action": data["recommended_action"],
                "risk_score": risk_score,
                "treatment_response": data.get("treatment_response", "N/A")
            })
            history["risk_progression"].append({
                "date": data["date"].strftime("%Y-%m-%d") if data.get("date") else datetime.now().strftime("%Y-%m-%d"),
                "risk_score": risk_score,
                "condition": "Cervical"
            })

        ovarian_records = db.collection("patient_history").document(user_uid).collection("ovarian").get()
        for record in ovarian_records:
            data = record.to_dict()
            symptom_values = [1 if s.lower() in [x.lower() for x in data.get("symptoms", [])] else 0 for s in symptoms]
            patient_df = pd.DataFrame([{
                "Age": data["age"],
                "Menopause Status": encoders["le_menopause"].transform([data["menopause_status"]])[0],
                "Cyst Size cm": data["cyst_size"],
                "Cyst Growth Rate cm/month": data.get("cyst_growth_rate", ovarian_data["Cyst Growth Rate cm/month"].median()),
                "CA 125 Level": data["ca125_level"],
                "Pelvic Pain": symptom_values[0],
                "Bloating": symptom_values[1],
                "Nausea": symptom_values[2],
                "Fatigue": symptom_values[3],
                "Irregular Periods": symptom_values[4]
            }])
            probs = management_model.predict_proba(patient_df)[0]
            risk_score = max(probs) * 100
            history["ovarian_timeline"].append({
                "date": data["date"].strftime("%Y-%m-%d") if data.get("date") else datetime.now().strftime("%Y-%m-%d"),
                "ultrasound_features": data["ultrasound_features"],
                "recommended_management": data["recommended_management"],
                "symptoms": data["symptoms"],
                "risk_score": risk_score,
                "treatment_response": data.get("treatment_response", "N/A")
            })
            history["risk_progression"].append({
                "date": data["date"].strftime("%Y-%m-%d") if data.get("date") else datetime.now().strftime("%Y-%m-%d"),
                "risk_score": risk_score,
                "condition": "Ovarian"
            })

        history["cervical_timeline"] = sorted(history["cervical_timeline"], key=lambda x: x["date"])
        history["ovarian_timeline"] = sorted(history["ovarian_timeline"], key=lambda x: x["date"])
        history["risk_progression"] = sorted(history["risk_progression"], key=lambda x: x["date"])
        
        return history
    except Exception as e:
        logger.error(f"Error in generate_patient_history_timeline: {e}")
        return {"error": str(e)}

# Advanced Educational Content
def generate_advanced_education(user_uid, patient_data, recommendation, condition_type):
    try:
        risk_factors = []
        if condition_type == "cervical":
            if patient_data.get("hpv_result") == "Positive":
                risk_factors.append({"factor": "HPV Status", "description": "Positive HPV increases cervical cancer risk.", "modifiable": True})
            if patient_data.get("smoking_status") == "Yes":
                risk_factors.append({"factor": "Smoking", "description": "Smoking increases cervical cancer risk.", "modifiable": True})
        elif condition_type == "ovarian":
            if patient_data.get("cyst_size", 0) > 5:
                risk_factors.append({"factor": "Cyst Size", "description": "Large cysts may indicate higher ovarian cancer risk.", "modifiable": False})
            if patient_data.get("ca125_level", 0) > 35:
                risk_factors.append({"factor": "CA-125 Level", "description": "Elevated CA-125 may indicate higher ovarian cancer risk.", "modifiable": False})

        symptom_checker = {
            "symptoms_to_monitor": ["Pelvic Pain", "Bloating", "Abnormal Bleeding"] if condition_type == "ovarian" else ["Abnormal Bleeding"],
            "instructions": "Report these symptoms to your doctor immediately."
        }

        lifestyle_recommendations = []
        if condition_type == "cervical":
            if patient_data.get("smoking_status") == "Yes":
                lifestyle_recommendations.append("Consider smoking cessation programs.")
            if patient_data.get("sexual_partners", 0) > 3:
                lifestyle_recommendations.append("Practice safe sex to reduce HPV risk.")
        elif condition_type == "ovarian":
            lifestyle_recommendations.append("Maintain regular gynecological check-ups.")

        content = {
            "risk_factors": risk_factors,
            "symptom_checker": symptom_checker,
            "lifestyle_recommendations": lifestyle_recommendations
        }
        
        db.collection("patient_history").document(user_uid).collection("advanced_education").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            "condition_type": condition_type,
            "patient_data": patient_data,
            "recommendation": recommendation,
            "content": content
        })
        return content
    except Exception as e:
        logger.error(f"Error in generate_advanced_education: {e}")
        return {"error": str(e)}

# Endpoints
# Updated /login endpoint with email and password
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'status': 'error', 'message': 'Email and password are required'}), 400

        # Query Firebase for the user by email
        logger.info(f"Attempting to find user with email: {email}")
        users_ref = db.collection("users")
        query = users_ref.where('email', '==', email).limit(1).get()
        users = list(query)  # Convert to list to inspect results

        logger.info(f"Query returned {len(users)} document(s)")
        if not users:
            logger.warning(f"No user found for email: {email}. Query executed against Firestore.")
            return jsonify({'status': 'error', 'message': 'Invalid email or password'}), 401

        user = users[0]  # Take the first (and only) result
        if not user.exists:
            logger.warning(f"User document does not exist for email: {email}")
            return jsonify({'status': 'error', 'message': 'Invalid email or password'}), 401

        user_data = user.to_dict()
        logger.info(f"Fetched user data: {user_data}")  # Log full document for debugging

        stored_password_hash = user_data.get('password_hash')
        if not stored_password_hash:
            logger.error(f"No password_hash found for user with email: {email}. Document: {user_data}")
            return jsonify({'status': 'error', 'message': 'Invalid email or password'}), 401

        try:
            password_check = bcrypt.checkpw(password.encode('utf-8'), stored_password_hash.encode('utf-8'))
            logger.info(f"Password check result for email {email}: {'Success' if password_check else 'Failure'}")
        except Exception as bcrypt_err:
            logger.error(f"bcrypt checkpw error for email {email}: {str(bcrypt_err)}")
            return jsonify({'status': 'error', 'message': 'Internal server error during password verification'}), 500

        if not password_check:
            logger.warning(f"Password mismatch for email: {email}. Stored hash: {stored_password_hash}")
            return jsonify({'status': 'error', 'message': 'Invalid email or password'}), 401

        user_uid = user.id
        expiration = datetime.utcnow() + timedelta(hours=24)
        try:
            token = jwt.encode({
                'user_uid': user_uid,
                'exp': expiration
            }, JWT_SECRET, algorithm=JWT_ALGORITHM)
        except Exception as jwt_err:
            logger.error(f"JWT encoding error for user_uid {user_uid}: {str(jwt_err)}")
            return jsonify({'status': 'error', 'message': 'Internal server error during token generation'}), 500

        try:
            db.collection("users").document(user_uid).collection("tokens").document(token).set({
                'created_at': firestore.SERVER_TIMESTAMP,
                'expires_at': expiration
            })
        except Exception as firestore_err:
            logger.error(f"Firestore error saving token for user_uid {user_uid}: {str(firestore_err)}")
            return jsonify({'status': 'error', 'message': 'Internal server error during token storage'}), 500

        logger.info(f"Login successful for user_uid: {user_uid}")
        return jsonify({
            'status': 'success',
            'user_uid': user_uid,
            'role': user_data.get('role'),
            'token': token
        })
    except Exception as e:
        logger.error(f'Unexpected error in /login: {str(e)}', exc_info=True)
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500
    
    
    
    

@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.json
        email = data.get('email').strip()
        password = data.get('password').strip()
        full_name = data.get('fullName')
        username = data.get('username')
        date_of_birth = data.get('dateOfBirth')
        role = data.get('role')
        region = data.get('region')
        has_family_history = data.get('hasFamilyHistory')
        family_history_type = data.get('familyHistoryType')
        family_relation = data.get('familyRelation')

        # Validate required fields
        required_fields = [email, password, full_name, username, date_of_birth, role, region, has_family_history]
        if any(field is None or field == '' for field in required_fields) or \
           (has_family_history == 'Yes' and (family_history_type is None or family_relation is None)):
            return jsonify({'status': 'error', 'message': 'Please fill in all required fields'}), 400

        # Check if user already exists
        users_ref = db.collection("users")
        query = users_ref.where('email', '==', email).limit(1).get()
        if list(query):
            return jsonify({'status': 'error', 'message': 'User with this email already exists'}), 400

        # Hash the password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        # Prepare user data
        user_data = {
            'fullName': full_name,
            'username': username,
            'email': email,
            'dateOfBirth': date_of_birth,
            'role': role,
            'region': region,
            'hasFamilyHistory': has_family_history,
            'familyHistoryType': family_history_type if has_family_history == 'Yes' else None,
            'familyRelation': family_relation if has_family_history == 'Yes' else None,
            'password_hash': password_hash,
            'createdAt': firestore.SERVER_TIMESTAMP
        }

        # Save user to Firestore
        user_ref = users_ref.add(user_data)[1]
        user_uid = user_ref.id

        logger.info(f'Registered new user with uid: {user_uid}')
        return jsonify({'status': 'success', 'user_uid': user_uid, 'message': 'Account created successfully! Please login.'}), 201
    except Exception as e:
        logger.error(f'Unexpected error in /register: {str(e)}', exc_info=True)
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

    
@app.route('/patient', methods=['GET'])
@token_required
def get_patient_data(user_uid):
    try:
        cervical_records = db.collection("patient_history").document(user_uid).collection("cervical").get()
        ovarian_records = db.collection("patient_history").document(user_uid).collection("ovarian").get()

        cervical_dict = []
        if cervical_records:
            for r in cervical_records:
                data = r.to_dict()
                for key, encoder in [
                    ('hpv_result', encoders['le_hpv']),
                    ('pap_smear_result', encoders['le_pap']),
                    ('smoking_status', encoders['le_smoking']),
                    ('stds_history', encoders['le_std']),
                    ('insurance_covered', encoders['le_insurance']),
                    ('screening_type_last', encoders['le_screening']),
                    ('recommended_action', encoders['le_action'])
                ]:
                    if key in data and data[key] is not None:
                        try:
                            if isinstance(data[key], str) and data[key] in encoder.classes_:
                                continue
                            data[key] = encoder.inverse_transform([int(data[key])])[0]
                        except (ValueError, IndexError, AttributeError) as e:
                            logger.error(f"Error decoding {key} for user {user_uid}: {e}")
                            data[key] = str(data[key])
                cervical_dict.append(data)

        ovarian_dict = []
        if ovarian_records:
            for r in ovarian_records:
                data = r.to_dict()
                for key, encoder in [
                    ('menopause_status', encoders['le_menopause']),
                    ('ultrasound_features', encoders['le_ultrasound']),
                    ('recommended_management', encoders['le_management'])
                ]:
                    if key in data and data[key] is not None:
                        try:
                            if isinstance(data[key], str) and data[key] in encoder.classes_:
                                continue
                            data[key] = encoder.inverse_transform([int(data[key])])[0]
                        except (ValueError, IndexError, AttributeError) as e:
                            logger.error(f"Error decoding {key} for user {user_uid}: {e}")
                            data[key] = str(data[key])
                ovarian_dict.append(data)

        if not cervical_dict and not ovarian_dict:
            logger.warning(f"No patient data found for user_uid: {user_uid}")
            return jsonify({'cervical': [], 'ovarian': [], 'message': 'No patient history data available'}), 404

        return jsonify({'cervical': cervical_dict, 'ovarian': ovarian_dict})
    except Exception as e:
        logger.error(f'Error in /patient for user {user_uid}: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

def override_cervical_recommendation(hpv, pap_smear, age):
    try:
        if hpv == "Negative" and pap_smear == "Negative":
            return encoders['le_action'].transform(["Repeat Pap Smear In 3 Years"])[0]
        elif hpv == "Positive" and pap_smear == "Positive":
            return encoders['le_action'].transform(["Colposcopy, Biopsy, Cytology"])[0]
        elif age < 25 and hpv == "Positive":
            return encoders['le_action'].transform(["Hpv Vaccine And Sexual Education"])[0]
        return None
    except ValueError as e:
        logger.error(f"Error in override_cervical_recommendation: {e}")
        return None

@app.route('/cervical_recommendation', methods=['POST'])
@token_required
def cervical_recommendation(user_uid):
    try:
        data = request.json
        view = request.args.get('view', 'patient')
        # Validate and use the user's region from Firebase
        region = validate_region(user_uid)
        # Check for required fields with defaults
        required_fields = {
            'age': int,
            'sexual_partners': int,
            'first_sexual_activity_age': int,
            'hpv_result': str,
            'pap_smear_result': str,
            'smoking_status': str,
            'stds_history': str,
            'screening_type_last': str
        }
        for field, type_cast in required_fields.items():
            if field not in data:
                raise ValueError(f"Missing required field: {field}")
            try:
                data[field] = type_cast(data[field])
            except (ValueError, TypeError):
                raise ValueError(f"Invalid type for {field}: {data[field]}")

        input_data = {
            'age': data['age'],
            'sexual_partners': data['sexual_partners'],
            'first_sexual_activity_age': data['first_sexual_activity_age'],
            'hpv_result': normalize_hpv_result(data['hpv_result']),
            'pap_smear_result': normalize_pap_result(data['pap_smear_result']),
            'smoking_status': normalize_yes_no(data['smoking_status']),
            'stds_history': normalize_yes_no(data['stds_history']),
            'screening_type_last': normalize_screening_type(data['screening_type_last']),
            'region': region,
            'date': data.get('date', datetime.now().strftime("%Y-%m-%d")),
            'treatment_response': data.get('treatment_response', 'N/A')
        }

        for field, encoder in [
            ('hpv_result', encoders['le_hpv']),
            ('pap_smear_result', encoders['le_pap']),
            ('smoking_status', encoders['le_smoking']),
            ('stds_history', encoders['le_std']),
            ('screening_type_last', encoders['le_screening'])
        ]:
            if input_data[field] not in encoder.classes_:
                return jsonify({
                    'status': 'error',
                    'message': f"Invalid {field}: {input_data[field]}. Must be one of {list(encoder.classes_)}"
                }), 400

        patient_data = pd.DataFrame([{
            'Age': input_data['age'],
            'Sexual Partners': input_data['sexual_partners'],
            'First Sexual Activity Age': input_data['first_sexual_activity_age'],
            'HPV Test Result': encoders['le_hpv'].transform([input_data['hpv_result']])[0],
            'Pap Smear Result': encoders['le_pap'].transform([input_data['pap_smear_result']])[0],
            'Smoking Status': encoders['le_smoking'].transform([input_data['smoking_status']])[0],
            'STDs History': encoders['le_std'].transform([input_data['stds_history']])[0],
            'Screening Type Last': encoders['le_screening'].transform([input_data['screening_type_last']])[0]
        }])

        override = override_cervical_recommendation(input_data['hpv_result'], input_data['pap_smear_result'], input_data['age'])
        prediction_action = override if override is not None else cervical_model.predict(patient_data)[0]
        recommended_action = encoders['le_action'].inverse_transform([prediction_action])[0]
        insurance_prediction = insurance_model.predict(patient_data)[0]
        insurance_covered = encoders['le_insurance'].inverse_transform([insurance_prediction])[0]
        validation = validate_recommendation_guidelines(user_uid, input_data, recommended_action)
        percentile_risk = calculate_percentile_risk(user_uid, input_data, "cervical")
        education_content = get_education_content(user_uid, input_data, recommended_action)
        clinical_alerts = generate_clinical_alerts(user_uid, input_data, "cervical")
        care_plan = generate_automated_care_plan(user_uid, recommended_action, input_data, "cervical")
        advanced_education = generate_advanced_education(user_uid, input_data, recommended_action, "cervical")

        db.collection("patient_history").document(user_uid).collection("cervical").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            **input_data,
            "recommended_action": recommended_action,
            "insurance_covered": insurance_covered
        })

        response = {
            'patient_data' if view.lower() == 'doctor' else 'your_info': input_data,
            'recommended_action' if view.lower() == 'doctor' else 'next_steps': recommended_action,
            'insurance_covered': insurance_covered,  # Added as response field
            'screening_type_last': input_data['screening_type_last'],
            'validation': validation,
            'percentile_risk': percentile_risk,
            'education_content': education_content,
            'clinical_alerts': clinical_alerts,
            'care_plan': care_plan,
            'advanced_education': advanced_education
        }
        return jsonify(response)
    except ValueError as e:
        logger.error(f'Error in /cervical_recommendation for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': f'Invalid input: {str(e)}'}), 400
    except Exception as e:
        logger.error(f'Error in /cervical_recommendation for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500
    
@app.route('/ovarian_recommendation', methods=['POST'])
@token_required
def ovarian_recommendation(user_uid):
    try:
        data = request.json
        view = request.args.get('view', 'patient')
        symptom_values = [1 if s.lower() in [x.lower() for x in data.get('symptoms', [])] else 0 for s in symptoms]
        # Validate and use the user's region from Firebase
        region = validate_region(user_uid)
        input_data = {
            'age': int(data['age']),
            'menopause_status': data['menopause_status'].title(),
            'cyst_size': float(data['cyst_size']),
            'cyst_growth_rate': float(data.get('cyst_growth_rate', ovarian_data['Cyst Growth Rate cm/month'].median())),
            'ca125_level': float(data['ca125_level']),
            'symptoms': data.get('symptoms', []),
            'region': region,
            'ultrasound_features': data.get('ultrasound_features', '').title().strip(),
            'date': data.get('date', datetime.now().strftime("%Y-%m-%d")),
            'treatment_response': data.get('treatment_response', 'N/A')
        }

        if input_data['menopause_status'] not in encoders['le_menopause'].classes_:
            input_data['menopause_status'] = 'Pre-Menopausal' if input_data['age'] < 40 else 'Post-Menopausal'

        ultrasound_val = None
        if input_data['ultrasound_features']:
            if input_data['ultrasound_features'] in encoders['le_ultrasound'].classes_:
                ultrasound_val = encoders['le_ultrasound'].transform([input_data['ultrasound_features']])[0]
            else:
                return jsonify({
                    'status': 'error',
                    'message': f"Invalid ultrasound_features: {input_data['ultrasound_features']}. Must be one of {list(encoders['le_ultrasound'].classes_)}"
                }), 400

        patient_data = pd.DataFrame([{
            'Age': input_data['age'],
            'Menopause Status': encoders['le_menopause'].transform([input_data['menopause_status']])[0],
            'Cyst Size cm': input_data['cyst_size'],
            'Cyst Growth Rate cm/month': input_data['cyst_growth_rate'],
            'CA 125 Level': input_data['ca125_level'],
            'Pelvic Pain': symptom_values[0],
            'Bloating': symptom_values[1],
            'Nausea': symptom_values[2],
            'Fatigue': symptom_values[3],
            'Irregular Periods': symptom_values[4]
        }])

        if ultrasound_val is None:
            ultrasound_prediction = ultrasound_model.predict(patient_data)[0]
            ultrasound_features = encoders['le_ultrasound'].inverse_transform([ultrasound_prediction])[0]
        else:
            ultrasound_features = input_data['ultrasound_features']

        management_prediction = management_model.predict(patient_data)[0]
        recommended_management = encoders['le_management'].inverse_transform([management_prediction])[0]
        percentile_risk = calculate_percentile_risk(user_uid, input_data, "ovarian")
        education_content = get_education_content(user_uid, input_data, recommended_management)
        clinical_alerts = generate_clinical_alerts(user_uid, input_data, "ovarian")
        care_plan = generate_automated_care_plan(user_uid, recommended_management, input_data, "ovarian")
        advanced_education = generate_advanced_education(user_uid, input_data, recommended_management, "ovarian")

        db.collection("patient_history").document(user_uid).collection("ovarian").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            **input_data,
            "recommended_management": recommended_management,
            "ultrasound_features": ultrasound_features
        })

        response = {
            'patient_data' if view.lower() == 'doctor' else 'your_info': input_data,
            'ultrasound_features': ultrasound_features,
            'recommended_management' if view.lower() == 'doctor' else 'next_steps': recommended_management,
            'percentile_risk': percentile_risk,
            'education_content': education_content,
            'clinical_alerts': clinical_alerts,
            'care_plan': care_plan,
            'advanced_education': advanced_education
        }
        return jsonify(response)
    except ValueError as e:
        logger.error(f'Error in /ovarian_recommendation for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': f'Invalid input: {str(e)}'}), 400
    except Exception as e:
        logger.error(f'Error in /ovarian_recommendation for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

@app.route('/patient_history', methods=['GET'])
@token_required
def get_patient_history(user_uid):
    try:
        history = generate_patient_history_timeline(user_uid)
        return jsonify(history)
    except Exception as e:
        logger.error(f'Error in /patient_history: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/specialists/<region>', methods=['GET'])
def get_specialists(region):
    try:
        specialists = get_specialist_contacts(region)
        return jsonify({'specialists': specialists})
    except Exception as e:
        logger.error(f'Error in /specialists/{region}: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/population_health', methods=['GET'])
def get_population_health():
    try:
        region = request.args.get('region', '').title().strip()
        insights = track_population_health(region)
        return jsonify(insights)
    except Exception as e:
        logger.error(f'Error in /population_health: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/anonymized_data', methods=['GET'])
def get_anonymized_data():
    try:
        data = aggregate_anonymized_data()
        return jsonify(data)
    except Exception as e:
        logger.error(f'Error in /anonymized_data: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/generate_pdf/<user_uid>', methods=['POST'])
@token_required
def generate_pdf(user_uid):
    try:
        data = request.json
        patient_data = data['patient_data']
        recommendation = data['recommendation']
        filename = generate_pdf_report(user_uid, patient_data, recommendation)
        if filename:
            return jsonify({'status': 'success', 'filename': filename})
        return jsonify({'status': 'error', 'message': 'Failed to generate PDF'})
    except Exception as e:
        logger.error(f'Error in /generate_pdf/{user_uid}: {e}')
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})










@app.route('/cervical_risk_assessment', methods=['POST'])
@token_required
def cervical_risk_assessment(user_uid):
    try:
        data = request.json
        view = request.args.get('view', 'patient')
        region = validate_region(user_uid)

        # Define required fields with explicit nested structure
        required_patient_info = {
            'patient_info.age': int,
            'patient_info.sexual_partners': int,
            'patient_info.age_first_sex': int,
            'patient_info.smoking': str,
            'patient_info.menopause_status': str
        }
        required_medical_history = {
            'medical_history.family_cancer_history': str,
            'medical_history.previous_stds': str,
            'medical_history.hiv_status': str,
            'medical_history.taking_immune_drugs': str,
            'medical_history.had_pap_test': str,
            'medical_history.had_hpv_test': str,
            'medical_history.last_screening': str
        }
        
        # Add lifestyle fields
        required_lifestyle = {
            'lifestyle.exercise_frequency': str,
            'lifestyle.diet_quality': str,
            'lifestyle.alcohol_consumption': str,
            'lifestyle.stress_level': str,
            'lifestyle.sleep_quality': str,
            'lifestyle.contraceptive_use': str,
            'lifestyle.hpv_vaccination': str
        }
        
        required_fields = {**required_patient_info, **required_medical_history, **required_lifestyle}

        # Validate all required fields
        for field_path, type_cast in required_fields.items():
            parts = field_path.split('.')
            value = data
            for part in parts:
                value = value.get(part)
                if value is None:
                    raise ValueError(f"Missing required field: {field_path}")
            try:
                if value is not None:
                    value = type_cast(value)
            except (ValueError, TypeError):
                raise ValueError(f"Invalid type for {field_path}: {value}")

        # Calculate risk using clinical factors and symptoms
        risk_score = calculate_cervical_risk_score(data)
        risk_level = determine_risk_level(risk_score)
        
        # Calculate insurance coverage based on risk factors
        insurance_covered = calculate_insurance_coverage(data, risk_level)

        # Prepare comprehensive storage data
        storage_data = {
            'age': data['patient_info']['age'],
            'sexual_partners': data['patient_info']['sexual_partners'],
            'age_first_sex': data['patient_info']['age_first_sex'],
            'smoking': normalize_yes_no(data['patient_info']['smoking']),
            'menopause_status': normalize_yes_no(data['patient_info']['menopause_status']),
            'family_cancer_history': normalize_yes_no(data['medical_history']['family_cancer_history']),
            'previous_stds': normalize_yes_no(data['medical_history']['previous_stds']),
            'hiv_status': normalize_yes_no(data['medical_history']['hiv_status']),
            'taking_immune_drugs': normalize_yes_no(data['medical_history']['taking_immune_drugs']),
            'had_pap_test': normalize_yes_no(data['medical_history']['had_pap_test']),
            'had_hpv_test': normalize_yes_no(data['medical_history']['had_hpv_test']),
            'last_screening': data['medical_history']['last_screening'],
            
            # Lifestyle factors
            'exercise_frequency': data['lifestyle']['exercise_frequency'],
            'diet_quality': data['lifestyle']['diet_quality'],
            'alcohol_consumption': data['lifestyle']['alcohol_consumption'],
            'stress_level': data['lifestyle']['stress_level'],
            'sleep_quality': data['lifestyle']['sleep_quality'],
            'contraceptive_use': data['lifestyle']['contraceptive_use'],
            'hpv_vaccination': normalize_yes_no(data['lifestyle']['hpv_vaccination']),
            
            # Symptoms
            'bleeding_between_periods': normalize_yes_no(data.get('bleeding_symptoms', {}).get('bleeding_between_periods', 'No')),
            'bleeding_after_sex': normalize_yes_no(data.get('bleeding_symptoms', {}).get('bleeding_after_sex', 'No')),
            'bleeding_after_menopause': normalize_yes_no(data.get('bleeding_symptoms', {}).get('bleeding_after_menopause', 'No')),
            'periods_heavier_than_before': normalize_yes_no(data.get('bleeding_symptoms', {}).get('periods_heavier_than_before', 'No')),
            'periods_longer_than_before': normalize_yes_no(data.get('bleeding_symptoms', {}).get('periods_longer_than_before', 'No')),
            'unusual_discharge': normalize_yes_no(data.get('other_symptoms', {}).get('unusual_discharge', 'No')),
            'discharge_smells_bad': normalize_yes_no(data.get('other_symptoms', {}).get('discharge_smells_bad', 'No')),
            'discharge_color_change': normalize_yes_no(data.get('other_symptoms', {}).get('discharge_color_change', 'No')),
            'pain_during_sex': normalize_yes_no(data.get('other_symptoms', {}).get('pain_during_sex', 'No')),
            'pelvic_pain': normalize_yes_no(data.get('other_symptoms', {}).get('pelvic_pain', 'No')),
            'painful_urination': normalize_yes_no(data.get('other_symptoms', {}).get('painful_urination', 'No')),
            'blood_in_urine': normalize_yes_no(data.get('other_symptoms', {}).get('blood_in_urine', 'No')),
            'frequent_urination': normalize_yes_no(data.get('other_symptoms', {}).get('frequent_urination', 'No')),
            'rectal_bleeding': normalize_yes_no(data.get('other_symptoms', {}).get('rectal_bleeding', 'No')),
            'painful_bowel_movements': normalize_yes_no(data.get('other_symptoms', {}).get('painful_bowel_movements', 'No')),
            'unexplained_weight_loss': normalize_yes_no(data.get('general_symptoms', {}).get('unexplained_weight_loss', 'No')),
            'constant_tiredness': normalize_yes_no(data.get('general_symptoms', {}).get('constant_tiredness', 'No')),
            'leg_swelling': normalize_yes_no(data.get('general_symptoms', {}).get('leg_swelling', 'No')),
            'back_pain': normalize_yes_no(data.get('general_symptoms', {}).get('back_pain', 'No')),
            'risk_score': risk_score
        }

        # Additional calculations using storage_data format
        percentile_risk = calculate_percentile_risk(user_uid, storage_data, "cervical")
        education_content = get_education_content(user_uid, storage_data, risk_level)
        care_plan = generate_automated_care_plan(user_uid, risk_level, storage_data, "cervical")

        # Store in database
        db.collection("patient_history").document(user_uid).collection("cervical_risk").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            **storage_data,
            "risk_level": risk_level,
            "insurance_covered": insurance_covered
        })

        response = {
            'patient_data' if view.lower() == 'doctor' else 'your_info': storage_data,
            'risk_level' if view.lower() == 'doctor' else 'your_risk': risk_level,
            'insurance_covered': insurance_covered,
            'percentile_risk': percentile_risk,
            'education_content': education_content,
            'care_plan': care_plan
        }
        return jsonify(response)
        
    except ValueError as e:
        logger.error(f'Validation error in /cervical_risk_assessment for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': f'Invalid input: {str(e)}'}), 400
    except Exception as e:
        logger.error(f'Error in /cervical_risk_assessment for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': 'Internal server error', 'details': str(e)}), 500


def calculate_cervical_risk_score(data):
    """
    Calculate cervical cancer risk score based on clinical factors, lifestyle, and symptoms.
    """
    risk_score = 0
    
    # Age-based risk (cervical cancer peaks in 30s-40s)
    age = data['patient_info']['age']
    if 25 <= age <= 29:
        risk_score += 12
    elif 30 <= age <= 39:
        risk_score += 20
    elif 40 <= age <= 49:
        risk_score += 18
    elif 50 <= age <= 59:
        risk_score += 12
    elif age >= 60:
        risk_score += 8
    
    # Sexual activity risk factors
    sexual_partners = data['patient_info']['sexual_partners']
    if sexual_partners >= 6:
        risk_score += 18
    elif sexual_partners >= 3:
        risk_score += 12
    elif sexual_partners >= 2:
        risk_score += 8
    
    # Early sexual activity
    age_first_sex = data['patient_info']['age_first_sex']
    if age_first_sex <= 16:
        risk_score += 12
    elif age_first_sex <= 18:
        risk_score += 8
    
    # Smoking (major risk factor)
    if normalize_yes_no(data['patient_info']['smoking']):
        risk_score += 20
    
    # Medical history risk factors
    if normalize_yes_no(data['medical_history']['family_cancer_history']):
        risk_score += 12
    
    if normalize_yes_no(data['medical_history']['previous_stds']):
        risk_score += 15
    
    if normalize_yes_no(data['medical_history']['hiv_status']):
        risk_score += 25
    
    if normalize_yes_no(data['medical_history']['taking_immune_drugs']):
        risk_score += 15
    
    # HPV vaccination (protective factor)
    if normalize_yes_no(data['lifestyle']['hpv_vaccination']):
        risk_score -= 15  # Reduces risk significantly
    
    # Lifestyle factors
    exercise_freq = data['lifestyle']['exercise_frequency'].lower()
    if exercise_freq in ['rarely', 'never']:
        risk_score += 8
    elif exercise_freq == 'regularly':
        risk_score -= 3
    
    diet_quality = data['lifestyle']['diet_quality'].lower()
    if diet_quality == 'poor':
        risk_score += 8
    elif diet_quality == 'excellent':
        risk_score -= 3
    
    alcohol_consumption = data['lifestyle']['alcohol_consumption'].lower()
    if alcohol_consumption in ['heavy', 'excessive']:
        risk_score += 10
    elif alcohol_consumption == 'moderate':
        risk_score += 3
    
    stress_level = data['lifestyle']['stress_level'].lower()
    if stress_level == 'high':
        risk_score += 8
    elif stress_level == 'very high':
        risk_score += 12
    
    sleep_quality = data['lifestyle']['sleep_quality'].lower()
    if sleep_quality == 'poor':
        risk_score += 6
    elif sleep_quality == 'very poor':
        risk_score += 10
    
    # Contraceptive use (long-term oral contraceptives slightly increase risk)
    contraceptive = data['lifestyle']['contraceptive_use'].lower()
    if 'oral' in contraceptive and 'long-term' in contraceptive:
        risk_score += 5
    
    # Lack of screening (major risk factor)
    last_screening = data['medical_history']['last_screening'].lower()
    if last_screening == 'never':
        risk_score += 20
    elif 'year' in last_screening:
        try:
            years_ago = int(last_screening.split()[0])
            if years_ago >= 5:
                risk_score += 15
            elif years_ago >= 3:
                risk_score += 10
        except:
            risk_score += 8
    
    # Symptom-based risk assessment
    symptom_score = 0
    
    # Bleeding symptoms (high concern)
    bleeding_symptoms = data.get('bleeding_symptoms', {})
    if normalize_yes_no(bleeding_symptoms.get('bleeding_between_periods', 'No')):
        symptom_score += 15
    if normalize_yes_no(bleeding_symptoms.get('bleeding_after_sex', 'No')):
        symptom_score += 20
    if normalize_yes_no(bleeding_symptoms.get('bleeding_after_menopause', 'No')):
        symptom_score += 25
    if normalize_yes_no(bleeding_symptoms.get('periods_heavier_than_before', 'No')):
        symptom_score += 12
    if normalize_yes_no(bleeding_symptoms.get('periods_longer_than_before', 'No')):
        symptom_score += 12
    
    # Discharge symptoms
    other_symptoms = data.get('other_symptoms', {})
    if normalize_yes_no(other_symptoms.get('unusual_discharge', 'No')):
        symptom_score += 12
    if normalize_yes_no(other_symptoms.get('discharge_smells_bad', 'No')):
        symptom_score += 15
    if normalize_yes_no(other_symptoms.get('discharge_color_change', 'No')):
        symptom_score += 12
    
    # Pain symptoms
    if normalize_yes_no(other_symptoms.get('pain_during_sex', 'No')):
        symptom_score += 15
    if normalize_yes_no(other_symptoms.get('pelvic_pain', 'No')):
        symptom_score += 18
    
    # Urinary symptoms
    if normalize_yes_no(other_symptoms.get('painful_urination', 'No')):
        symptom_score += 10
    if normalize_yes_no(other_symptoms.get('blood_in_urine', 'No')):
        symptom_score += 15
    if normalize_yes_no(other_symptoms.get('frequent_urination', 'No')):
        symptom_score += 8
    
    # Bowel symptoms
    if normalize_yes_no(other_symptoms.get('rectal_bleeding', 'No')):
        symptom_score += 20
    if normalize_yes_no(other_symptoms.get('painful_bowel_movements', 'No')):
        symptom_score += 15
    
    # General symptoms
    general_symptoms = data.get('general_symptoms', {})
    if normalize_yes_no(general_symptoms.get('unexplained_weight_loss', 'No')):
        symptom_score += 20
    if normalize_yes_no(general_symptoms.get('constant_tiredness', 'No')):
        symptom_score += 8
    if normalize_yes_no(general_symptoms.get('leg_swelling', 'No')):
        symptom_score += 15
    if normalize_yes_no(general_symptoms.get('back_pain', 'No')):
        symptom_score += 12
    
    # Add symptom score to risk score
    risk_score += symptom_score
    
    # Ensure risk score is reasonable (not negative, capped at 100)
    risk_score = max(0, min(risk_score, 100))
    
    logger.info(f"Cervical cancer risk calculation: base_risk={risk_score-symptom_score}, symptom_score={symptom_score}, total={risk_score}")
    
    return risk_score


def determine_risk_level(risk_score):
    """Convert risk score to risk level with more reasonable thresholds"""
    if risk_score >= 60:
        return "High"
    elif risk_score >= 35:
        return "Moderate"
    else:
        return "Low"


def calculate_insurance_coverage(data, risk_level):
    """Calculate insurance coverage likelihood based on risk factors"""
    
    # Base coverage probability
    coverage_score = 60
    
    # Age factor (insurance more likely to cover screening for certain ages)
    age = data['patient_info']['age']
    if 21 <= age <= 65:
        coverage_score += 25
    elif age > 65:
        coverage_score += 15
    
    # Risk level factor
    if risk_level == "High":
        coverage_score += 25
    elif risk_level == "Moderate":
        coverage_score += 15
    
    # Symptoms present
    has_symptoms = any([
        normalize_yes_no(data.get('bleeding_symptoms', {}).get('bleeding_between_periods', 'No')),
        normalize_yes_no(data.get('bleeding_symptoms', {}).get('bleeding_after_sex', 'No')),
        normalize_yes_no(data.get('other_symptoms', {}).get('unusual_discharge', 'No')),
        normalize_yes_no(data.get('other_symptoms', {}).get('pelvic_pain', 'No'))
    ])
    
    if has_symptoms:
        coverage_score += 20
    
    # Never been screened
    if data['medical_history']['last_screening'].lower() == 'never':
        coverage_score += 15
    
    # High-risk factors
    if normalize_yes_no(data['medical_history']['family_cancer_history']):
        coverage_score += 10
    
    if normalize_yes_no(data['medical_history']['previous_stds']):
        coverage_score += 10
    
    return "Yes" if coverage_score >= 75 else "Possibly"


# Helper function - modified to return Yes/No instead of 0/1
def normalize_yes_no(value):
    """Convert various inputs to Yes/No format"""
    if value is None:
        return "No"
    value = str(value).strip().lower()
    return "Yes" if value in ['yes', 'y', '1', 'true'] else "No"


def calculate_percentile_risk(user_uid, storage_data, cancer_type):
    """
    Calculate percentile risk for cervical cancer based on population data
    """
    try:
        age = storage_data.get('age', 30)
        risk_score = storage_data.get('risk_score', 0)
        
        # Age-based population risk percentiles (more reasonable)
        age_percentiles = {
            (20, 29): {'Low': 8, 'Moderate': 18, 'High': 35},
            (30, 39): {'Low': 12, 'Moderate': 25, 'High': 45},
            (40, 49): {'Low': 15, 'Moderate': 30, 'High': 50},
            (50, 59): {'Low': 10, 'Moderate': 22, 'High': 40},
            (60, 100): {'Low': 6, 'Moderate': 15, 'High': 30}
        }
        
        # Find age group
        age_group = None
        for (min_age, max_age), percentiles in age_percentiles.items():
            if min_age <= age <= max_age:
                age_group = (min_age, max_age)
                break
        
        if not age_group:
            age_group = (30, 39)  # Default
        
        # Calculate percentile based on risk score
        if risk_score >= 60:
            base_percentile = age_percentiles[age_group]['High']
        elif risk_score >= 35:
            base_percentile = age_percentiles[age_group]['Moderate']
        else:
            base_percentile = age_percentiles[age_group]['Low']
        
        # Adjust for specific risk factors
        adjustment = 0
        
        # Smoking adjustment
        if storage_data.get('smoking') == "Yes":
            adjustment += 8
        
        # Sexual history adjustment
        if storage_data.get('sexual_partners', 0) >= 6:
            adjustment += 6
        elif storage_data.get('sexual_partners', 0) >= 3:
            adjustment += 4
        
        # STD history adjustment
        if storage_data.get('previous_stds') == "Yes":
            adjustment += 6
        
        # HIV status adjustment
        if storage_data.get('hiv_status') == "Yes":
            adjustment += 12
        
        # HPV vaccination (protective)
        if storage_data.get('hpv_vaccination') == "Yes":
            adjustment -= 5
        
        # Lifestyle factors
        if storage_data.get('exercise_frequency', '').lower() in ['rarely', 'never']:
            adjustment += 3
        if storage_data.get('diet_quality', '').lower() == 'poor':
            adjustment += 3
        if storage_data.get('stress_level', '').lower() in ['high', 'very high']:
            adjustment += 3
        
        # Symptom adjustment
        symptom_count = sum([
            1 if storage_data.get('bleeding_between_periods') == "Yes" else 0,
            1 if storage_data.get('bleeding_after_sex') == "Yes" else 0,
            1 if storage_data.get('unusual_discharge') == "Yes" else 0,
            1 if storage_data.get('pelvic_pain') == "Yes" else 0,
            1 if storage_data.get('pain_during_sex') == "Yes" else 0
        ])
        
        if symptom_count >= 3:
            adjustment += 10
        elif symptom_count >= 2:
            adjustment += 6
        elif symptom_count >= 1:
            adjustment += 3
        
        final_percentile = max(5, min(base_percentile + adjustment, 85))
        
        return {
            'percentile': final_percentile,
            'age_group': f"{age_group[0]}-{age_group[1]}",
            'population_context': f"Your risk level is higher than {final_percentile}% of women in your age group",
            'risk_factors_identified': adjustment,
            'interpretation': get_percentile_interpretation(final_percentile)
        }
        
    except Exception as e:
        logger.error(f"Error calculating percentile risk: {e}")
        return {'error': str(e)}


def get_percentile_interpretation(percentile):
    """Provide patient-friendly interpretation of percentile risk"""
    if percentile >= 70:
        return "This indicates a higher risk level that warrants prompt medical attention."
    elif percentile >= 40:
        return "This suggests a moderate risk level that should be discussed with your healthcare provider."
    elif percentile >= 20:
        return "This indicates a lower to moderate risk level. Regular screening is still important."
    else:
        return "This indicates a lower risk level, but preventive care remains important."


def get_education_content(user_uid, storage_data, risk_level):
    """
    Generate educational content without FAQs - focused on practical guidance
    """
    try:
        content = {
            'what_this_means': '',
            'why_it_matters': '',
            'lifestyle_recommendations': [],
            'prevention_tips': []
        }
        
        # Risk level specific content
        if risk_level == "High":
            content['what_this_means'] = "Your assessment indicates several risk factors that suggest you should prioritize cervical health screening. This doesn't mean you have cancer, but it's important to get proper medical evaluation soon."
            content['why_it_matters'] = "Cervical cancer is highly treatable when detected early. Regular screening can catch changes before they become serious problems, and modern treatments are very effective."
            
        elif risk_level == "Moderate":
            content['what_this_means'] = "Your assessment shows some risk factors that suggest you should stay current with cervical health screening. You're in a position where proactive care can make a significant difference."
            content['why_it_matters'] = "Maintaining regular screening helps catch any changes early when they're most treatable. Many risk factors can be managed through lifestyle changes and preventive care."
            
        else:  # Low risk
            content['what_this_means'] = "Your assessment indicates you have relatively fewer risk factors for cervical cancer. This is encouraging, but maintaining good preventive care habits is still important."
            content['why_it_matters'] = "Even with lower risk, regular screening ensures continued health and peace of mind. Prevention is always the best approach to maintaining your health."
        
        # Lifestyle recommendations based on patient data
        lifestyle_recommendations = []
        
        if storage_data.get('smoking') == "Yes":
            lifestyle_recommendations.append("Consider joining a smoking cessation program - this single change can significantly reduce your risk")
        
        if storage_data.get('exercise_frequency', '').lower() in ['rarely', 'never']:
            lifestyle_recommendations.append("Regular exercise (even 30 minutes of walking daily) can boost your immune system and overall health")
        
        if storage_data.get('diet_quality', '').lower() == 'poor':
            lifestyle_recommendations.append("Eating more fruits and vegetables, especially those rich in antioxidants, supports your body's natural defenses")
        
        if storage_data.get('stress_level', '').lower() in ['high', 'very high']:
            lifestyle_recommendations.append("Managing stress through relaxation techniques, exercise, or counseling can improve your overall health")
        
        if storage_data.get('sleep_quality', '').lower() in ['poor', 'very poor']:
            lifestyle_recommendations.append("Improving sleep quality (7-9 hours nightly) helps your immune system function better")
        
        if storage_data.get('hpv_vaccination') == "No" and storage_data.get('age', 30) <= 45:
            lifestyle_recommendations.append("Ask your doctor about HPV vaccination - it can still provide protection even if you've been sexually active")
        
        content['lifestyle_recommendations'] = lifestyle_recommendations
        
        # General prevention tips
        prevention_tips = [
            "Maintain regular gynecological check-ups as recommended by your healthcare provider",
            "Practice safe sex by using condoms and limiting sexual partners",
            "Don't smoke or use tobacco products",
            "Maintain a healthy diet rich in fruits and vegetables",
            "Exercise regularly to support your immune system",
            "Manage stress through healthy coping strategies"
        ]
        
        content['prevention_tips'] = prevention_tips
        
        return content
        
    except Exception as e:
        logger.error(f"Error generating education content: {e}")
        return {
            'what_this_means': 'Your assessment has been completed',
            'why_it_matters': 'Regular screening and healthy lifestyle choices are important for cervical health',
            'lifestyle_recommendations': [],
            'prevention_tips': []
        }


def generate_automated_care_plan(user_uid, risk_level, storage_data, cancer_type):
    """
    Generate automated care plan with practical, patient-friendly recommendations
    """
    try:
        care_plan = {
            'recommended_timeline': '',
            'next_steps': '',
            'lifestyle_actions': [],
            'monitoring_plan': '',
            'resources_needed': []
        }
        
        # Risk level specific care plans
        if risk_level == "High":
            care_plan['recommended_timeline'] = 'Within 2-4 weeks'
            care_plan['next_steps'] = 'Schedule an appointment with a gynecologist for comprehensive screening including HPV testing and Pap smear. If you have symptoms, mention them specifically during your appointment.'
            care_plan['monitoring_plan'] = 'Follow your doctor\'s recommendations for follow-up screening, which may be more frequent than standard guidelines.'
            care_plan['resources_needed'] = ['Gynecologist appointment', 'HPV/Pap smear testing', 'Possible additional testing if symptoms present']
            
        elif risk_level == "Moderate":
            care_plan['recommended_timeline'] = 'Within 1-3 months'
            care_plan['next_steps'] = 'Schedule a routine gynecological exam to discuss your risk factors and establish an appropriate screening schedule. This is a good time to address any concerns you may have.'
            care_plan['monitoring_plan'] = 'Follow standard screening guidelines, but discuss with your doctor if more frequent screening might be beneficial.'
            care_plan['resources_needed'] = ['Gynecologist appointment', 'Routine screening tests', 'Lifestyle counseling if needed']
            
        else:  # Low risk
            care_plan['recommended_timeline'] = 'Within 6-12 months (or as scheduled)'
            care_plan['next_steps'] = 'Continue with your regular screening schedule. Use this time to maintain healthy lifestyle habits and stay informed about cervical health.'
            care_plan['monitoring_plan'] = 'Follow standard screening guidelines for your age group. Continue regular check-ups as recommended.'
            care_plan['resources_needed'] = ['Routine screening as scheduled', 'Preventive care maintenance']
        
        # Lifestyle actions based on specific risk factors
        lifestyle_actions = []
        
        if storage_data.get('smoking') == "Yes":
            lifestyle_actions.append('Quit smoking - this is the single most important change you can make for your health')
        
        if storage_data.get('exercise_frequency', '').lower() in ['rarely', 'never']:
            lifestyle_actions.append('Start with 15-30 minutes of physical activity daily, such as walking or swimming')
        
        if storage_data.get('diet_quality', '').lower() == 'poor':
            lifestyle_actions.append('Improve your diet by adding more fruits, vegetables, and whole grains')
        
        if storage_data.get('stress_level', '').lower() in ['high', 'very high']:
            lifestyle_actions.append('Practice stress management techniques like meditation, yoga, or regular exercise')
        
        if storage_data.get('hpv_vaccination') == "No":
            lifestyle_actions.append('Discuss HPV vaccination with your healthcare provider')
        
        if storage_data.get('last_screening', '').lower() == 'never':
            lifestyle_actions.append('Learn about what to expect during screening to reduce anxiety about the process')
        
        care_plan['lifestyle_actions'] = lifestyle_actions
        
        # Add symptom-specific recommendations
        if any([storage_data.get('bleeding_between_periods') == "Yes", 
                storage_data.get('bleeding_after_sex') == "Yes",
                storage_data.get('pelvic_pain') == "Yes"]):
            care_plan['next_steps'] += ' Be sure to discuss your symptoms in detail with your healthcare provider.'
            care_plan['monitoring_plan'] += ' Keep track of your symptoms and their patterns to share with your doctor.'
        
        return care_plan
        
    except Exception as e:
        logger.error(f"Error generating care plan: {e}")
        return {
            'recommended_timeline': '3-6 months',
            'next_steps': 'Consult with your healthcare provider for personalized recommendations.',
            'lifestyle_actions': ['Maintain healthy lifestyle habits'],
            'monitoring_plan': 'Follow standard screening guidelines for your age group.',
            'resources_needed': ['Healthcare consultation']}
 

@app.route('/ovarian_cysts_assessment', methods=['POST'])
@token_required
def ovarian_cysts_assessment(user_uid):
    try:
        data = request.json
        region = validate_region(user_uid)

        # Define required fields with explicit nested structure
        required_patient_info = {
            'patient_info.age': int,
            'patient_info.menstrual_cycle_length': int,
            'patient_info.menstrual_irregularity': str,
            'patient_info.pregnancy_history': str,
            'patient_info.menopause_status': str,
            'patient_info.family_history_ovarian': str
        }
        
        required_medical_history = {
            'medical_history.pcos_diagnosis': str,
            'medical_history.endometriosis': str,
            'medical_history.previous_ovarian_cysts': str,
            'medical_history.hormone_therapy': str,
            'medical_history.fertility_treatments': str,
            'medical_history.previous_ovarian_surgery': str,
            'medical_history.last_pelvic_exam': str,
            'medical_history.last_ultrasound': str
        }
        
        required_lifestyle = {
            'lifestyle.exercise_frequency': str,
            'lifestyle.diet_quality': str,
            'lifestyle.stress_level': str,
            'lifestyle.sleep_quality': str,
            'lifestyle.weight_status': str,
            'lifestyle.contraceptive_use': str,
            'lifestyle.smoking_status': str  # Added smoking_status
        }
        
        required_fields = {**required_patient_info, **required_medical_history, **required_lifestyle}

        # Validate all required fields
        for field_path, type_cast in required_fields.items():
            parts = field_path.split('.')
            value = data
            for part in parts:
                value = value.get(part)
                if value is None:
                    raise ValueError(f"Missing required field: {field_path}")
            try:
                if value is not None:
                    value = type_cast(value)
            except (ValueError, TypeError):
                raise ValueError(f"Invalid type for {field_path}: {value}")

        # Calculate risk using clinical factors and symptoms
        risk_score = calculate_ovarian_cysts_risk_score(data)
        risk_level = determine_ovarian_cysts_risk_level(risk_score)
        
        # Calculate insurance coverage based on risk factors
        insurance_covered = calculate_ovarian_cysts_insurance_coverage(data, risk_level)

        # Prepare comprehensive storage data
        storage_data = {
            'age': data['patient_info']['age'],
            'menstrual_cycle_length': data['patient_info']['menstrual_cycle_length'],
            'menstrual_irregularity': normalize_yes_no(data['patient_info']['menstrual_irregularity']),
            'pregnancy_history': normalize_yes_no(data['patient_info']['pregnancy_history']),
            'menopause_status': normalize_yes_no(data['patient_info']['menopause_status']),
            'family_history_ovarian': normalize_yes_no(data['patient_info']['family_history_ovarian']),
            'pcos_diagnosis': normalize_yes_no(data['medical_history']['pcos_diagnosis']),
            'endometriosis': normalize_yes_no(data['medical_history']['endometriosis']),
            'previous_ovarian_cysts': normalize_yes_no(data['medical_history']['previous_ovarian_cysts']),
            'hormone_therapy': normalize_yes_no(data['medical_history']['hormone_therapy']),
            'fertility_treatments': normalize_yes_no(data['medical_history']['fertility_treatments']),
            'previous_ovarian_surgery': normalize_yes_no(data['medical_history']['previous_ovarian_surgery']),
            'last_pelvic_exam': data['medical_history']['last_pelvic_exam'],
            'last_ultrasound': data['medical_history']['last_ultrasound'],
            'exercise_frequency': data['lifestyle']['exercise_frequency'],
            'diet_quality': data['lifestyle']['diet_quality'],
            'stress_level': data['lifestyle']['stress_level'],
            'sleep_quality': data['lifestyle']['sleep_quality'],
            'weight_status': data['lifestyle']['weight_status'],
            'contraceptive_use': data['lifestyle']['contraceptive_use'],
            'smoking_status': normalize_yes_no(data['lifestyle']['smoking_status']),
            'pelvic_pain': normalize_yes_no(data.get('pelvic_symptoms', {}).get('pelvic_pain', 'No')),
            'abdominal_bloating': normalize_yes_no(data.get('pelvic_symptoms', {}).get('abdominal_bloating', 'No')),
            'feeling_full_quickly': normalize_yes_no(data.get('pelvic_symptoms', {}).get('feeling_full_quickly', 'No')),
            'frequent_urination': normalize_yes_no(data.get('pelvic_symptoms', {}).get('frequent_urination', 'No')),
            'difficulty_emptying_bladder': normalize_yes_no(data.get('pelvic_symptoms', {}).get('difficulty_emptying_bladder', 'No')),
            'pain_during_sex': normalize_yes_no(data.get('pelvic_symptoms', {}).get('pain_during_sex', 'No')),
            'irregular_periods': normalize_yes_no(data.get('menstrual_symptoms', {}).get('irregular_periods', 'No')),
            'heavy_periods': normalize_yes_no(data.get('menstrual_symptoms', {}).get('heavy_periods', 'No')),
            'painful_periods': normalize_yes_no(data.get('menstrual_symptoms', {}).get('painful_periods', 'No')),
            'spotting_between_periods': normalize_yes_no(data.get('menstrual_symptoms', {}).get('spotting_between_periods', 'No')),
            'missed_periods': normalize_yes_no(data.get('menstrual_symptoms', {}).get('missed_periods', 'No')),
            'breast_tenderness': normalize_yes_no(data.get('hormonal_symptoms', {}).get('breast_tenderness', 'No')),
            'mood_changes': normalize_yes_no(data.get('hormonal_symptoms', {}).get('mood_changes', 'No')),
            'weight_gain': normalize_yes_no(data.get('hormonal_symptoms', {}).get('weight_gain', 'No')),
            'acne_changes': normalize_yes_no(data.get('hormonal_symptoms', {}).get('acne_changes', 'No')),
            'hair_growth_changes': normalize_yes_no(data.get('hormonal_symptoms', {}).get('hair_growth_changes', 'No')),
            'nausea_vomiting': normalize_yes_no(data.get('general_symptoms', {}).get('nausea_vomiting', 'No')),
            'back_pain': normalize_yes_no(data.get('general_symptoms', {}).get('back_pain', 'No')),
            'leg_pain': normalize_yes_no(data.get('general_symptoms', {}).get('leg_pain', 'No')),
            'fatigue': normalize_yes_no(data.get('general_symptoms', {}).get('fatigue', 'No')),
            'risk_score': risk_score
        }

        # Additional calculations using storage_data format
        percentile_risk = calculate_percentile_risk(user_uid, storage_data, "ovarian_cysts")
        education_content = get_ovarian_cysts_education_content(user_uid, storage_data, risk_level)
        care_plan = generate_ovarian_cysts_care_plan(user_uid, risk_level, storage_data, "ovarian_cysts")

        # Store in database
        db.collection("patient_history").document(user_uid).collection("ovarian_cysts_risk").add({
            "timestamp": firestore.SERVER_TIMESTAMP,
            **storage_data,
            "risk_level": risk_level,
            "insurance_covered": insurance_covered
        })

        response = {
            'patient_data': storage_data,
            'risk_level': risk_level,
            'insurance_covered': insurance_covered,
            'percentile_risk': percentile_risk,
            'education_content': education_content,
            'care_plan': care_plan
        }
        return jsonify(response)
        
    except ValueError as e:
        logger.error(f'Validation error in /ovarian_cysts_assessment for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': f'Invalid input: {str(e)}'}), 400
    except Exception as e:
        logger.error(f'Error in /ovarian_cysts_assessment for user {user_uid}: {e}')
        return jsonify({'status': 'error', 'message': 'Internal server error', 'details': str(e)}), 500

def calculate_ovarian_cysts_risk_score(data):
    """
    Calculate ovarian cysts risk score based on clinical, lifestyle, and symptom factors.
    Uses weight_status to align with endpoint validation, includes smoking status and PCOS-symptom interactions,
    with adjusted symptom weights for moderate risk differentiation.
    """
    risk_score = 0
    symptom_score = 0
    
    # Age-based risk (ovarian cysts more common in reproductive years)
    age = data['patient_info']['age']
    if 20 <= age <= 35:
        risk_score += 15
    elif 36 <= age <= 45:
        risk_score += 12
    elif 46 <= age <= 55:
        risk_score += 8
    elif age > 55:
        risk_score += 5
    
    # Menstrual cycle factors
    cycle_length = data['patient_info']['menstrual_cycle_length']
    if cycle_length > 35 or cycle_length < 21:
        risk_score += 12
    
    if normalize_yes_no(data['patient_info']['menstrual_irregularity']):
        risk_score += 5  # Reduced for moderate risk
    
    # Pregnancy history (nulliparity increases risk)
    if not normalize_yes_no(data['patient_info']['pregnancy_history']):
        risk_score += 10
    
    # Family history
    if normalize_yes_no(data['patient_info']['family_history_ovarian']):
        risk_score += 12
    
    # Medical history risk factors
    if normalize_yes_no(data['medical_history']['pcos_diagnosis']):
        risk_score += 30  # Strong risk factor
    
    if normalize_yes_no(data['medical_history']['endometriosis']):
        risk_score += 20
    
    if normalize_yes_no(data['medical_history']['previous_ovarian_cysts']):
        risk_score += 25  # High recurrence risk
    
    if normalize_yes_no(data['medical_history']['hormone_therapy']):
        risk_score += 10
    
    if normalize_yes_no(data['medical_history']['fertility_treatments']):
        risk_score += 15
    
    # Smoking history (increases hormonal disruption risk)
    smoking_status = data.get('lifestyle', {}).get('smoking_status', 'No')
    if normalize_yes_no(smoking_status):
        risk_score += 10
    
    # Weight status (aligned with endpoint validation)
    weight_status = data.get('lifestyle', {}).get('weight_status', 'normal').lower()
    if weight_status in ['obese', 'overweight']:
        risk_score += 12
    elif weight_status == 'underweight':
        risk_score += 8
    
    # Lifestyle factors
    exercise_freq = data['lifestyle']['exercise_frequency'].lower()
    if exercise_freq in ['rarely', 'never']:
        risk_score += 8
    elif exercise_freq == 'regularly':
        risk_score -= 3
    
    diet_quality = data['lifestyle']['diet_quality'].lower()
    if diet_quality == 'poor':
        risk_score += 8
    elif diet_quality == 'excellent':
        risk_score -= 3
    
    stress_level = data['lifestyle']['stress_level'].lower()
    if stress_level == 'high':
        risk_score += 10
    elif stress_level == 'very high':
        risk_score += 15
    
    # Contraceptive use (oral contraceptives may reduce risk)
    contraceptive = data['lifestyle']['contraceptive_use'].lower()
    if 'oral' in contraceptive or 'pill' in contraceptive:
        risk_score -= 8
    
    # Lack of recent screening
    last_exam = data['medical_history']['last_pelvic_exam'].lower()
    if last_exam == 'never':
        risk_score += 15
    elif 'year' in last_exam:
        try:
            years_ago = int(last_exam.split()[0])
            if years_ago >= 3:
                risk_score += 10
            elif years_ago >= 2:
                risk_score += 5
        except:
            risk_score += 5
    
    # Symptom-based risk assessment with adjusted weights
    pelvic_symptoms = data.get('pelvic_symptoms', {})
    if normalize_yes_no(pelvic_symptoms.get('pelvic_pain', 'No')):
        symptom_score += 10  # Reduced from 25
    if normalize_yes_no(pelvic_symptoms.get('abdominal_bloating', 'No')):
        symptom_score += 8
    if normalize_yes_no(pelvic_symptoms.get('feeling_full_quickly', 'No')):
        symptom_score += 8
    if normalize_yes_no(pelvic_symptoms.get('frequent_urination', 'No')):
        symptom_score += 8
    if normalize_yes_no(pelvic_symptoms.get('difficulty_emptying_bladder', 'No')):
        symptom_score += 8
    if normalize_yes_no(pelvic_symptoms.get('pain_during_sex', 'No')):
        symptom_score += 8
    
    menstrual_symptoms = data.get('menstrual_symptoms', {})
    if normalize_yes_no(menstrual_symptoms.get('irregular_periods', 'No')):
        symptom_score += 5  # Reduced from 20
    if normalize_yes_no(menstrual_symptoms.get('heavy_periods', 'No')):
        symptom_score += 8
    if normalize_yes_no(menstrual_symptoms.get('painful_periods', 'No')):
        symptom_score += 6
    if normalize_yes_no(menstrual_symptoms.get('spotting_between_periods', 'No')):
        symptom_score += 8
    if normalize_yes_no(menstrual_symptoms.get('missed_periods', 'No')):
        symptom_score += 8
    
    hormonal_symptoms = data.get('hormonal_symptoms', {})
    if normalize_yes_no(hormonal_symptoms.get('breast_tenderness', 'No')):
        symptom_score += 6
    if normalize_yes_no(hormonal_symptoms.get('mood_changes', 'No')):
        symptom_score += 6
    if normalize_yes_no(hormonal_symptoms.get('weight_gain', 'No')):
        symptom_score += 6
    if normalize_yes_no(hormonal_symptoms.get('acne_changes', 'No')):
        symptom_score += 6
    if normalize_yes_no(hormonal_symptoms.get('hair_growth_changes', 'No')):
        symptom_score += 6
    
    general_symptoms = data.get('general_symptoms', {})
    if normalize_yes_no(general_symptoms.get('nausea_vomiting', 'No')):
        symptom_score += 8
    if normalize_yes_no(general_symptoms.get('back_pain', 'No')):
        symptom_score += 6
    if normalize_yes_no(general_symptoms.get('leg_pain', 'No')):
        symptom_score += 6
    if normalize_yes_no(general_symptoms.get('fatigue', 'No')):
        symptom_score += 6
    
    # Interaction term: PCOS + irregular periods or pelvic pain
    if (normalize_yes_no(data['medical_history']['pcos_diagnosis']) and
        (normalize_yes_no(menstrual_symptoms.get('irregular_periods', 'No')) or
         normalize_yes_no(pelvic_symptoms.get('pelvic_pain', 'No')))):
        risk_score += 10  # Synergistic effect
    
    # Add symptom score to risk score
    risk_score += symptom_score
    
    # Ensure risk score is reasonable (not negative, capped at 100)
    risk_score = max(0, min(risk_score, 100))
    
    logger.info(f"Ovarian cysts risk calculation: base_risk={risk_score-symptom_score}, symptom_score={symptom_score}, total={risk_score}")
    
    return risk_score

def determine_ovarian_cysts_risk_level(risk_score):
    """Convert risk score to risk level with adjusted thresholds"""
    if risk_score >= 70:
        return "High"
    elif risk_score >= 40:
        return "Moderate"
    else:
        return "Low"

def calculate_ovarian_cysts_insurance_coverage(data, risk_level):
    """Calculate insurance coverage likelihood based on risk factors"""
    coverage_score = 65
    age = data['patient_info']['age']
    if 20 <= age <= 50:
        coverage_score += 20
    elif age > 50:
        coverage_score += 10
    
    if risk_level == "High":
        coverage_score += 25
    elif risk_level == "Moderate":
        coverage_score += 15
    
    has_symptoms = any([
        normalize_yes_no(data.get('pelvic_symptoms', {}).get('pelvic_pain', 'No')),
        normalize_yes_no(data.get('pelvic_symptoms', {}).get('abdominal_bloating', 'No')),
        normalize_yes_no(data.get('menstrual_symptoms', {}).get('irregular_periods', 'No')),
        normalize_yes_no(data.get('menstrual_symptoms', {}).get('heavy_periods', 'No'))
    ])
    
    if has_symptoms:
        coverage_score += 20
    
    if normalize_yes_no(data['medical_history']['pcos_diagnosis']):
        coverage_score += 15
    
    if normalize_yes_no(data['medical_history']['endometriosis']):
        coverage_score += 15
    
    if normalize_yes_no(data['medical_history']['previous_ovarian_cysts']):
        coverage_score += 15
    
    return "Yes" if coverage_score >= 80 else "Possibly"

def get_ovarian_cysts_education_content(user_uid, storage_data, risk_level):
    """
    Generate educational content for ovarian cysts
    """
    try:
        content = {
            'what_this_means': '',
            'why_it_matters': '',
            'lifestyle_recommendations': [],
            'prevention_tips': []
        }
        
        if risk_level == "High":
            content['what_this_means'] = "Your assessment indicates several risk factors for ovarian cysts. This doesn't mean you definitely have cysts, but it suggests you should have a pelvic examination and possibly an ultrasound to check your ovarian health."
            content['why_it_matters'] = "Most ovarian cysts are benign and resolve on their own, but some may cause complications if left unmonitored. Early detection allows for proper management and prevents potential complications."
            
        elif risk_level == "Moderate":
            content['what_this_means'] = "Your assessment shows some risk factors for ovarian cysts. You should maintain regular gynecological check-ups and be aware of symptoms that might indicate cyst development."
            content['why_it_matters'] = "Regular monitoring helps catch any ovarian changes early. Many cysts are manageable with lifestyle changes and medical monitoring."
            
        else:
            content['what_this_means'] = "Your assessment indicates you have relatively fewer risk factors for ovarian cysts. This is encouraging, but maintaining awareness of your reproductive health is still important."
            content['why_it_matters'] = "Even with lower risk, staying informed about your body and maintaining regular check-ups ensures optimal reproductive health."
        
        lifestyle_recommendations = []
        if storage_data.get('exercise_frequency', '').lower() in ['rarely', 'never']:
            lifestyle_recommendations.append("Regular exercise can help regulate hormones and reduce cyst formation risk")
        if storage_data.get('diet_quality', '').lower() == 'poor':
            lifestyle_recommendations.append("A balanced diet rich in fruits, vegetables, and whole grains supports hormonal balance")
        if storage_data.get('stress_level', '').lower() in ['high', 'very high']:
            lifestyle_recommendations.append("Stress management through relaxation techniques can help regulate hormonal fluctuations")
        if storage_data.get('weight_status', '').lower() in ['obese', 'overweight']:
            lifestyle_recommendations.append("Maintaining a healthy weight can help reduce hormone-related cyst formation")
        if storage_data.get('pcos_diagnosis') == "Yes":
            lifestyle_recommendations.append("If you have PCOS, following a PCOS-friendly diet and exercise routine can help manage symptoms")
        
        if not lifestyle_recommendations:
            lifestyle_recommendations.extend([
                "Maintain a regular exercise routine to support hormonal balance",
                "Follow a balanced diet rich in nutrients",
                "Practice stress management techniques"
            ])
        
        content['lifestyle_recommendations'] = lifestyle_recommendations
        
        prevention_tips = [
            "Maintain regular gynecological check-ups for early detection",
            "Monitor your menstrual cycle and report any significant changes",
            "Exercise regularly to support hormonal balance",
            "Maintain a healthy weight through balanced diet and exercise",
            "Manage stress through healthy coping strategies",
            "Consider hormonal birth control if recommended by your doctor"
        ]
        
        content['prevention_tips'] = prevention_tips
        
        return content
        
    except Exception as e:
        logger.error(f"Error generating ovarian cysts education content: {e}")
        return {
            'what_this_means': 'Your assessment has been completed',
            'why_it_matters': 'Regular monitoring and healthy lifestyle choices are important for ovarian health',
            'lifestyle_recommendations': [],
            'prevention_tips': []
        }

def generate_ovarian_cysts_care_plan(user_uid, risk_level, storage_data, condition_type):
    """
    Generate automated care plan for ovarian cysts
    """
    try:
        care_plan = {
            'recommended_timeline': '',
            'next_steps': '',
            'lifestyle_actions': [],
            'monitoring_plan': '',
            'resources_needed': []
        }
        
        if risk_level == "High":
            care_plan['recommended_timeline'] = 'Within 1-2 weeks'
            care_plan['next_steps'] = 'Schedule an appointment with a gynecologist for pelvic examination and transvaginal ultrasound. If you have severe symptoms, seek medical attention promptly.'
            care_plan['monitoring_plan'] = 'Follow your doctor\'s recommendations for monitoring, which may include regular ultrasounds and symptom tracking.'
            care_plan['resources_needed'] = ['Gynecologist appointment', 'Transvaginal ultrasound', 'Possible blood tests (tumor markers if indicated)']
            
        elif risk_level == "Moderate":
            care_plan['recommended_timeline'] = 'Within 4-6 weeks'
            care_plan['next_steps'] = 'Schedule a routine gynecological exam to discuss your symptoms and risk factors. Request a pelvic ultrasound if you have persistent symptoms.'
            care_plan['monitoring_plan'] = 'Monitor your menstrual cycle and symptoms. Schedule follow-up appointments as recommended.'
            care_plan['resources_needed'] = ['Gynecologist appointment', 'Pelvic ultrasound if symptomatic', 'Menstrual cycle tracking']
            
        else:
            care_plan['recommended_timeline'] = 'Within 3-6 months (or as scheduled)'
            care_plan['next_steps'] = 'Continue with regular gynecological check-ups. Monitor your menstrual cycle and report any changes to your healthcare provider.'
            care_plan['monitoring_plan'] = 'Annual gynecological exams and self-monitoring of symptoms. Track menstrual patterns.'
            care_plan['resources_needed'] = ['Routine gynecological care', 'Menstrual cycle tracking app or calendar']
        
        lifestyle_actions = []
        if storage_data.get('exercise_frequency', '').lower() in ['rarely', 'never']:
            lifestyle_actions.append('Begin a regular exercise routine - aim for 150 minutes of moderate activity weekly')
        if storage_data.get('diet_quality', '').lower() == 'poor':
            lifestyle_actions.append('Adopt a balanced diet rich in fruits, vegetables, and whole grains')
        if storage_data.get('stress_level', '').lower() in ['high', 'very high']:
            lifestyle_actions.append('Practice stress management techniques such as meditation or yoga')
        if storage_data.get('weight_status', '').lower() in ['obese', 'overweight']:
            lifestyle_actions.append('Work on achieving and maintaining a healthy weight')
        if storage_data.get('pcos_diagnosis') == "Yes":
            lifestyle_actions.append('Follow PCOS management guidelines including diet and exercise modifications')
        
        if not lifestyle_actions:
            lifestyle_actions.extend([
                'Maintain regular physical activity',
                'Follow a balanced, nutritious diet',
                'Practice stress management techniques'
            ])
        
        care_plan['lifestyle_actions'] = lifestyle_actions
        
        if any([storage_data.get('pelvic_pain') == "Yes", 
                storage_data.get('abdominal_bloating') == "Yes",
                storage_data.get('irregular_periods') == "Yes"]):
            care_plan['next_steps'] += ' Keep a detailed symptom diary to share with your healthcare provider.'
            care_plan['monitoring_plan'] += ' Track symptom severity and frequency.'
        
        return care_plan
        
    except Exception as e:
        logger.error(f"Error generating ovarian cysts care plan: {e}")
        return {
            'recommended_timeline': '4-8 weeks',
            'next_steps': 'Consult with your healthcare provider for personalized recommendations.',
            'lifestyle_actions': ['Maintain healthy lifestyle habits'],
            'monitoring_plan': 'Regular gynecological check-ups and symptom monitoring.',
            'resources_needed': ['Healthcare consultation']
        }

def calculate_percentile_risk(user_uid, storage_data, condition_type):
    """
    Calculate percentile risk for ovarian cysts based on age group and risk factors
    """
    try:
        age = storage_data.get('age', 0)
        risk_score = storage_data.get('risk_score', 0)
        
        if age < 20:
            age_group = "Under 20"
            baseline_percentile = 25
        elif 20 <= age <= 29:
            age_group = "20-29"
            baseline_percentile = 40
        elif 30 <= age <= 39:
            age_group = "30-39"
            baseline_percentile = 50
        elif 40 <= age <= 49:
            age_group = "40-49"
            baseline_percentile = 45
        elif 50 <= age <= 59:
            age_group = "50-59"
            baseline_percentile = 35
        else:
            age_group = "60+"
            baseline_percentile = 20
        
        if risk_score >= 70:
            percentile_adjustment = 25
        elif risk_score >= 40:
            percentile_adjustment = 10
        else:
            percentile_adjustment = -15
        
        final_percentile = max(5, min(95, baseline_percentile + percentile_adjustment))
        
        risk_factors_count = 0
        high_risk_factors = ['pcos_diagnosis', 'endometriosis', 'previous_ovarian_cysts']
        moderate_risk_factors = ['menstrual_irregularity', 'family_history_ovarian', 'pelvic_pain', 'irregular_periods']
        
        for factor in high_risk_factors:
            if storage_data.get(factor) == "Yes":
                risk_factors_count += 2
        for factor in moderate_risk_factors:
            if storage_data.get(factor) == "Yes":
                risk_factors_count += 1
        
        if final_percentile >= 70:
            interpretation = "This indicates a higher risk level that warrants prompt medical attention."
        elif final_percentile >= 50:
            interpretation = "This suggests moderate risk that should be monitored with regular check-ups."
        else:
            interpretation = "This indicates lower risk, but continued awareness is important."
        
        return {
            'percentile': final_percentile,
            'age_group': age_group,
            'population_context': f"Your risk level is higher than {final_percentile}% of women in your age group",
            'risk_factors_identified': risk_factors_count,
            'interpretation': interpretation
        }
        
    except Exception as e:
        logger.error(f"Error calculating percentile risk: {e}")
        return {
            'percentile': 50,
            'age_group': "Unknown",
            'population_context': "Unable to calculate percentile risk",
            'risk_factors_identified': 0,
            'interpretation': "Please consult with your healthcare provider for personalized risk assessment."
        }
        


@app.route('/inventory', methods=['POST'])
def check_inventory():
    try:
        data = request.json or {}

        region = data.get('region', '').strip().title()
        item = data.get('item', '').strip().lower()

        filtered_data = inventory_data.copy()

        if region:
            filtered_data = filtered_data[filtered_data['Region'].str.title() == region]

        if item:
            filtered_data = filtered_data[
                filtered_data['Item'].str.lower().str.contains(item)
            ]

        if filtered_data.empty:
            return jsonify({
                'status': 'error',
                'message': 'No inventory found for the given criteria'
            }), 404

        inventory_list = filtered_data[[
            'Region', 'Facility', 'Item', 'Available Stock', 'Cost (KES)'
        ]].to_dict(orient='records')

        return jsonify({
            'status': 'success',
            'inventory': inventory_list,
            'timestamp': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f'Error in /inventory: {e}')
        return jsonify({
            'status': 'error',
            'message': 'Internal server error'
        }), 500

@app.route('/cost', methods=['POST'])
def calculate_cost():
    try:
        data = request.json
        region = data['region'].title().strip()
        service = data['service'].title().strip()
        category = data['category'].title().strip()
        cost_row = costs_data[
            (costs_data['Region'] == region) &
            (costs_data['Service'] == service) &
            (costs_data['Category'] == category)
        ]
        if cost_row.empty:
            return jsonify({'status': 'error', 'message': 'No matching service found'}), 404
        cost_details = cost_row.iloc[0].to_dict()
        return jsonify({
            'status': 'success',
            'region': region,
            'facility': cost_details['Facility'],
            'category': cost_details['Category'],
            'service': cost_details['Service'],
            'base_cost_kes': float(cost_details['Base Cost (KES)']),
            'nhif_covered': cost_details['NHIF Covered'] == 'Yes',
            'insurance_copay_kes': float(cost_details['Insurance Copay (KES)']),
            'out_of_pocket_kes': float(cost_details['Out-of-Pocket (KES)']),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f'Error in /cost: {e}')
        return jsonify({'status': 'error', 'message': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info("Starting Flask API server...")
    app.run(debug=True, host='0.0.0.0', port=5000)
# Start scheduler thread
scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
scheduler_thread.start()

if __name__ == '__main__':
    logger.info('Starting Server...')
    app.run(debug=True, host='0.0.0.0', port=5000)