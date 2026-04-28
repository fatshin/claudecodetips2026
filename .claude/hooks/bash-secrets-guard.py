#!/usr/bin/env python3
"""
PreToolUse hook: Bash経由での機密ファイル読み取りをブロック。
protect-secrets.py がRead/Edit/Writeのみ対象のため、
Bashツール（cat, grep, rg等）による迂回を防止する。
"""

import json
import re
import sys


SENSITIVE_PATTERNS = [
    r"\.env\b",
    r"\.env\.",
    r"credentials",
    r"secrets\.json",
    r"secrets\.yaml",
    r"id_rsa",
    r"id_ed25519",
    r"id_dsa",
    r"\.pem\b",
    r"\.key\b",
    r"\.p12\b",
    r"\.pfx\b",
    r"\.npmrc\b",
    r"\.pypirc\b",
    r"\.netrc\b",
    r"\.dockercfg",
    r"kubeconfig",
    r"\.aws/",
    r"\.ssh/",
    r"\.gnupg/",
    r"terraform\.tfstate",
]

READ_COMMANDS = re.compile(
    r"\b(cat|head|tail|less|more|bat|rg|grep|egrep|fgrep|awk|sed|sort|strings|xxd|hexdump|od)\b"
)

COMBINED = re.compile("|".join(SENSITIVE_PATTERNS), re.IGNORECASE)

SAFE_PREFIXES = re.compile(
    r"^\s*(git\s|echo\s|printf\s|"
    r"bash\s+-n\s|shellcheck\s|find\s|ls\s|wc\s|mkdir\s|chmod\s|touch\s)"
)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_input = data.get("tool_input", {}) or {}
    command = tool_input.get("command", "")
    if not command:
        sys.exit(0)

    if re.match(r"^\s*git\s", command):
        sys.exit(0)

    has_sensitive = COMBINED.search(command)

    if has_sensitive and (
        READ_COMMANDS.search(command)
        or re.search(r"\b(python3?|node|ruby)\b.*(-[ce]\s|exec)", command)
    ):
        decision = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    "SECURITY_POLICY_VIOLATION: Bashコマンドで機密ファイルへのアクセスを検知。"
                    "機密情報は環境変数経由で取得すること。"
                ),
            }
        }
        print(json.dumps(decision))

    sys.exit(0)


if __name__ == "__main__":
    main()
