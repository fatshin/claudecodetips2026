#!/usr/bin/env python3
"""
PreToolUse hook: 機密ファイルへのRead/Edit/Writeをブロック。
settings.jsonのdenyルールが効かないバグ（CVE級の懸念あり）の回避策。
公式GitHub issue #6699 を参照。
"""
import json
import sys
from pathlib import Path

# ブロック対象パターン（ファイル名 or 拡張子）
SENSITIVE_NAMES = {
    ".env", ".env.local", ".env.production", ".env.development",
    "credentials.json", "credentials", "secrets.json", "secrets.yaml",
    "id_rsa", "id_ed25519", "id_dsa", ".npmrc", ".pypirc", ".dockercfg",
    "config.json",  # 注意: 一般的すぎるなら除外
}
SENSITIVE_EXT = {".pem", ".key", ".p12", ".pfx", ".keystore"}
SENSITIVE_DIR_KEYS = {"secrets", ".aws", ".ssh", ".gnupg"}

def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_input = data.get("tool_input", {}) or {}
    file_path_str = tool_input.get("file_path") or tool_input.get("path")
    if not file_path_str:
        sys.exit(0)

    p = Path(file_path_str)
    name = p.name.lower()
    ext = p.suffix.lower()
    parts = {part.lower() for part in p.parts}

    blocked = (
        name in SENSITIVE_NAMES
        or ext in SENSITIVE_EXT
        or any(k in parts for k in SENSITIVE_DIR_KEYS)
        or name.startswith(".env.")
    )
    if not blocked:
        sys.exit(0)

    decision = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"SECURITY_POLICY_VIOLATION: '{p.name}' は機密ファイル扱いでブロック。"
                "認証情報は環境変数経由か、必要箇所のみ別途共有。"
            ),
        }
    }
    print(json.dumps(decision))
    sys.exit(0)

if __name__ == "__main__":
    main()
