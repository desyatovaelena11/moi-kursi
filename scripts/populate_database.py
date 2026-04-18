#!/usr/bin/env python3
"""
Moi-Kursi Database Population Script

This script reads a CSV/JSON file with course structure and populates the database via API.

CSV Format:
    Course Name, Course Description, Section Name, Lesson Name, Video URL, Duration (seconds)

Usage:
    python3 populate_database.py --file courses.csv
    python3 populate_database.py --file courses.json
"""

import os
import sys
import json
import csv
import argparse
import requests
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

API_BASE_URL = os.getenv('API_BASE_URL', 'https://yourdomain.ru/backend/api/v1')

class DatabasePopulator:
    """Populates Moi-Kursi database via REST API"""

    def __init__(self, api_url):
        self.api_url = api_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({'Content-Type': 'application/json'})

    def test_connection(self):
        """Test API connection"""
        try:
            response = self.session.get(f"{self.api_url}/courses", timeout=5)
            if response.status_code in [200, 404]:
                print(f"✓ API connection successful: {self.api_url}")
                return True
            else:
                print(f"✗ API returned status {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ API connection failed: {e}")
            return False

    def create_course(self, name, description=''):
        """Create a new course"""
        try:
            data = {
                'name': name,
                'description': description
            }
            response = self.session.post(f"{self.api_url}/courses", json=data)
            result = response.json()

            if result.get('success'):
                course_id = result.get('data', {}).get('id')
                print(f"✓ Created course: {name} (ID: {course_id})")
                return course_id
            else:
                print(f"✗ Failed to create course: {result.get('error')}")
                return None

        except Exception as e:
            print(f"✗ Error creating course: {e}")
            return None

    def create_section(self, course_id, name, description=''):
        """Create a new section in a course"""
        try:
            data = {
                'course_id': course_id,
                'name': name,
                'description': description
            }
            response = self.session.post(f"{self.api_url}/sections", json=data)
            result = response.json()

            if result.get('success'):
                section_id = result.get('data', {}).get('id')
                print(f"  ✓ Created section: {name} (ID: {section_id})")
                return section_id
            else:
                print(f"  ✗ Failed to create section: {result.get('error')}")
                return None

        except Exception as e:
            print(f"  ✗ Error creating section: {e}")
            return None

    def create_lesson(self, section_id, name, video_url, duration=0, description=''):
        """Create a new lesson in a section"""
        try:
            data = {
                'section_id': section_id,
                'name': name,
                'description': description,
                'video_url': video_url,
                'duration': int(duration) if duration else 0
            }
            response = self.session.post(f"{self.api_url}/lessons", json=data)
            result = response.json()

            if result.get('success'):
                lesson_id = result.get('data', {}).get('id')
                print(f"    ✓ Created lesson: {name} (ID: {lesson_id})")
                return lesson_id
            else:
                print(f"    ✗ Failed to create lesson: {result.get('error')}")
                return None

        except Exception as e:
            print(f"    ✗ Error creating lesson: {e}")
            return None

    def populate_from_csv(self, csv_file):
        """Populate database from CSV file"""
        print(f"📂 Loading CSV file: {csv_file}")

        try:
            current_course_id = None
            current_course = None
            current_section_id = None
            current_section = None

            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                header = next(reader)

                # Expected columns
                if len(header) < 6:
                    print("✗ CSV must have at least 6 columns: Course, Description, Section, Lesson, Video URL, Duration")
                    return False

                for row in reader:
                    if len(row) < 6:
                        continue

                    course_name, course_desc, section_name, lesson_name, video_url, duration = row[:6]

                    # Skip empty rows
                    if not course_name.strip():
                        continue

                    # Create course if changed
                    if course_name != current_course:
                        current_course = course_name
                        current_course_id = self.create_course(course_name, course_desc)
                        current_section = None
                        current_section_id = None

                        if not current_course_id:
                            continue

                    # Create section if changed
                    if section_name != current_section:
                        current_section = section_name
                        current_section_id = self.create_section(current_course_id, section_name)

                        if not current_section_id:
                            continue

                    # Create lesson
                    self.create_lesson(
                        current_section_id,
                        lesson_name,
                        video_url,
                        duration
                    )

            print("\n✅ CSV import complete!")
            return True

        except Exception as e:
            print(f"✗ Error reading CSV: {e}")
            return False

    def populate_from_json(self, json_file):
        """Populate database from JSON file"""
        print(f"📂 Loading JSON file: {json_file}")

        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Expected structure:
            # [
            #   {
            #     "name": "Course Name",
            #     "description": "...",
            #     "sections": [
            #       {
            #         "name": "Section Name",
            #         "lessons": [
            #           {
            #             "name": "Lesson Name",
            #             "video_url": "...",
            #             "duration": 600
            #           }
            #         ]
            #       }
            #     ]
            #   }
            # ]

            if isinstance(data, dict):
                data = [data]

            for course_data in data:
                course_name = course_data.get('name')
                course_desc = course_data.get('description', '')

                print(f"\n📚 Course: {course_name}")
                course_id = self.create_course(course_name, course_desc)

                if not course_id:
                    continue

                sections = course_data.get('sections', [])
                for section_data in sections:
                    section_name = section_data.get('name')
                    section_desc = section_data.get('description', '')

                    section_id = self.create_section(course_id, section_name, section_desc)

                    if not section_id:
                        continue

                    lessons = section_data.get('lessons', [])
                    for lesson_data in lessons:
                        lesson_name = lesson_data.get('name')
                        video_url = lesson_data.get('video_url')
                        duration = lesson_data.get('duration', 0)
                        lesson_desc = lesson_data.get('description', '')

                        self.create_lesson(
                            section_id,
                            lesson_name,
                            video_url,
                            duration,
                            lesson_desc
                        )

            print("\n✅ JSON import complete!")
            return True

        except json.JSONDecodeError:
            print("✗ Invalid JSON file")
            return False
        except Exception as e:
            print(f"✗ Error reading JSON: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Populate Moi-Kursi database from CSV or JSON'
    )
    parser.add_argument('--file', required=True, help='CSV or JSON file with courses')
    parser.add_argument('--api', default=API_BASE_URL, help='API base URL')
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"✗ File not found: {args.file}")
        sys.exit(1)

    # Initialize populator
    populator = DatabasePopulator(args.api)

    # Test connection
    if not populator.test_connection():
        print("\n❌ Cannot connect to API. Check API_BASE_URL in .env")
        sys.exit(1)

    print(f"\n📝 Populating database from: {args.file}\n")

    # Determine file type and populate
    if args.file.endswith('.csv'):
        success = populator.populate_from_csv(args.file)
    elif args.file.endswith('.json'):
        success = populator.populate_from_json(args.file)
    else:
        print("✗ File must be CSV or JSON")
        sys.exit(1)

    if success:
        print(f"\n✅ Database populated successfully!")
        print(f"\n🌐 Access your platform at: {args.api.replace('/api/v1', '')}")
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
