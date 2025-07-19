#!/usr/bin/env python3
"""
Direct upload script for Hugging Face Spaces
This bypasses Git and uploads files directly via the Hugging Face API
"""

import os
from pathlib import Path
from huggingface_hub import HfApi, login
import time

def upload_to_huggingface_spaces():
    """Upload entire folder to Hugging Face Spaces"""
    
    # Configuration
    REPO_ID = "Njoguni/my-medical-inventory-api"
    REPO_TYPE = "space"  # This is a Space, not a model
    FOLDER_PATH = "."  # Current directory (your backend folder)
    
    # Files/folders to ignore during upload
    IGNORE_PATTERNS = [
        ".git",
        ".git/*",
        "__pycache__",
        "__pycache__/*",
        "*.pyc",
        "*.pyo", 
        ".pytest_cache",
        ".pytest_cache/*",
        "venv",
        "venv/*",
        "env", 
        "env/*",
        ".env",
        ".vscode",
        ".idea",
        "*.log",
        "ngrok.exe",  # Remove this Windows executable
        "paste.txt",  # Your git log file
    ]
    
    print("🚀 Starting direct upload to Hugging Face Spaces...")
    print(f"Repository: {REPO_ID}")
    print(f"Source folder: {os.path.abspath(FOLDER_PATH)}")
    
    try:
        # Initialize the API
        api = HfApi()
        
        # Login (you'll be prompted for your token)
        print("\n🔐 Please provide your Hugging Face token...")
        print("Get your token from: https://huggingface.co/settings/tokens")
        login()
        
        # Check if repository exists, if not create it
        try:
            repo_info = api.repo_info(repo_id=REPO_ID, repo_type=REPO_TYPE)
            print(f"✅ Repository {REPO_ID} exists")
        except Exception as e:
            print(f"❌ Repository doesn't exist or can't access it: {e}")
            print("Please create the Space manually on Hugging Face first")
            return False
        
        # Get list of files to upload
        print("\n📁 Scanning files to upload...")
        folder_path = Path(FOLDER_PATH)
        all_files = []
        
        for file_path in folder_path.rglob("*"):
            if file_path.is_file():
                relative_path = file_path.relative_to(folder_path)
                # Check if file should be ignored
                should_ignore = False
                for pattern in IGNORE_PATTERNS:
                    if pattern in str(relative_path) or str(relative_path).endswith(pattern.replace("*", "")):
                        should_ignore = True
                        break
                
                if not should_ignore:
                    all_files.append(str(relative_path))
        
        print(f"Found {len(all_files)} files to upload")
        
        # Show large files (>100MB) for confirmation
        large_files = []
        for file_path in all_files:
            full_path = folder_path / file_path
            size_mb = full_path.stat().st_size / (1024 * 1024)
            if size_mb > 100:
                large_files.append((file_path, size_mb))
        
        if large_files:
            print("\n⚠️ Large files detected (>100MB):")
            for file_path, size_mb in large_files:
                print(f"  - {file_path}: {size_mb:.1f} MB")
        
        # Confirm upload
        response = input(f"\n🤔 Upload {len(all_files)} files to {REPO_ID}? (y/N): ")
        if response.lower() != 'y':
            print("❌ Upload cancelled")
            return False
        
        # Upload the folder
        print("\n⬆️ Starting upload... This may take a while for large files.")
        print("The upload will continue even if individual files fail.")
        
        start_time = time.time()
        
        result = api.upload_folder(
            folder_path=FOLDER_PATH,
            repo_id=REPO_ID,
            repo_type=REPO_TYPE,
            ignore_patterns=IGNORE_PATTERNS,
            commit_message="Direct upload via Hugging Face Hub API",
            create_pr=False,  # Upload directly to main branch
        )
        
        end_time = time.time()
        upload_time = end_time - start_time
        
        print(f"\n🎉 Upload completed successfully!")
        print(f"⏱️ Time taken: {upload_time:.1f} seconds ({upload_time/60:.1f} minutes)")
        print(f"🔗 Your Space: https://huggingface.co/spaces/{REPO_ID}")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        print("\nTroubleshooting tips:")
        print("1. Make sure your Hugging Face token has write permissions")
        print("2. Check that the repository exists and you have access")
        print("3. Ensure you have a stable internet connection")
        print("4. Try uploading smaller batches of files")
        return False

def upload_specific_files():
    """Upload specific important files first"""
    
    REPO_ID = "Njoguni/my-medical-inventory-api"
    REPO_TYPE = "space"
    
    # Critical files to upload first
    critical_files = [
        "app.py",
        "requirements.txt", 
        "Dockerfile",
        "README.md",  # If it exists
        ".gitignore",
    ]
    
    print("🎯 Uploading critical files first...")
    
    try:
        api = HfApi()
        login()
        
        for file_path in critical_files:
            if os.path.exists(file_path):
                print(f"⬆️ Uploading {file_path}...")
                api.upload_file(
                    path_or_fileobj=file_path,
                    path_in_repo=file_path,
                    repo_id=REPO_ID,
                    repo_type=REPO_TYPE,
                    commit_message=f"Upload {file_path}"
                )
                print(f"✅ {file_path} uploaded successfully")
            else:
                print(f"⚠️ {file_path} not found, skipping")
                
        print(f"\n🎉 Critical files uploaded! Check: https://huggingface.co/spaces/{REPO_ID}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to upload critical files: {e}")
        return False

if __name__ == "__main__":
    print("Hugging Face Direct Upload Tool")
    print("=" * 40)
    
    choice = input("Choose upload method:\n1. Upload all files (recommended)\n2. Upload critical files only\nEnter choice (1 or 2): ")
    
    if choice == "2":
        upload_specific_files()
    else:
        upload_to_huggingface_spaces()