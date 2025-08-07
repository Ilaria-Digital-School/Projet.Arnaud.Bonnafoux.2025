#!/bin/bash

# ✅ CONFIG
BASE_URL="https://lasicroom.local/api/reservations"
AUTH_URL="https://lasicroom.local/api/connexions"
TMP_FILE="tmp_reservation_id.txt"

# 🔐 1. Connexion de l'admin Alice
echo "🔐 Connexion d'Alice..."
TOKEN=$(curl -sk -X POST "$AUTH_URL" -H "Content-Type: application/json" -d '{"email":"alice@example.com","mot_de_passe":"alice123"}' | jq -r .token)

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Erreur : impossible de récupérer un token."
  exit 1
fi
echo "✅ Token obtenu."

# 🎯 2. Choix du concert (≠ id_concert 8 déjà réservé par Alice)
ID_CONCERT=5 # <-- Assure-toi que ce concert a des places restantes dans ta BDD
TARIF="plein"
MONTANT=20.00 # <-- Adapte selon la grille tarifaire du concert 5

# 📝 3. Création d’une réservation
echo -e "\n📝 Création d’une réservation pour le concert $ID_CONCERT..."
REPONSE=$(curl -sk -X POST "$BASE_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"id_concert\": $ID_CONCERT,
    \"type_tarif\": \"$TARIF\",
    \"montant\": $MONTANT
  }" | tee /dev/tty)

ID_RESERVATION=$(echo "$REPONSE" | jq -r .id_reservation)

if [ "$ID_RESERVATION" == "null" ] || [ -z "$ID_RESERVATION" ]; then
  echo "❌ Erreur : réservation non créée."
  exit 1
fi
echo "$ID_RESERVATION" > "$TMP_FILE"
echo "✅ Réservation créée avec l'ID : $ID_RESERVATION"

# 📋 4. Consultation des réservations (admin)
echo -e "\n📋 Récupération des réservations (GET)..."
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE_URL" | jq .

# 🗑️ 5. Suppression de la réservation (DELETE)
echo -e "\n🗑️ Suppression de la réservation $ID_RESERVATION..."
curl -sk -X DELETE "$BASE_URL/$ID_RESERVATION" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 🧹 Nettoyage
rm -f "$TMP_FILE"
