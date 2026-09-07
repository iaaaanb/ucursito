"""Tests for the pure helpers in src/calendar_export.py."""

import subprocess
import sys
from pathlib import Path

from src.calendar_export import build_uid, parse_time_range

REPO_ROOT = Path(__file__).resolve().parent.parent


class TestParseTimeRange:
    def test_parses_a_plain_range(self):
        assert parse_time_range('(13:00 - 16:00)') == (13, 0, 16, 0)

    def test_finds_the_range_inside_a_longer_line(self):
        assert parse_time_range('Control 1, Sala B12 (9:30 - 11:00)') == (9, 30, 11, 0)

    def test_accepts_a_range_without_spaces(self):
        assert parse_time_range('(9:30-11:00)') == (9, 30, 11, 0)

    def test_returns_none_when_there_is_no_range(self):
        assert parse_time_range('Fecha por confirmar') is None


class TestBuildUid:
    EVENT = {'course': 'CC3001', 'title': 'Control 1', 'start_time': '2025-11-20 13:00'}

    def test_is_stable_within_a_process(self):
        assert build_uid('control', self.EVENT) == build_uid('control', self.EVENT)

    def test_changes_when_the_event_changes(self):
        otro = dict(self.EVENT, title='Control 2')
        assert build_uid('control', self.EVENT) != build_uid('control', otro)

    def test_changes_with_the_kind(self):
        assert build_uid('tarea', self.EVENT) != build_uid('tarea-late', self.EVENT)

    def test_keeps_the_kind_and_course_prefix(self):
        # scraper.get_existing_tareas_from_calendar filters previously exported
        # tareas by this prefix, so its shape is part of the contract.
        assert build_uid('tarea', self.EVENT).startswith('tarea-CC3001-')

    def test_is_stable_across_processes(self):
        """
        The regression guard. This used to be hash(str(event)), and string
        hashing is randomized per process, so every run produced new UIDs and
        re-importing the calendar duplicated every event instead of updating
        it. Two interpreters have to agree.
        """
        code = (
            f'import sys; sys.path.insert(0, {str(REPO_ROOT)!r});'
            'from src.calendar_export import build_uid;'
            f'print(build_uid("control", {self.EVENT!r}))'
        )
        uids = {
            subprocess.run(
                [sys.executable, '-c', code],
                capture_output=True, text=True, check=True,
            ).stdout.strip()
            for _ in range(2)
        }
        assert len(uids) == 1
