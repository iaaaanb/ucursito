"""
Global configuration for U-Cursos Scraper.
Centralized location for all configuration settings.
"""

# Personal, optional mapping from a course's full name to a short one, used to
# keep calendar event titles readable. A course that is not listed here simply
# keeps its full name, so this dict can be emptied or replaced with your own.
#
# The abbreviations are used ONLY in calendar event titles, never in download
# folder names or category tags, which always keep the full course name.
COURSE_ABBREVIATIONS = {
    "Análisis Avanzado de Algoritmos": "Análisis",
    "Bases de Datos": "Batos",
    "Matemáticas Discretas para la Computación": "Discretas",
    "Metodologías de Diseño y Programación": "Memes",
    "Programación de Software de Sistemas": "PSS",
}


# Default download directory
DOWNLOAD_DIR = "downloads"


# Add other global configuration here in the future
# Examples:
# - Browser settings
# - Timeout values
# - File organization preferences
# - Logging configuration
