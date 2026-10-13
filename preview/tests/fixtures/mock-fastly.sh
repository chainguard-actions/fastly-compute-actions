#!/bin/sh
# Mock fastly CLI for testing
echo "mock fastly: $*"
case "$*" in
  *"service delete"*) echo "Deleted (mock)"; exit 0 ;;
  *"compute publish"*) echo "Published (mock)"; exit 0 ;;
  *"service domain list"*) printf '[{"Name":"mock.edgecompute.app"}]\n'; exit 0 ;;
  *) echo "mock fastly: $*"; exit 0 ;;
esac
