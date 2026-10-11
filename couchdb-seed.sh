#!/bin/sh
set -e

COUCHDB_URL="${COUCHDB_URL:-http://couchdb:5984}"
COUCHDB_USER="${COUCHDB_USER:-admin}"
COUCHDB_PASSWORD="${COUCHDB_PASSWORD:-123321k}"
AUTH="${COUCHDB_USER}:${COUCHDB_PASSWORD}"

echo "Waiting for CouchDB to be ready..."
until curl -sf "${COUCHDB_URL}" >/dev/null 2>&1; do
  sleep 1
done
echo "CouchDB is ready."

# Create the database
echo "Creating kou-database..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database" || true

# Create the design document with views
echo "Creating design document..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/_design/_all" \
  -H "Content-Type: application/json" \
  -d '{
    "views": {
      "students": {
        "map": "function(doc) { if (doc._id && doc._id.indexOf(\"stu-\") === 0) { emit(doc._id, doc); } }"
      },
      "applications": {
        "map": "function(doc) { if (doc._id && doc._id.indexOf(\"app-\") === 0) { emit(doc.studentNum, doc); } }"
      },
      "student-applications": {
        "map": "function(doc) { if (doc._id && doc._id.indexOf(\"app-\") === 0) { emit(doc.studentNum, doc); } }"
      },
      "categories": {
        "map": "function(doc) { if (doc._id && doc._id.indexOf(\"kat-\") === 0) { emit(doc._id, doc); } }"
      },
      "faculties": {
        "map": "function(doc) { if (doc._id && doc._id.indexOf(\"fac-\") === 0) { emit(doc._id, doc); } }"
      }
    }
  }' || true

# Seed sample student
echo "Seeding student stu-201307083..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/stu-201307083" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "stu-201307083",
    "nameSurname": "Ahmet Yilmaz",
    "mail": "ahmet@test.com",
    "telNum": "05551234567",
    "identityCard": "12345678901",
    "address": {"home": "Kocaeli", "job": ""},
    "dateBirth": "01/01/2000",
    "universityInfo": {
      "universityName": "Kocaeli Universitesi",
      "facility": "Muhendislik Fakultesi",
      "department": "Bilgisayar Muhendisligi",
      "grade": 3
    },
    "photoUrl": ""
  }' || true

# Seed admin student
echo "Seeding student stu-admin..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/stu-admin" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "stu-admin",
    "nameSurname": "Admin",
    "mail": "admin@test.com",
    "telNum": "",
    "identityCard": "",
    "address": {"home": "", "job": ""},
    "dateBirth": "",
    "universityInfo": {
      "universityName": "",
      "facility": "",
      "department": "",
      "grade": 0
    },
    "photoUrl": ""
  }' || true

# Seed faculty data
echo "Seeding faculty data..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/fac-1" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "fac-1",
    "faculties": [
      {"faculty": "Muhendislik Fakultesi", "departments": ["Bilgisayar Muhendisligi", "Elektrik Muhendisligi", "Makine Muhendisligi", "Insaat Muhendisligi", "Kimya Muhendisligi"]},
      {"faculty": "Fen Edebiyat Fakultesi", "departments": ["Matematik", "Fizik", "Kimya", "Biyoloji", "Turk Dili ve Edebiyati"]},
      {"faculty": "Iktisadi ve Idari Bilimler Fakultesi", "departments": ["Iktisat", "Isletme", "Kamu Yonetimi", "Calisma Ekonomisi", "Uluslararasi Iliskiler"]},
      {"faculty": "Teknoloji Fakultesi", "departments": ["Yazilim Muhendisligi", "Bilisim Sistemleri Muhendisligi", "Endustri Muhendisligi", "Yapi Muhendisligi", "Mekatronik Muhendisligi"]},
      {"faculty": "Spor Bilimleri Fakultesi", "departments": ["Antrenorluk Egitimi", "Spor Yoneticiligi", "Beden Egitimi", "Rekreasyon", "Spor Sagligi"]}
    ]
  }' || true

# Seed categories
echo "Seeding categories..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/kat-1" \
  -H "Content-Type: application/json" \
  -d '{"_id":"kat-1","categoryName":"Yaz Okulu"}' || true
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/kat-2" \
  -H "Content-Type: application/json" \
  -d '{"_id":"kat-2","categoryName":"Yatay Gecis"}' || true
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/kat-3" \
  -H "Content-Type: application/json" \
  -d '{"_id":"kat-3","categoryName":"DGS"}' || true
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/kat-4" \
  -H "Content-Type: application/json" \
  -d '{"_id":"kat-4","categoryName":"CAP"}' || true
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/kat-5" \
  -H "Content-Type: application/json" \
  -d '{"_id":"kat-5","categoryName":"Intibak"}' || true

# Seed a sample application
echo "Seeding sample application..."
curl -sf -X PUT -u "$AUTH" "${COUCHDB_URL}/kou-database/app-1" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "app-1",
    "studentNum": "201307083",
    "applicationType": "kat-1",
    "documents": [{"documentName": "Transkript", "path": ""}],
    "status": "Beklemede"
  }' || true

echo "Seed complete!"
