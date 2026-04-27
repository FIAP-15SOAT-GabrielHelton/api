#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

OUTPUT_HTML="tmp/security_report.html"
OUTPUT_PDF="tmp/security_report.pdf"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

mkdir -p tmp

# Verify python3 is available
if ! command -v python3 &> /dev/null; then
  echo "Error: python3 is required but not installed"
  exit 1
fi

# Verify Chrome exists
if [ ! -f "$CHROME" ]; then
  echo "Warning: Chrome not found at $CHROME. PDF generation will be skipped."
  CHROME=""
fi

echo "🔍 Running security scans..."

# Step 1 — bundler-audit
echo "  • Running bundler-audit..."
AUDIT_JSON=$(docker compose run --rm --no-deps web \
  bundle exec bundler-audit check --update --format json \
  --config config/bundler-audit.yml 2>/dev/null | grep '^{' || echo '{}')

# Step 2 — brakeman
echo "  • Running brakeman..."
BRAKEMAN_JSON=$(docker compose run --rm --no-deps web \
  bundle exec brakeman --format json --no-pager \
  --no-exit-on-warn --no-exit-on-error --quiet 2>/dev/null || echo '{}')

# Step 3 — Trivy
echo "  • Running Trivy..."
TRIVY_JSON=$(docker run --rm \
  -v "$REPO_ROOT:/repo" \
  aquasec/trivy fs \
  --format json --quiet --scanners vuln,misconfig \
  /repo 2>/dev/null || echo '{}')

# Step 4 — Semgrep
echo "  • Running Semgrep..."
SEMGREP_JSON=$(docker run --rm \
  -v "$REPO_ROOT:/src" \
  semgrep/semgrep semgrep \
  --config p/ruby --config p/rails \
  --json --quiet \
  /src 2>/dev/null || echo '{}')

echo "✓ Scans complete. Generating report..."

# Step 5 — Generate HTML
export AUDIT_JSON BRAKEMAN_JSON TRIVY_JSON SEMGREP_JSON

python3 << 'PYEOF'
import os
import json
from datetime import datetime
import html as html_module

def safe_html(text):
    """Escape HTML special characters"""
    return html_module.escape(str(text))

def parse_json(json_str):
    """Safely parse JSON string"""
    try:
        return json.loads(json_str)
    except (json.JSONDecodeError, ValueError):
        return {}

# Parse all JSON inputs
audit_data = parse_json(os.environ.get('AUDIT_JSON', '{}'))
brakeman_data = parse_json(os.environ.get('BRAKEMAN_JSON', '{}'))
trivy_data = parse_json(os.environ.get('TRIVY_JSON', '{}'))
semgrep_data = parse_json(os.environ.get('SEMGREP_JSON', '{}'))

# Count findings
audit_count = len(audit_data.get('vulnerabilities', []))
brakeman_count = len(brakeman_data.get('warnings', []))
trivy_results = trivy_data.get('Results', [])
trivy_count = sum(len(r.get('Misconfigurations', []) + r.get('Vulnerabilities', [])) for r in trivy_results)
semgrep_count = len(semgrep_data.get('results', []))

# Determine severity badges
def get_badge_color(count):
    if count == 0:
        return 'green'
    elif count < 5:
        return 'yellow'
    else:
        return 'red'

audit_color = get_badge_color(audit_count)
brakeman_color = get_badge_color(brakeman_count)
trivy_color = get_badge_color(trivy_count)
semgrep_color = get_badge_color(semgrep_count)

timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

# Helper functions for building sections
def build_audit_section():
    if audit_count == 0:
        return '<div class="empty-state">✓ No vulnerabilities detected</div>'

    rows = []
    for v in audit_data.get('vulnerabilities', []):
        rows.append(f"""<tr>
            <td><span class="code">{safe_html(v.get('gem', 'N/A'))}</span></td>
            <td>{safe_html(v.get('version', 'N/A'))}</td>
            <td>{safe_html(v.get('advisory_id', 'N/A'))}</td>
            <td>{safe_html(v.get('cve', 'N/A') or 'N/A')}</td>
            <td><span class="severity-critical">{safe_html(v.get('severity', 'UNKNOWN'))}</span></td>
            <td>{safe_html(v.get('title', 'N/A'))}</td>
        </tr>""")

    return f"""<table>
        <thead>
            <tr>
                <th>Gem</th>
                <th>Version</th>
                <th>Advisory</th>
                <th>CVE</th>
                <th>Severity</th>
                <th>Summary</th>
            </tr>
        </thead>
        <tbody>
            {''.join(rows)}
        </tbody>
    </table>"""

