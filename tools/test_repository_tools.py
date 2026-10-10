#!/usr/bin/env python3
"""Contract tests for repository import and release-support tooling."""

from __future__ import annotations

import os
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock

import build_user_release as player_builder
import import_source_archive as importer
import validate_user_release as player_validator


class SourceArchiveTests(unittest.TestCase):
    def make_source_tree(self, root: Path, version: str = "4.1") -> Path:
        source = root / importer.ROOT_NAME
        for relative in sorted(importer.REQUIRED_SOURCE_FILES):
            path = source / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            if relative == "VERSION.txt":
                path.write_text(version + "\n", encoding="utf-8")
            else:
                path.write_bytes(b"placeholder\n")
        patch = source / "tools" / "player_release" / "00-runtime.patch"
        patch.parent.mkdir(parents=True, exist_ok=True)
        patch.write_text("placeholder\n", encoding="utf-8")
        return source

    def write_archive(self, repository: Path, name: str, source: Path) -> Path:
        archive_path = repository / name
        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(source.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(source.parent).as_posix())
        return archive_path

    def test_imports_valid_versioned_source_and_removes_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repository = base / "repo"
            staging = base / "staging"
            repository.mkdir()
            source = self.make_source_tree(staging, "4.1")
            archive = self.write_archive(
                repository,
                "Metamorph-Creative-Menu-v4.1.zip",
                source,
            )
            old_target = repository / importer.ROOT_NAME
            old_target.mkdir()
            (old_target / "obsolete.txt").write_text("old", encoding="utf-8")

            changed, version = importer.import_archive(repository)

            self.assertTrue(changed)
            self.assertEqual(version, "4.1")
            self.assertFalse(archive.exists())
            self.assertFalse((old_target / "obsolete.txt").exists())
            self.assertEqual((old_target / "VERSION.txt").read_text().strip(), "4.1")
            self.assertTrue((old_target / "tests" / "run_all.py").is_file())

    def test_rejects_archive_major_version_mismatch_without_replacing_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            repository = base / "repo"
            staging = base / "staging"
            repository.mkdir()
            source = self.make_source_tree(staging, "5.0")
            self.write_archive(repository, "Metamorph-Creative-Menu-v4.zip", source)
            target = repository / importer.ROOT_NAME
            target.mkdir()
            marker = target / "keep.txt"
            marker.write_text("keep", encoding="utf-8")

            with self.assertRaisesRegex(RuntimeError, "archive name says v4"):
                importer.import_archive(repository)

            self.assertEqual(marker.read_text(encoding="utf-8"), "keep")

    def test_ignores_modworkshop_player_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repository = Path(temp)
            (repository / "Metamorph-Creative-Menu-v4-Modworkshop.zip").write_bytes(b"not a source zip")
            archive, match = importer.discover_archive(repository)
            self.assertIsNone(archive)
            self.assertIsNone(match)

    def test_rejects_path_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repository = Path(temp)
            archive_path = repository / "Metamorph-Creative-Menu-v4.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{importer.ROOT_NAME}/../escape.txt", "bad")

            with zipfile.ZipFile(archive_path) as archive:
                with self.assertRaisesRegex(RuntimeError, "unsafe archive path"):
                    importer.validate_members(archive)

    def test_rejects_case_colliding_paths(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repository = Path(temp)
            archive_path = repository / "Metamorph-Creative-Menu-v4.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr(f"{importer.ROOT_NAME}/Files/A.lua", "return 1\n")
                archive.writestr(f"{importer.ROOT_NAME}/files/a.lua", "return 2\n")

            with zipfile.ZipFile(archive_path) as archive:
                with self.assertRaisesRegex(RuntimeError, "case-colliding archive path"):
                    importer.validate_members(archive)

    def test_main_reports_no_change_without_archive(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            with mock.patch("pathlib.Path.cwd", return_value=Path(temp)):
                with mock.patch.dict(os.environ, {}, clear=False):
                    self.assertEqual(importer.main(), 0)


class PlayerReleaseToolTests(unittest.TestCase):
    PATCH_TEXT = """--- metamorph_creative_menu/example.txt
+++ metamorph_creative_menu/example.txt
@@ -1 +1 @@
-development
+player
"""

    def prepare_patch_case(self, root: Path, staged_text: str) -> tuple[Path, Path, Path]:
        source = root / "source" / player_builder.ROOT_NAME
        patch_dir = source / "tools" / "player_release"
        patch_dir.mkdir(parents=True)
        (patch_dir / "00-example.patch").write_text(self.PATCH_TEXT, encoding="utf-8")

        stage = root / "stage"
        target = stage / player_builder.ROOT_NAME
        target.mkdir(parents=True)
        staged_file = target / "example.txt"
        staged_file.write_text(staged_text, encoding="utf-8")
        return source, stage, staged_file

    @unittest.skipUnless(player_builder.shutil.which("patch"), "patch utility is required")
    def test_release_patch_applies_forward(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            source, stage, staged_file = self.prepare_patch_case(Path(temp), "development\n")
            player_builder.apply_release_patches(source, stage)
            self.assertEqual(staged_file.read_text(encoding="utf-8"), "player\n")

    @unittest.skipUnless(player_builder.shutil.which("patch"), "patch utility is required")
    def test_release_patch_skips_when_cleanup_is_already_integrated(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            source, stage, staged_file = self.prepare_patch_case(Path(temp), "player\n")
            player_builder.apply_release_patches(source, stage)
            self.assertEqual(staged_file.read_text(encoding="utf-8"), "player\n")

    def test_lua_comment_detection_ignores_double_dash_inside_strings(self) -> None:
        self.assertFalse(player_validator.contains_lua_comment('return "https://example.invalid/a--b"\n'))
        self.assertFalse(player_validator.contains_lua_comment("return '--not-a-comment'\n"))

    def test_lua_comment_detection_finds_line_and_block_comments(self) -> None:
        self.assertTrue(player_validator.contains_lua_comment("local x = 1 -- comment\n"))
        self.assertTrue(player_validator.contains_lua_comment("--[[ block ]]\nreturn 1\n"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
