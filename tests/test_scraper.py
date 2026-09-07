"""
Tests for the pure helpers in src/scraper.py.

These need no browser and no U-Cursos session: they cover the two places where
a silent mistake would misfile every download.
"""

import pytest

from src import scraper
from src.scraper import get_course_folder_name, sanitize_filename


class TestSanitizeFilename:
    def test_replaces_characters_the_filesystem_rejects(self):
        assert sanitize_filename('a<b>c:d"e/f\\g|h?i*j') == 'a_b_c_d_e_f_g_h_i_j'

    def test_turns_spaces_into_dashes(self):
        assert sanitize_filename('Clase 01 Introduccion.pdf') == 'Clase-01-Introduccion.pdf'

    def test_leaves_an_already_clean_name_alone(self):
        assert sanitize_filename('tarea-1.pdf') == 'tarea-1.pdf'

    def test_surrounding_spaces_end_up_as_dashes(self):
        # strip() runs after the replacement, so it never sees a space: the
        # dashes that took their place survive. Documented, not endorsed.
        assert sanitize_filename('  informe  ') == '--informe--'


class TestGetCourseFolderName:
    """
    Folder naming follows a priority order, and the point of these tests is
    that re-running the scraper keeps writing into the folder it used last
    time instead of creating a second one next to it.
    """

    @pytest.fixture(autouse=True)
    def abbreviations(self, monkeypatch):
        # Not the real mapping from config.py: that one is personal and would
        # tie these tests to whatever courses the author was taking.
        monkeypatch.setattr(scraper, 'COURSE_ABBREVIATIONS', {'Bases de Datos': 'Batos'})

    def test_uses_the_abbreviation_for_a_new_folder(self, tmp_path):
        assert get_course_folder_name({'name': 'Bases de Datos'}, tmp_path) == 'Batos'

    def test_falls_back_to_the_full_name_when_unmapped(self, tmp_path):
        assert get_course_folder_name({'name': 'Redes'}, tmp_path) == 'Redes'

    def test_sanitizes_the_full_name(self, tmp_path):
        assert get_course_folder_name({'name': 'Redes y Comunicaciones'}, tmp_path) == 'Redes-y-Comunicaciones'

    def test_reuses_an_existing_abbreviated_folder(self, tmp_path):
        (tmp_path / 'Batos').mkdir()
        assert get_course_folder_name({'name': 'Bases de Datos'}, tmp_path) == 'Batos'

    def test_an_existing_full_name_folder_beats_the_abbreviation(self, tmp_path):
        (tmp_path / 'Bases-de-Datos').mkdir()
        assert get_course_folder_name({'name': 'Bases de Datos'}, tmp_path) == 'Bases-de-Datos'

    def test_rejects_something_that_is_not_a_course(self, tmp_path):
        with pytest.raises(TypeError):
            get_course_folder_name('Bases de Datos', tmp_path)

    def test_rejects_a_course_without_a_name(self, tmp_path):
        with pytest.raises(KeyError):
            get_course_folder_name({'code': 'CC3001'}, tmp_path)
