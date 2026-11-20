#!/usr/bin/env bash
# ==============================================================================
# CONSOLIDATED INFRASTRUCTURE OPERATIONS REPORT GENERATOR
# ==============================================================================
# Framework: Enterprise Infrastructure Automation Framework
# Classification: REPORTING / OPERATIONAL_ANALYTICS
# Usage:
#   ./scripts/generate-report.sh
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}" || exit 1

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_DIR="${REPO_ROOT}/reports/execution"
mkdir -p "${REPORT_DIR}"
HTML_REPORT="${REPORT_DIR}/CONSOLIDATED_SUMMARY_${TIMESTAMP}.html"
TXT_REPORT="${REPORT_DIR}/CONSOLIDATED_SUMMARY_${TIMESTAMP}.txt"

echo "=============================================================================="
echo "ENTERPRISE INFRASTRUCTURE REPORT AGGREGATOR"
echo "=============================================================================="
echo "Report Dir : ${REPORT_DIR}"
echo "Generated  : $(date)"
echo "=============================================================================="

# Count available reports across categories
HEALTH_COUNT=$(find "${REPO_ROOT}/reports/health-checks" -type f 2>/dev/null | wc -l)
AUDIT_COUNT=$(find "${REPO_ROOT}/reports/configuration-audits" -type f 2>/dev/null | wc -l)
INCIDENT_COUNT=$(find "${REPO_ROOT}/case-output" -type d -name "session_*" 2>/dev/null | wc -l)
VALIDATION_COUNT=$(find "${REPO_ROOT}/reports/validation" -type f 2>/dev/null | wc -l)

# Generate Text Report
cat <<EOF > "${TXT_REPORT}"
==============================================================================
ENTERPRISE INFRASTRUCTURE OPERATIONS SUMMARY
==============================================================================
Generated: $(date)
Controller: $(hostname -f 2>/dev/null || hostname)
Repository: ${REPO_ROOT}

1. OPERATIONS METRICS
------------------------------------------------------------------------------
Health Check Artifacts Captured : ${HEALTH_COUNT}
Configuration Audits Performed  : ${AUDIT_COUNT}
Incident Evidence Sessions Saved : ${INCIDENT_COUNT}
Validation Run Artifacts        : ${VALIDATION_COUNT}

2. HEALTH CHECK ARTIFACTS
------------------------------------------------------------------------------
$(find "${REPO_ROOT}/reports/health-checks" -type f -exec ls -lh {} + 2>/dev/null | awk '{print $9, "(" $5 ")"}' || echo "No health reports found.")

3. INCIDENT EVIDENCE SESSIONS
------------------------------------------------------------------------------
$(find "${REPO_ROOT}/case-output" -maxdepth 2 -type d 2>/dev/null || echo "No incident cases logged.")
==============================================================================
EOF

# Generate HTML Report
cat <<EOF > "${HTML_REPORT}"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Enterprise Infrastructure Operations Consolidated Summary</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 25px; background: #f8fafc; color: #1e293b; }
    .header { background: #0f172a; color: white; padding: 25px; border-radius: 8px; margin-bottom: 25px; }
    .header h1 { margin: 0 0 8px 0; font-size: 24px; }
    .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 25px; }
    .card { background: white; padding: 20px; border-radius: 8px; border: 1px solid #e2e8f0; text-align: center; }
    .num { font-size: 32px; font-weight: 700; color: #2563eb; }
    .label { font-size: 13px; color: #64748b; text-transform: uppercase; margin-top: 5px; }
    .section { background: white; padding: 20px; border-radius: 8px; border: 1px solid #e2e8f0; margin-bottom: 20px; }
    h2 { color: #0f172a; margin-top: 0; font-size: 18px; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; }
    pre { background: #f1f5f9; padding: 15px; border-radius: 6px; font-size: 13px; overflow-x: auto; }
  </style>
</head>
<body>

  <div class="header">
    <h1>Enterprise Infrastructure Operations Consolidated Summary</h1>
    <p>Report Date: $(date) | Controller: $(hostname -f 2>/dev/null || hostname)</p>
  </div>

  <div class="grid">
    <div class="card"><div class="num">${HEALTH_COUNT}</div><div class="label">Health Checks</div></div>
    <div class="card"><div class="num">${AUDIT_COUNT}</div><div class="label">Config Audits</div></div>
    <div class="card"><div class="num">${INCIDENT_COUNT}</div><div class="label">Incident Sessions</div></div>
    <div class="card"><div class="num">${VALIDATION_COUNT}</div><div class="label">Validations</div></div>
  </div>

  <div class="section">
    <h2>Operations Summary Details</h2>
    <pre>$(cat "${TXT_REPORT}")</pre>
  </div>

</body>
</html>
EOF

echo "[+] Consolidated summary reports generated:"
echo "    HTML: ${HTML_REPORT}"
echo "    Text: ${TXT_REPORT}"
echo "=============================================================================="

exit 0
