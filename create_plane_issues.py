#!/usr/bin/env python3
"""
FlowMaster Plane Issue Creator
Creates epics, user stories, infrastructure tasks, and architecture fixes in Plane
"""

import requests
import json
from typing import Dict, List, Optional

# Plane Configuration
PLANE_URL = "http://65.21.153.235:8012"
WORKSPACE_SLUG = "flowmaster"
PROJECT_SLUG = "FM"
API_KEY = "plane_api_b91c8c1ffd1448d0bd0130bbc279b124"

# Headers for API requests
HEADERS = {
    "Content-Type": "application/json",
    "X-Api-Key": API_KEY
}

print("Script created - run with: python3 create_plane_issues.py")
