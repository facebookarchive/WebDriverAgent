if [[ ! -f Scripts/generate_modules.sh ]]; then
  echo "Run this script from the root of repository"
  exit 1
fi

MODULES_DIR="Modules"
MODULES_FILE="module.modulemap"
CONTENT="
module libxml [system] {
  header \"${SDKROOT}/usr/include/libxml2/libxml/tree.h\"
  export *
}
"
mkdir -p "$MODULES_DIR"
echo "$CONTENT" > "$MODULES_DIR/$MODULES_FILE"
