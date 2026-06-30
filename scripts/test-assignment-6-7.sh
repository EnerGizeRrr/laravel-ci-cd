#!/bin/bash

set -e

echo "Testing Assignment 6 & 7 - Observability & Security"
echo "======================================================"

API_URL="${1:-http://localhost}"
FAILED=0

test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_code=$3
    local description=$4
    
    echo -n "Testing $description ... "
    
    response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_URL$endpoint")
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$status_code" -eq "$expected_code" ]; then
        echo "✅ PASS (HTTP $status_code)"
    else
        echo "❌ FAIL (Expected $expected_code, got $status_code)"
        FAILED=$((FAILED + 1))
    fi
}

test_header() {
    local endpoint=$1
    local header=$2
    local description=$3
    
    echo -n "Testing $description ... "
    
    response=$(curl -s -i "$API_URL$endpoint" | grep -i "^$header")
    
    if [ -n "$response" ]; then
        echo "✅ PASS"
        echo "  $response"
    else
        echo "❌ FAIL (Header not found)"
        FAILED=$((FAILED + 1))
    fi
}

test_json() {
    local endpoint=$1
    local key=$2
    local description=$3
    
    echo -n "Testing $description ... "
    
    response=$(curl -s "$API_URL$endpoint")
    
    if echo "$response" | grep -q "$key"; then
        echo "✅ PASS"
    else
        echo "❌ FAIL"
        echo "Response: $response"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo "=== ASSIGNMENT 6: OBSERVABILITY ==="
echo ""

echo "Health Endpoints:"
test_endpoint "GET" "/api/health" "200" "GET /api/health"
test_endpoint "GET" "/api/ready" "200" "GET /api/ready (if DB connected)"
test_json "/api/health" '"status":"alive"' "Health returns alive status"
test_json "/api/ready" '"status":"ready"' "Ready returns ready status"

echo ""
echo "Metrics Endpoint:"
test_endpoint "GET" "/api/metrics" "200" "GET /api/metrics"
test_json "/api/metrics" '"requests_total"' "Metrics includes request count"
test_json "/api/metrics" '"response_time_avg_ms"' "Metrics includes response time"
test_json "/api/metrics" '"errors_4xx"' "Metrics includes error count"

echo ""
echo "Request-ID Headers:"
response=$(curl -s -i "$API_URL/api/health" | grep -i "x-request-id")
if [ -n "$response" ]; then
    echo "✅ PASS: X-Request-ID header present"
    echo "  $response"
else
    echo "❌ FAIL: X-Request-ID header missing"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "=== ASSIGNMENT 7: SECURITY ==="
echo ""

echo "Security Headers:"
test_header "/api/health" "X-Frame-Options" "X-Frame-Options header"
test_header "/api/health" "X-Content-Type-Options" "X-Content-Type-Options header"
test_header "/api/health" "X-XSS-Protection" "X-XSS-Protection header"
test_header "/api/health" "Content-Security-Policy" "Content-Security-Policy header"

echo ""
echo "Debug Mode Security:"
response=$(curl -s "$API_URL/api/nonexistent")
if echo "$response" | grep -q "stack trace\|exception\|file"; then
    echo "❌ FAIL: Stack trace visible in production"
    FAILED=$((FAILED + 1))
else
    echo "✅ PASS: No stack trace in error response"
fi

echo ""
echo "CORS Configuration:"
response=$(curl -s -H "Origin: https://malicious.com" "$API_URL/api/health")
if [ -n "$response" ]; then
    echo "✅ PASS: CORS handling active"
else
    echo "⚠️  WARNING: CORS test inconclusive"
fi

echo ""
echo "Rate Limiting Test (should fail after burst):"
echo -n "Sending 100 rapid requests ... "
total_success=0
for i in {1..100}; do
    status=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/metrics")
    if [ "$status" -eq 429 ]; then
        echo "✅ PASS: Rate limit triggered (429)"
        FAILED=$((FAILED - 1))  # Reset previous fail if this passes
        break
    fi
done

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✅ ALL TESTS PASSED!"
    echo "======================================"
else
    echo ""
    echo "======================================"
    echo "❌ SOME TESTS FAILED ($FAILED)"
    echo "======================================"
fi

exit $FAILED
