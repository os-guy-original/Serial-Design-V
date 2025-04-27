#!/bin/bash

# Seçilen rengin saklanacağı dosya
COLOR_FILE="/tmp/hyprpicker-selected-color"

# Dosya yoksa veya boşsa varsayılan bir değer kullan
if [[ ! -f "$COLOR_FILE" || ! -s "$COLOR_FILE" ]]; then
    echo '{"text": "", "tooltip": "No color selected yet", "class": "no-color"}'
    exit 0
fi

# Renk değerini al
COLOR=$(cat "$COLOR_FILE")

# Geçerli bir hex renk kodu mu kontrol et
if [[ ! $COLOR =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    echo '{"text": "", "tooltip": "Invalid color format", "class": "invalid-color"}'
    exit 0
fi

# Renk adını oluştur
COLOR_NAME=$(echo "$COLOR" | tr '[:lower:]' '[:upper:]')

# Renk tonu için class belirle
# Kırmızı, yeşil ve mavi değerlerini al
R=$(echo "$COLOR" | cut -c2-3)
G=$(echo "$COLOR" | cut -c4-5)
B=$(echo "$COLOR" | cut -c6-7)

# Hex'i decimal'e çevir
R=$((16#$R))
G=$((16#$G))
B=$((16#$B))

# Rengin açıklık/koyuluk değerini hesapla
BRIGHTNESS=$(( (R + G + B) / 3 ))

# Renk tonu için class belirle
if [[ $BRIGHTNESS -lt 128 ]]; then
    TEXT_COLOR="#FFFFFF"  # Açık renk metin için koyu arka plan
    CLASS="dark-color"
else
    TEXT_COLOR="#000000"  # Koyu renk metin için açık arka plan
    CLASS="light-color"
fi

# CSS stil tanımı
CSS_STYLE="background-color: $COLOR; color: $TEXT_COLOR;"

# JSON çıktısını oluştur
echo "{\"text\": \"$COLOR_NAME\", \"tooltip\": \"Selected Color: $COLOR_NAME\nClick to copy to clipboard\", \"class\": \"$CLASS\", \"style\": \"$CSS_STYLE\"}" 