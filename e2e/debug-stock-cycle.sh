#!/bin/bash

# Script to debug stock-cycle test with CI-like conditions
# This runs the test multiple times with detailed logging

echo "Running stock-cycle test with debugging..."
echo "=========================================="

for i in {1..10}; do
  echo ""
  echo "=== Attempt $i/10 ==="
  
  # Run the test with full output
  npm test -- tests/stock-cycle.spec.js --reporter=dot 2>&1 | tee /tmp/test-run-$i.log
  
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ FAILURE on attempt $i!"
    echo "Logs saved to /tmp/test-run-$i.log"
    
    # Show last 50 lines
    echo ""
    echo "Last 50 lines of output:"
    tail -50 /tmp/test-run-$i.log
    
    exit 1
  else
    echo "✅ Pass"
  fi
  
  # Small delay between runs
  sleep 1
done

echo ""
echo "=========================================="
echo "All 10 runs passed! ✅"
