#!/bin/zsh

# Skript pro vyhledání a odstranění duplikátních souborů všech typů v macOS

TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Chyba: Adresář '$TARGET_DIR' neexistuje."
    exit 1
fi

echo "Procházení souborů v adresáři: $TARGET_DIR"

# Vytvoření dočasného souboru pro uložení výsledků
TEMP_FILE=$(mktemp)

# Procházení všech souborů a výpočet hash
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
    echo "$hash $file" >> "$TEMP_FILE"
    echo "Zpracován soubor: $file"
done

echo "Hledání duplikátů..."
DUPLICATES=$(sort "$TEMP_FILE" | awk '
    {
        hash=$1;
        file=substr($0, index($0,$2));
        count[hash]++;
        if(count[hash] == 1) files[hash] = file;
        else if(count[hash] == 2) print files[hash] "\n" file;
        else if(count[hash] > 2) print file;
    }
')

if [[ -z "$DUPLICATES" ]]; then
    echo "Žádné duplikáty nebyly nalezeny."
else
    echo "Nalezeny následující duplikáty:"
    echo "$DUPLICATES"

    read "CONFIRM?Chcete odstranit tyto duplikátní soubory? (první soubor z každé skupiny bude zachován) (a/N): "
    if [[ "$CONFIRM" == "a" || "$CONFIRM" == "A" ]]; then
        echo "$DUPLICATES" | awk '
            BEGIN { first = 1 }
            { 
                if (first) {
                    first = 0;
                } else {
                    print "Odstraňuji: " $0;
                    system("rm \"" $0 "\"");
                    first = 1;
                }
            }
        '
        echo "Duplikáty byly odstraněny."
    else
        echo "Operace zrušena. Žádné soubory nebyly odstraněny."
    fi
fi

# Úklid
rm "$TEMP_FILE"

echo "Operace dokončena."