def build_brakeman_section():
    if brakeman_count == 0:
        return '<div class="empty-state">✓ No warnings detected</div>'

    rows = []
    for w in brakeman_data.get('warnings', []):
        rows.append(f"""<tr>
            <td><span class="code">{safe_html(w.get('file', 'N/A'))}</span></td>
            <td>{safe_html(str(w.get('line', 'N/A')))}</td>
            <td>{safe_html(w.get('warning_type', 'N/A'))}</td>
            <td><span class="severity-{w.get('confidence', 'low').lower()}">{safe_html(w.get('confidence', 'N/A'))}</span></td>
            <td>{safe_html(w.get('message', 'N/A'))}</td>
        </tr>""")

    return f"""<table>
        <thead>
            <tr>
                <th>File</th>
                <th>Line</th>
                <th>Type</th>
                <th>Confidence</th>
                <th>Message</th>
            </tr>
        </thead>
        <tbody>
            {''.join(rows)}
        </tbody>
    </table>"""

def build_trivy_section():
    if trivy_count == 0:
        return '<div class="empty-state">✓ No issues detected</div>'

    sections = []
    for r in trivy_results:
        target = safe_html(r.get('Target', 'Unknown Target'))
        vulns = r.get('Vulnerabilities', [])
        misconfigs = r.get('Misconfigurations', [])

        section = f'<h3>{target}</h3>'

        if vulns:
            vuln_rows = []
            for v in vulns:
                vuln_rows.append(f"""<tr>
                    <td><span class="code">{safe_html(v.get('VulnerabilityID', 'N/A'))}</span></td>
                    <td>{safe_html(v.get('PkgName', 'N/A'))}</td>
                    <td>{safe_html(v.get('InstalledVersion', 'N/A'))}</td>
                    <td>{safe_html(v.get('FixedVersion', 'N/A') or 'N/A')}</td>
                    <td><span class="severity-{v.get('Severity', 'unknown').lower()}">{safe_html(v.get('Severity', 'UNKNOWN'))}</span></td>
                    <td>{safe_html(v.get('Description', 'N/A')[:100])}</td>
                </tr>""")

            section += f"""<h4>Vulnerabilities</h4>
            <table>
                <thead>
                    <tr>
                        <th>CVE ID</th>
                        <th>Package</th>
                        <th>Installed</th>
                        <th>Fixed</th>
                        <th>Severity</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    {''.join(vuln_rows)}
                </tbody>
            </table>"""
        else:
            section += '<div class="empty-state">No vulnerabilities</div>'

        if misconfigs:
            misconf_rows = []
            for m in misconfigs:
                misconf_rows.append(f"""<tr>
                    <td><span class="code">{safe_html(m.get('ID', 'N/A'))}</span></td>
                    <td><span class="severity-{m.get('Severity', 'unknown').lower()}">{safe_html(m.get('Severity', 'UNKNOWN'))}</span></td>
                    <td>{safe_html(m.get('Title', 'N/A'))}</td>
                    <td>{safe_html(m.get('Description', 'N/A')[:100])}</td>
                </tr>""")

            section += f"""<h4>Misconfigurations</h4>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Severity</th>
                        <th>Title</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
                    {''.join(misconf_rows)}
                </tbody>
            </table>"""
        else:
            section += '<div class="empty-state">No misconfigurations</div>'

        sections.append(section)

    return ''.join(sections)

def build_semgrep_section():
    if semgrep_count == 0:
        return '<div class="empty-state">✓ No findings detected</div>'

    rows = []
    for f in semgrep_data.get('results', []):
        line = f.get('start', {}).get('line', 'N/A') if isinstance(f.get('start'), dict) else 'N/A'
        rows.append(f"""<tr>
            <td><span class="code">{safe_html(f.get('path', 'N/A'))}</span></td>
            <td>{safe_html(str(line))}</td>
            <td><span class="code">{safe_html(f.get('rule_id', 'N/A'))}</span></td>
            <td><span class="severity-{f.get('severity', 'info').lower()}">{safe_html(f.get('severity', 'INFO'))}</span></td>
            <td>{safe_html(f.get('message', 'N/A'))}</td>
        </tr>""")

    return f"""<table>
        <thead>
            <tr>
                <th>File</th>
                <th>Line</th>
                <th>Rule ID</th>
                <th>Severity</th>
                <th>Message</th>
            </tr>
        </thead>
        <tbody>
            {''.join(rows)}
        </tbody>
    </table>"""

audit_section = build_audit_section()
brakeman_section = build_brakeman_section()
trivy_section = build_trivy_section()
semgrep_section = build_semgrep_section()

