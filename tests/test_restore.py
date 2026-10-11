import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
FISH = shutil.which("fish")


class RestoreTests(unittest.TestCase):
    def test_plugin_restore_requires_applied_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                ["sh", str(ROOT / "scripts/restore-fish-plugins.sh")],
                env={**os.environ, "XDG_CONFIG_HOME": directory},
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Apply the dotfiles first", result.stderr)

    def test_plugin_restore_rejects_an_unrelated_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "fish"
            config.mkdir()
            (config / "fish_plugins").write_text("someone/unrelated-plugin\n")
            result = subprocess.run(
                ["sh", str(ROOT / "scripts/restore-fish-plugins.sh")],
                env={**os.environ, "XDG_CONFIG_HOME": directory},
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("differs from this repository", result.stderr)

    @unittest.skipUnless(FISH, "fish is required for the configuration smoke test")
    def test_local_download_directory_with_spaces(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "fish"
            shutil.copytree(ROOT / "home/dot_config/fish", config)
            downloads = root / "Downloads with spaces"
            downloads.mkdir()
            (config / "local.fish").write_text(
                f"set -gx DOTFILES_DOWNLOADS '{downloads}'\n"
            )
            result = subprocess.run(
                [FISH, "-i", "-c", 'cdwd; or exit 1; printf "%s" "$PWD"'],
                env={**os.environ, "XDG_CONFIG_HOME": directory, "TERM": "dumb"},
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(downloads), result.stdout)

    @unittest.skipUnless(FISH, "fish is required for the configuration smoke test")
    def test_prun_reports_missing_local_script(self):
        with tempfile.TemporaryDirectory() as directory:
            shutil.copytree(ROOT / "home/dot_config/fish", Path(directory) / "fish")
            env = {**os.environ, "XDG_CONFIG_HOME": directory, "TERM": "dumb"}
            env.pop("DOTFILES_PRUN_SCRIPT", None)
            result = subprocess.run(
                [FISH, "-i", "-c", "prun"], env=env, capture_output=True, text=True
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("DOTFILES_PRUN_SCRIPT", result.stderr)


if __name__ == "__main__":
    unittest.main()
