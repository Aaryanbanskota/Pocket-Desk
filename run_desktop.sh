#!/usr/bin/env bash
# Runs Pocketdesk directly on this Linux computer desktop
cd "$(dirname "$0")"
flutter run -d linux "$@"