html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Vulnerability Report</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        header {{
            border-bottom: 3px solid #007bff;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }}
        h1 {{
            font-size: 28px;
            margin-bottom: 10px;
            color: #111;
        }}
        .timestamp {{
            color: #666;
            font-size: 14px;
        }}
        .badges {{
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            margin-top: 20px;
        }}
        .badge {{
            padding: 8px 12px;
            border-radius: 4px;
            font-weight: 600;
            font-size: 13px;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }}
        .badge.green {{
            background: #d4edda;
            color: #155724;
        }}
        .badge.yellow {{
            background: #fff3cd;
            color: #856404;
        }}
        .badge.red {{
            background: #f8d7da;
            color: #721c24;
        }}
        .section {{
            margin-bottom: 40px;
        }}
        .section h2 {{
            font-size: 20px;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
            color: #222;
        }}
        .section h3 {{
            font-size: 14px;
            margin-top: 15px;
            margin-bottom: 10px;
            color: #666;
            font-weight: 600;
        }}
        .section h4 {{
            font-size: 12px;
            margin-top: 12px;
            margin-bottom: 8px;
            color: #666;
            font-weight: 600;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
            font-size: 13px;
        }}
        thead {{
            background: #f8f9fa;
        }}
        th {{
            padding: 10px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }}
        td {{
            padding: 10px;
            border-bottom: 1px solid #dee2e6;
            word-break: break-word;
        }}
        tr:nth-child(even) {{
            background: #f9f9f9;
        }}
        .severity-critical {{
            color: #dc3545;
            font-weight: 600;
        }}
        .severity-high {{
            color: #fd7e14;
            font-weight: 600;
        }}
        .severity-medium {{
            color: #ffc107;
            font-weight: 600;
        }}
        .severity-low {{
            color: #28a745;
        }}
        .severity-info {{
            color: #17a2b8;
        }}
        .severity-unknown {{
            color: #999;
        }}
        .empty-state {{
            padding: 20px;
            background: #f8f9fa;
            border-radius: 4px;
            text-align: center;
            color: #666;
        }}
        .summary {{
            padding: 15px;
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            border-radius: 4px;
            margin-bottom: 20px;
        }}
        .code {{
            background: #f4f4f4;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
        }}
        @media print {{
            body {{
                padding: 0;
                background: white;
            }}
            .container {{
                padding: 20px;
                box-shadow: none;
                border-radius: 0;
            }}
            .section {{
                page-break-inside: avoid;
            }}
            table {{
                page-break-inside: avoid;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔒 Security Vulnerability Report</h1>
            <div class="timestamp">Generated: {timestamp}</div>
            <div class="badges">
                <div class="badge {audit_color}">bundler-audit: {audit_count} findings</div>
                <div class="badge {brakeman_color}">brakeman: {brakeman_count} warnings</div>
                <div class="badge {trivy_color}">Trivy: {trivy_count} issues</div>
                <div class="badge {semgrep_color}">Semgrep: {semgrep_count} findings</div>
            </div>
        </header>

        <!-- bundler-audit Section -->
        <section class="section">
            <h2>📦 Dependency Vulnerabilities (bundler-audit)</h2>
            <div class="summary">Scans Gemfile.lock for known CVEs in gem dependencies.</div>
            {audit_section}
        </section>

        <!-- brakeman Section -->
        <section class="section">
            <h2>🛡️ Static Analysis (brakeman)</h2>
            <div class="summary">Scans Ruby on Rails code for common security issues.</div>
            {brakeman_section}
        </section>

        <!-- Trivy Section -->
        <section class="section">
            <h2>🔍 Container & Dependency Scanning (Trivy)</h2>
            <div class="summary">Scans OS packages, base image, and configuration mismatches.</div>
            {trivy_section}
        </section>

        <!-- Semgrep Section -->
        <section class="section">
            <h2>🔬 Pattern Matching (Semgrep)</h2>
            <div class="summary">Scans code against Ruby and Rails security patterns.</div>
            {semgrep_section}
        </section>
    </div>
</body>
</html>"""

# Write HTML file
output_path = 'tmp/security_report.html'
with open(output_path, 'w') as f:
    f.write(html_content)

print(f'✓ HTML report written to {output_path}')
PYEOF

# Step 6 — Convert to PDF if Chrome is available
if [ -n "$CHROME" ]; then
  echo "📄 Converting to PDF..."
  "$CHROME" \
    --headless --disable-gpu --no-sandbox \
    --print-to-pdf="$OUTPUT_PDF" \
    --print-to-pdf-no-header \
    "file://$REPO_ROOT/$OUTPUT_HTML" 2>/dev/null || echo "⚠ PDF generation failed"

  if [ -f "$OUTPUT_PDF" ]; then
    echo "✓ PDF report written to $OUTPUT_PDF"
  fi
else
  echo "ℹ Skipping PDF generation (Chrome not found)"
fi

echo ""
echo "✅ Security report complete!"
echo "📂 HTML: $OUTPUT_HTML"
if [ -f "$OUTPUT_PDF" ]; then
  echo "📂 PDF:  $OUTPUT_PDF"
fi
