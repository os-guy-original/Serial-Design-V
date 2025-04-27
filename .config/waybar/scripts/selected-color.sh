#!/bin/bash

# Seçilen rengin saklanacağı dosya
COLOR_FILE="/tmp/hyprpicker-selected-color"

# Dosya yoksa veya boşsa varsayılan bir değer kullan
if [[ ! -f "$COLOR_FILE" || ! -s "$COLOR_FILE" ]]; then
    echo '{"text": "No Color", "class": "no-color"}'
    exit 0
fi

# Renk değerini al
COLOR=$(cat "$COLOR_FILE")

# Geçerli bir hex renk kodu mu kontrol et
if [[ ! $COLOR =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    echo '{"text": "Invalid", "class": "invalid-color"}'
    exit 0
fi

# Renk adını oluştur
COLOR_NAME=$(echo "$COLOR" | tr '[:lower:]' '[:upper:]')

# Normal JSON çıktısını oluştur, özel arka plan olmadan
echo "{\"text\": \"$COLOR_NAME\"}" 