from firebase_config import db

# Change 'your-collection-name' to your actual collection name
docs = db.collection('users').get()
docs = db.collection('appointments').get()
docs = db.collection('doctors').get()
docs = db.collection('ovarian_screening').get()
docs = db.collection('cervical_screening').get()


for doc in docs:
    print(f'{doc.id} => {doc.to_dict()}')
