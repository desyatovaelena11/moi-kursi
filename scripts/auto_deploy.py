#!/usr/bin/env python3
"""
Moi-Kursi Auto Deployment Script
Полностью автоматическое развёртывание на сервер Beget
"""

import os
import sys
import json
import subprocess
import paramiko
from pathlib import Path
from dotenv import load_dotenv
import time

load_dotenv()

class AutoDeploy:
    def __init__(self):
        self.ssh_host = os.getenv('SSH_HOST')
        self.ssh_user = os.getenv('SSH_USER')
        self.ssh_password = os.getenv('SSH_PASSWORD')
        self.deploy_path = os.getenv('DEPLOY_PATH')
        self.db_user = os.getenv('DB_USER')
        self.db_pass = os.getenv('DB_PASS')
        self.db_name = os.getenv('DB_NAME')
        self.domain = os.getenv('FRONTEND_BASE_URL')

        self.ssh = None
        self.sftp = None

    def connect_ssh(self):
        """Подключиться по SSH"""
        print("🔐 Подключаюсь к серверу...")
        try:
            self.ssh = paramiko.SSHClient()
            self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.ssh.connect(
                self.ssh_host,
                username=self.ssh_user,
                password=self.ssh_password,
                timeout=10
            )
            self.sftp = self.ssh.open_sftp()
            print("✓ Подключение успешно")
            return True
        except Exception as e:
            print(f"✗ Ошибка подключения: {e}")
            return False

    def exec_command(self, command):
        """Выполнить команду на сервере"""
        try:
            stdin, stdout, stderr = self.ssh.exec_command(command)
            output = stdout.read().decode('utf-8')
            error = stderr.read().decode('utf-8')
            return output, error
        except Exception as e:
            print(f"✗ Ошибка выполнения команды: {e}")
            return None, str(e)

    def upload_files(self):
        """Загрузить файлы на сервер"""
        print("\n📤 Загружаю файлы на сервер...")

        # Создать директории
        print("Создаю директории...")
        self.exec_command(f"mkdir -p {self.deploy_path}/{{backend,frontend,docs}}")

        files_to_upload = [
            ('backend', f'{self.deploy_path}/backend'),
            ('frontend', f'{self.deploy_path}/frontend'),
            ('docs', f'{self.deploy_path}/docs'),
            ('.env', f'{self.deploy_path}/.env'),
        ]

        for src, dst in files_to_upload:
            self._upload_recursive(src, dst)
            print(f"✓ Загружено: {src}")

        print("✓ Все файлы загружены")

    def _upload_recursive(self, local_path, remote_path):
        """Рекурсивная загрузка папок"""
        try:
            if os.path.isfile(local_path):
                self.sftp.put(local_path, remote_path)
            else:
                try:
                    self.sftp.stat(remote_path)
                except IOError:
                    self.sftp.mkdir(remote_path)

                for item in os.listdir(local_path):
                    local_item = os.path.join(local_path, item)
                    remote_item = f"{remote_path}/{item}"
                    self._upload_recursive(local_item, remote_item)
        except Exception as e:
            print(f"⚠️  Ошибка загрузки {local_path}: {e}")

    def create_database(self):
        """Создать БД и пользователя"""
        print("\n🗄️  Создаю базу данных...")

        # Создать БД и пользователя
        mysql_commands = f"""
CREATE DATABASE IF NOT EXISTS {self.db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '{self.db_user}'@'localhost' IDENTIFIED BY '{self.db_pass}';
GRANT ALL PRIVILEGES ON {self.db_name}.* TO '{self.db_user}'@'localhost';
FLUSH PRIVILEGES;
"""

        try:
            # Сохранить команды в временный файл
            with open('/tmp/create_db.sql', 'w') as f:
                f.write(mysql_commands)

            # Загрузить на сервер
            self.sftp.put('/tmp/create_db.sql', f'{self.deploy_path}/create_db.sql')

            # Выполнить
            cmd = f"mysql -u root < {self.deploy_path}/create_db.sql"
            output, error = self.exec_command(cmd)

            if error and 'already exists' not in error:
                print(f"⚠️  {error}")
            else:
                print("✓ База данных создана")

            # Создать таблицы
            cmd = f"mysql -u {self.db_user} -p{self.db_pass} {self.db_name} < {self.deploy_path}/docs/DATABASE.sql"
            output, error = self.exec_command(cmd)

            if error and 'already exists' not in error:
                print(f"⚠️  {error}")
            else:
                print("✓ Таблицы созданы")

        except Exception as e:
            print(f"✗ Ошибка создания БД: {e}")

    def set_permissions(self):
        """Установить правильные права доступа"""
        print("\n🔒 Устанавливаю права доступа...")

        commands = [
            f"chmod -R 755 {self.deploy_path}",
            f"chmod 600 {self.deploy_path}/.env",
            f"chmod 644 {self.deploy_path}/backend/.htaccess",
        ]

        for cmd in commands:
            self.exec_command(cmd)

        print("✓ Права доступа установлены")

    def test_api(self):
        """Протестировать API"""
        print("\n✅ Тестирую API...")

        api_url = f"{os.getenv('API_BASE_URL')}/courses"

        try:
            import requests
            response = requests.get(api_url, timeout=10)
            if response.status_code == 200:
                print(f"✓ API доступен: {api_url}")
                return True
            else:
                print(f"⚠️  API вернул статус {response.status_code}")
                return False
        except Exception as e:
            print(f"⚠️  Не могу подключиться к API: {e}")
            return False

    def close(self):
        """Закрыть соединение"""
        if self.sftp:
            self.sftp.close()
        if self.ssh:
            self.ssh.close()

    def deploy(self):
        """Полное развёртывание"""
        print("=" * 50)
        print("🚀 MOI-KURSI AUTO DEPLOYMENT")
        print("=" * 50)

        # Проверить зависимости
        print("\n📦 Проверяю зависимости...")
        try:
            import paramiko
            print("✓ paramiko установлен")
        except ImportError:
            print("❌ paramiko не установлен")
            print("Установи: pip install paramiko")
            return False

        # Подключиться
        if not self.connect_ssh():
            return False

        try:
            # Выполнить шаги
            self.upload_files()
            self.create_database()
            self.set_permissions()
            time.sleep(2)
            self.test_api()

            print("\n" + "=" * 50)
            print("✅ РАЗВЁРТЫВАНИЕ ЗАВЕРШЕНО!")
            print("=" * 50)
            print(f"\n🌐 Твоя платформа доступна по адресу:")
            print(f"   Frontend: {os.getenv('FRONTEND_BASE_URL')}/frontend/")
            print(f"   API:      {os.getenv('API_BASE_URL')}/courses")
            print("\n📝 Следующие шаги:")
            print("1. Загрузи видео на Mail.ru Cloud")
            print("2. Выполни: python3 scripts/populate_database.py --file courses.csv")
            print("3. Открой платформу в браузере")

            return True

        finally:
            self.close()


def main():
    deployer = AutoDeploy()
    success = deployer.deploy()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
