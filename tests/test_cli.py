from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


def run_cli(*args: str, cwd: Path) -> dict:
    result = subprocess.run(
        [sys.executable, "-m", "codex_hot_media", "--json", *args],
        cwd=cwd,
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


class CliTests(unittest.TestCase):
    def test_doctor(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = run_cli("doctor", cwd=Path(temp_dir))
        self.assertEqual(payload["status"], "ok")
        self.assertFalse(payload["auth_required"])

    def test_agent_guide(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = run_cli("agent-guide", cwd=Path(temp_dir))
        self.assertEqual(payload["status"], "ok")
        self.assertIn("codex_skill", payload["agent_integrations"])
        self.assertIn("claude_code_command", payload["agent_integrations"])
        self.assertIn("ourongxing/newsnow", payload["network_projects"])
        self.assertIn("ourongxing/newsnow-mcp-server", payload["network_projects"])

    def test_sources_include_network_projects(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = run_cli("sources", cwd=Path(temp_dir))
        projects = {item["project"] for item in payload["source_catalog"]}
        self.assertIn("ourongxing/newsnow", projects)
        self.assertIn("ourongxing/newsnow-mcp-server", projects)
        self.assertIn("joyce677/TrendRadar", projects)
        self.assertIn("one-box-u/openclaw-daily-hot-news", projects)

    def test_manual_import_plan_pack_dashboard(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            tmp_path = Path(temp_dir)
            source = tmp_path / "hot.txt"
            source.write_text("AI工具省钱清单\n短视频前5秒钩子模板\n账号诊断流程\n", encoding="utf-8")

            imported = run_cli(
                "import-text",
                "--input",
                str(source),
                "--source-name",
                "manual",
                "--out-dir",
                str(tmp_path / "data"),
                "--prefix",
                "manual_hot",
                cwd=tmp_path,
            )
            self.assertEqual(imported["count"], 3)

            planned = run_cli(
                "plan",
                "--input",
                imported["latest_json"],
                "--top-n",
                "2",
                "--out-dir",
                str(tmp_path / "out"),
                cwd=tmp_path,
            )
            self.assertEqual(planned["count"], 2)

            packed = run_cli(
                "pack",
                "--plan",
                planned["latest_json"],
                "--out-dir",
                str(tmp_path / "out"),
                cwd=tmp_path,
            )
            self.assertEqual(packed["count"], 2)
            self.assertTrue(Path(packed["publish_log_template"]).exists())

            dashboard = run_cli(
                "dashboard",
                "--plan",
                planned["latest_json"],
                "--pack",
                packed["publish_pack_json"],
                "--out",
                str(tmp_path / "dashboard.html"),
                cwd=tmp_path,
            )
            self.assertEqual(dashboard["status"], "ok")
            self.assertTrue(Path(dashboard["dashboard_html"]).exists())


if __name__ == "__main__":
    unittest.main()
