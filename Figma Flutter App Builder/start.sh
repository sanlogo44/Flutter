#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Figma Flutter App Builder – Startskript
#  Startet Flutter-Frontend und Node.js-Backend zusammen.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Konfiguration ---
FLUTTER_PORT="8080"
BACKEND_PORT="3000"
BACKEND_DIR="$SCRIPT_DIR/backend"
RUN_TESTS=false
SKIP_BACKEND=false
SKIP_FRONTEND=false

# --- Argumente parsen ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --test|-t)       RUN_TESTS=true; shift ;;
    --no-backend)    SKIP_BACKEND=true; shift ;;
    --no-frontend)   SKIP_FRONTEND=true; shift ;;
    --backend-port)  BACKEND_PORT="$2"; shift 2 ;;
    --flutter-port)  FLUTTER_PORT="$2"; shift 2 ;;
    --help|-h)
      echo "Verwendung: ./start.sh [Optionen]"
      echo ""
      echo "Optionen:"
      echo "  --test, -t        Führt Tests vor dem Start aus"
      echo "  --no-backend      Startet nur das Flutter-Frontend"
      echo "  --no-frontend     Startet nur das Backend"
      echo "  --backend-port N  Backend-Port (Standard: 3000)"
      echo "  --flutter-port N  Flutter-Port (Standard: 8080)"
      echo "  --help, -h        Diese Hilfe anzeigen"
      exit 0 ;;
    *) log_error "Unbekannte Option: $1"; exit 1 ;;
  esac
done

echo ""
echo "========================================"
echo "  Figma Flutter App Builder"
echo "========================================"
echo ""

# --- Prerequisites prüfen ---

check_flutter() {
  if command -v flutter &>/dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1)
    log_ok "Flutter gefunden: $FLUTTER_VERSION"
    return 0
  elif command -v dart &>/dev/null; then
    log_warn "Flutter nicht gefunden, aber Dart SDK verfügbar"
    log_info "Verwende Dart direkt (eingeschränkter Modus)"
    return 0
  else
    log_error "Weder Flutter noch Dart gefunden"
    log_info "Installieren: https://docs.flutter.dev/get-started/install"
    return 1
  fi
}

check_node() {
  if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null)
    log_ok "Node.js gefunden: $NODE_VERSION"
  else
    log_error "Node.js nicht gefunden"
    log_info "Installieren: https://nodejs.org/"
    return 1
  fi

  if command -v npm &>/dev/null; then
    NPM_VERSION=$(npm --version 2>/dev/null)
    log_ok "npm gefunden: $NPM_VERSION"
  else
    log_error "npm nicht gefunden"
    return 1
  fi
}

check_prisma_cli() {
  if [[ -d "$BACKEND_DIR" ]]; then
    if ! npx prisma --version &>/dev/null 2>&1; then
      log_warn "Prisma CLI nicht global verfügbar, wird lokal verwendet"
    fi
  fi
}

# --- Backend starten ---

start_backend() {
  if [[ ! -d "$BACKEND_DIR" ]]; then
    log_warn "Kein backend/ Verzeichnis gefunden – überspringe Backend"
    SKIP_BACKEND=true
    return 0
  fi

  log_info "=== Backend wird vorbereitet ==="

  cd "$BACKEND_DIR"

  # .env aus .env.example erstellen falls nicht vorhanden
  if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
      log_info "Erstelle .env aus .env.example"
      cp .env.example .env
      log_warn ".env enthält Platzhalter – bitte echte Werte eintragen!"
    else
      log_warn "Keine .env.example gefunden – Backend benötigt DATABASE_URL und JWT_SECRET"
    fi
  fi

  # Dependencies installieren
  log_info "npm install..."
  if ! npm install --silent 2>/dev/null; then
    log_error "npm install fehlgeschlagen"
    cd "$SCRIPT_DIR"
    return 1
  fi
  log_ok "Dependencies installiert"

  # Prisma Client generieren
  log_info "Prisma Client generieren..."
  if [[ -f "prisma/schema.prisma" ]]; then
    npx prisma generate 2>/dev/null || log_warn "Prisma generate übersprungen"
    log_ok "Prisma Client generiert"
  fi

  # Tests falls gewünscht
  if $RUN_TESTS; then
    log_info "Backend-Tests..."
    npm test 2>/dev/null || log_warn "Backend-Tests fehlgeschlagen oder nicht vorhanden"
  fi

  # Backend im Hintergrund starten
  log_info "Starte Backend auf Port $BACKEND_PORT..."
  PORT="$BACKEND_PORT" npm run dev &
  BACKEND_PID=$!
  log_ok "Backend gestartet (PID: $BACKEND_PID, Port: $BACKEND_PORT)"

  # Warten bis Backend erreichbar ist
  log_info "Warte auf Backend..."
  for i in $(seq 1 30); do
    if curl -s "http://localhost:$BACKEND_PORT/api/health" &>/dev/null; then
      log_ok "Backend ist erreichbar"
      break
    fi
    if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
      log_error "Backend-Prozess ist abgestürzt"
      cd "$SCRIPT_DIR"
      return 1
    fi
    sleep 1
  done

  cd "$SCRIPT_DIR"
}

# --- Flutter/Frontend starten ---

start_frontend() {
  log_info "=== Flutter-Frontend wird vorbereitet ==="

  cd "$SCRIPT_DIR"

  # Dependencies
  log_info "flutter pub get..."
  if command -v flutter &>/dev/null; then
    flutter pub get 2>/dev/null || { log_error "flutter pub get fehlgeschlagen"; return 1; }
  elif command -v dart &>/dev/null; then
    dart pub get 2>/dev/null || { log_error "dart pub get fehlgeschlagen"; return 1; }
  fi
  log_ok "Dependencies installiert"

  # Analyse
  log_info "Statische Analyse..."
  if command -v flutter &>/dev/null; then
    flutter analyze --no-fatal-infos 2>/dev/null || log_warn "Analyse-Warnungen vorhanden"
  fi

  # Tests
  if $RUN_TESTS; then
    log_info "Frontend-Tests..."
    if command -v flutter &>/dev/null; then
      flutter test 2>/dev/null || log_warn "Frontend-Tests fehlgeschlagen"
    fi
  fi

  # Frontend starten
  log_info "Starte Flutter auf Port $FLUTTER_PORT..."
  if command -v flutter &>/dev/null; then
    flutter run --web-port="$FLUTTER_PORT" 2>&1
  elif command -v dart &>/dev/null; then
    dart run lib/main.dart 2>&1
  fi
}

# --- Cleanup ---

cleanup() {
  echo ""
  log_info "Beende Prozesse..."
  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
    log_ok "Backend beendet"
  fi
  log_ok "Aufgeräumt"
}

trap cleanup EXIT INT TERM

# --- Hauptablauf ---

log_info "Prerequisites werden geprüft..."
echo ""

if ! $SKIP_FRONTEND; then
  check_flutter || SKIP_FRONTEND=true
fi

if ! $SKIP_BACKEND; then
  check_node || SKIP_BACKEND=true
  check_prisma_cli
fi

echo ""

# Backend zuerst starten (Frontend kann es dann erreichen)
if ! $SKIP_BACKEND; then
  start_backend
  echo ""
fi

if ! $SKIP_FRONTEND; then
  start_frontend
fi

if $SKIP_BACKEND && $SKIP_FRONTEND; then
  log_error "Weder Frontend noch Backend können gestartet werden"
  log_info "Bitte Flutter und Node.js installieren"
  exit 1
fi
