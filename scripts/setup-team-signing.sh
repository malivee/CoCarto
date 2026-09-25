#!/bin/bash
# Penjelasan file: setup-team-signing.sh
# Script otomatis untuk mencegah error merge signing / developer team di Xcode antar-teman.
# Jalankan script ini sekali di terminal: ./scripts/setup-team-signing.sh

set -e

echo "🔧 Menyiapkan konfigurasi Git Signing CoCarto..."

# 1. Konfigurasi Git Filter Driver
git config filter.signing.clean 'sed -E "s/DEVELOPMENT_TEAM = [A-Z0-9]+;/DEVELOPMENT_TEAM = DTTY9ZX5T4;/g; s/PRODUCT_BUNDLE_IDENTIFIER = [^;]+;/PRODUCT_BUNDLE_IDENTIFIER = com.academy.goty.ArthurAdventures;/g"'
git config filter.signing.smudge 'cat'

# 2. Pasang Git Pre-commit Hook
mkdir -p .git/hooks
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
PBXPROJ="CoCarto.xcodeproj/project.pbxproj"
if [ -f "$PBXPROJ" ]; then
    sed -E -i '' 's/DEVELOPMENT_TEAM = [A-Z0-9]+;/DEVELOPMENT_TEAM = DTTY9ZX5T4;/g' "$PBXPROJ"
    sed -E -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = [^;]+;/PRODUCT_BUNDLE_IDENTIFIER = com.academy.goty.ArthurAdventures;/g' "$PBXPROJ"
    git add "$PBXPROJ" 2>/dev/null || true
fi
exit 0
EOF
chmod +x .git/hooks/pre-commit

echo "✅ Selesai! Sekarang saat teman kamu mengubah signing ke akunnya di Xcode,"
echo "   Git akan otomatis menjaga project.pbxproj tetap bersih saat commit & merge."
echo "   Tidak akan ada lagi konflik atau error signing antar-teman!"
