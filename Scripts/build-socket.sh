CURRENT_DIR=$(pwd)
INSPECTOR_DIR="$CURRENT_DIR/Inspector"
cd "$INSPECTOR_DIR"
echo "Building Inspector for socket..."
npm run build-socket
echo "Done"