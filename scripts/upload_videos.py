#!/usr/bin/env python3
"""
Moi-Kursi Video Upload Script for Mail.ru Cloud

Usage:
    python3 upload_videos.py

Before running:
    1. Create .env file with MAILRU_EMAIL and MAILRU_PASSWORD
    2. Create structure.csv with video files and their metadata
"""

import os
import sys
import json
import requests
from pathlib import Path
from dotenv import load_dotenv
import argparse

# Load environment variables
load_dotenv()

MAILRU_EMAIL = os.getenv('MAILRU_EMAIL')
MAILRU_PASSWORD = os.getenv('MAILRU_PASSWORD')
LOCAL_VIDEOS_PATH = os.getenv('LOCAL_VIDEOS_PATH', './videos')

class MailRuCloudUploader:
    """Uploads videos to Mail.ru Cloud and retrieves direct links"""

    def __init__(self, email, password):
        self.email = email
        self.password = password
        self.session = requests.Session()
        self.token = None
        self.auth()

    def auth(self):
        """Authenticate with Mail.ru Cloud"""
        print(f"🔐 Authenticating as {self.email}...")
        try:
            # Mail.ru Cloud API endpoint
            url = "https://cloud.mail.ru/api/v2/login"
            data = {
                "email": self.email,
                "password": self.password
            }

            response = self.session.post(url, json=data, timeout=10)
            response.raise_for_status()

            result = response.json()
            if result.get('status') == 'success':
                self.token = result.get('body', {}).get('token')
                print("✓ Authentication successful")
                return True
            else:
                print(f"✗ Authentication failed: {result.get('body', {}).get('error')}")
                return False

        except Exception as e:
            print(f"✗ Error during authentication: {e}")
            return False

    def create_folder(self, path):
        """Create folder in Mail.ru Cloud"""
        print(f"📁 Creating folder: {path}")
        try:
            url = "https://cloud.mail.ru/api/v2/folder/add"
            params = {
                "token": self.token,
                "path": path
            }
            response = self.session.post(url, params=params, timeout=10)
            result = response.json()
            return result.get('status') == 'success'
        except Exception as e:
            print(f"⚠️  Error creating folder: {e}")
            return False

    def upload_file(self, local_path, remote_path):
        """Upload file to Mail.ru Cloud"""
        print(f"📤 Uploading: {local_path}")

        try:
            file_size = os.path.getsize(local_path)
            file_size_mb = file_size / (1024 * 1024)

            if file_size_mb > 2048:  # 2GB limit for free tier
                print(f"⚠️  File too large ({file_size_mb:.1f}MB). Skipping.")
                return None

            # Upload file
            url = "https://cloud.mail.ru/api/v2/file/add"
            params = {
                "token": self.token,
                "path": remote_path
            }

            with open(local_path, 'rb') as f:
                files = {'file': f}
                response = self.session.post(url, params=params, files=files, timeout=300)

            result = response.json()

            if result.get('status') == 'success':
                print(f"✓ Uploaded: {remote_path}")
                return remote_path
            else:
                print(f"✗ Upload failed: {result.get('body', {}).get('error')}")
                return None

        except Exception as e:
            print(f"✗ Error uploading file: {e}")
            return None

    def get_public_link(self, path):
        """Get public link for uploaded file"""
        try:
            url = "https://cloud.mail.ru/api/v2/file/publish"
            params = {
                "token": self.token,
                "path": path
            }
            response = self.session.post(url, params=params, timeout=10)
            result = response.json()

            if result.get('status') == 'success':
                link = result.get('body', {}).get('link')
                print(f"🔗 Public link: {link}")
                return link
            else:
                print(f"⚠️  Could not get public link for {path}")
                return None

        except Exception as e:
            print(f"✗ Error getting public link: {e}")
            return None

    def upload_folder(self, local_folder, remote_folder="/Курсы"):
        """Upload entire folder structure"""
        results = {}

        for root, dirs, files in os.walk(local_folder):
            for file in files:
                if file.endswith(('.mp4', '.mov', '.avi', '.mkv')):
                    local_path = os.path.join(root, file)
                    relative_path = os.path.relpath(local_path, local_folder)
                    remote_path = f"{remote_folder}/{relative_path}".replace('\\', '/')

                    # Create folder structure
                    remote_dir = os.path.dirname(remote_path)
                    self.create_folder(remote_dir)

                    # Upload file
                    uploaded = self.upload_file(local_path, remote_path)

                    # Get public link
                    if uploaded:
                        link = self.get_public_link(remote_path)
                        results[relative_path] = {
                            'local': local_path,
                            'remote': remote_path,
                            'link': link
                        }

        return results


def main():
    parser = argparse.ArgumentParser(description='Upload videos to Mail.ru Cloud')
    parser.add_argument('--folder', default=LOCAL_VIDEOS_PATH, help='Local folder with videos')
    parser.add_argument('--output', default='video_links.json', help='Output file with links')
    args = parser.parse_args()

    if not MAILRU_EMAIL or not MAILRU_PASSWORD:
        print("❌ Error: MAILRU_EMAIL and MAILRU_PASSWORD not set in .env")
        print("Please fill .env file with your Mail.ru Cloud credentials")
        sys.exit(1)

    if not os.path.exists(args.folder):
        print(f"❌ Error: Folder not found: {args.folder}")
        sys.exit(1)

    # Initialize uploader
    uploader = MailRuCloudUploader(MAILRU_EMAIL, MAILRU_PASSWORD)

    if not uploader.token:
        print("❌ Authentication failed")
        sys.exit(1)

    # Upload videos
    print(f"\n📚 Starting upload from: {args.folder}\n")
    results = uploader.upload_folder(args.folder)

    # Save results
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Upload complete!")
    print(f"📄 Results saved to: {args.output}")
    print(f"📊 Uploaded {len(results)} files")

    # Show summary
    print("\n" + "="*50)
    print("Video Links Summary")
    print("="*50)
    for filename, data in results.items():
        if data['link']:
            print(f"\n📹 {filename}")
            print(f"   Link: {data['link']}")


if __name__ == '__main__':
    main()
