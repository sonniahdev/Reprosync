from flask import Flask, request, jsonify
import requests
import base64
from datetime import datetime
import json

app = Flask(__name__)

# M-Pesa Sandbox Credentials - REPLACE THESE WITH YOUR ACTUAL CREDENTIALS
# Get these from https://developer.safaricom.co.ke/
CONSUMER_KEY = "eyvAI1iKNFvKdr9zpkFcdnUY1d9tmC9yBskAsm8ksDkCnwWG"  # Replace with real key
CONSUMER_SECRET = "b11Pt7l3gGn5Gi1FvQGMGeMkDqPS1nIhZHRyN7UUf4FOFRZ8EpQ3R6YSO3PfL3tV"  # Replace with real secret
BUSINESS_SHORT_CODE = "174379"  # Official Safaricom test shortcode
PASSKEY = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"  # Official test passkey
CALLBACK_URL = "https://httpbin.org/post"  # Dummy URL for testing

# M-Pesa API URLs (Sandbox)
TOKEN_URL = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
STK_PUSH_URL = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"

def get_access_token():
    """Generate access token for M-Pesa API"""
    try:
        # Check if credentials are set
        if CONSUMER_KEY == "YOUR_ACTUAL_CONSUMER_KEY" or CONSUMER_SECRET == "YOUR_ACTUAL_CONSUMER_SECRET":
            print("ERROR: Please replace CONSUMER_KEY and CONSUMER_SECRET with your actual credentials!")
            return None
            
        # Encode consumer key and secret
        credentials = f"{CONSUMER_KEY}:{CONSUMER_SECRET}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        
        headers = {
            'Authorization': f'Basic {encoded_credentials}',
            'Content-Type': 'application/json'
        }
        
        print(f"Requesting access token...")
        response = requests.get(TOKEN_URL, headers=headers)
        print(f"Token response status: {response.status_code}")
        
        if response.status_code == 200:
            token_data = response.json()
            print("Access token obtained successfully!")
            return token_data.get('access_token')
        else:
            print(f"Token request failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"Error getting access token: {e}")
        return None

def generate_password():
    """Generate password for STK push"""
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    data_to_encode = f"{BUSINESS_SHORT_CODE}{PASSKEY}{timestamp}"
    password = base64.b64encode(data_to_encode.encode()).decode()
    return password, timestamp

@app.route('/mpesa/payment', methods=['POST'])
def initiate_payment():
    """Initiate M-Pesa STK Push payment"""
    try:
        # Get request data
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['number', 'amount']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        phone_number = data['number']
        amount = data['amount']
        account_reference = f"PAY{datetime.now().strftime('%Y%m%d%H%M%S')}"  # Auto-generated
        transaction_desc = f"Payment of KES {amount}"  # Auto-generated
        
        # Format phone number (ensure it starts with 254)
        if phone_number.startswith('0'):
            phone_number = '254' + phone_number[1:]
        elif phone_number.startswith('+254'):
            phone_number = phone_number[1:]
        elif not phone_number.startswith('254'):
            phone_number = '254' + phone_number
        
        # Get access token
        access_token = get_access_token()
        if not access_token:
            return jsonify({
                'success': False,
                'message': 'Failed to get access token'
            }), 500
        
        # Generate password and timestamp
        password, timestamp = generate_password()
        
        # Prepare STK push request
        stk_headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        stk_payload = {
            "BusinessShortCode": BUSINESS_SHORT_CODE,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": int(amount),
            "PartyA": phone_number,
            "PartyB": BUSINESS_SHORT_CODE,
            "PhoneNumber": phone_number,
            "CallBackURL": CALLBACK_URL,
            "AccountReference": account_reference,
            "TransactionDesc": transaction_desc
        }
        
        # Send STK push request with timeout and better error handling
        print(f"Sending STK push to {phone_number} for KES {amount}...")
        
        response = requests.post(STK_PUSH_URL, json=stk_payload, headers=stk_headers, timeout=30)
        
        print(f"STK push response status: {response.status_code}")
        print(f"STK push response: {response.text}")
        
        if response.status_code == 200:
            response_data = response.json()
            
            if response_data.get('ResponseCode') == '0':
                return jsonify({
                    'success': True,
                    'message': 'STK push sent successfully',
                    'checkout_request_id': response_data.get('CheckoutRequestID'),
                    'merchant_request_id': response_data.get('MerchantRequestID'),
                    'response_description': response_data.get('ResponseDescription')
                }), 200
            else:
                return jsonify({
                    'success': False,
                    'message': response_data.get('ResponseDescription', 'STK push failed'),
                    'error_code': response_data.get('ResponseCode')
                }), 400
        else:
            return jsonify({
                'success': False,
                'message': 'Failed to send STK push request',
                'error': response.text
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Internal server error: {str(e)}'
        }), 500

@app.route('/mpesa/callback', methods=['POST'])
def callback():
    """Handle M-Pesa callback"""
    try:
        callback_data = request.get_json()
        
        # Log the callback data (in production, save to database)
        print("M-Pesa Callback Data:")
        print(json.dumps(callback_data, indent=2))
        
        # Extract important information
        stk_callback = callback_data.get('Body', {}).get('stkCallback', {})
        result_code = stk_callback.get('ResultCode')
        
        if result_code == 0:
            # Payment successful
            print("Payment was successful!")
            # Process successful payment here
            
        else:
            # Payment failed
            print(f"Payment failed with code: {result_code}")
            # Handle failed payment here
        
        # Always return success to M-Pesa
        return jsonify({'ResultCode': 0, 'ResultDesc': 'Success'}), 200
        
    except Exception as e:
        print(f"Callback error: {e}")
        return jsonify({'ResultCode': 1, 'ResultDesc': 'Error'}), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({'status': 'API is running', 'timestamp': datetime.now().isoformat()}), 200

if __name__ == '__main__':
    print("M-Pesa Integration Server Starting...")
    print("Available endpoints:")
    print("POST /mpesa/payment - Initiate payment")
    print("POST /mpesa/callback - M-Pesa callback")
    print("GET /health - Health check")
    app.run(debug=True, host='0.0.0.0', port=5000)