#!/usr/bin/env python3
"""
MCP Documentation Manager

This script helps manage the MCP documentation system by providing tools for:
- Validating documentation structure and front matter
- Checking cross-references
- Generating documentation reports
- Assisting with migration tasks
- Updating document status

Usage:
  python doc-manager.py [command] [options]

Commands:
  validate      Validate documentation structure and front matter
  check-links   Check for broken cross-references
  report        Generate documentation status report
  migrate       Assist with documentation migration
  update-status Update document status
  help          Show this help message
"""

import os
import re
import sys
import yaml
import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple, Any

# Configuration
DOCS_ROOT = Path(os.path.dirname(os.path.abspath(__file__))).parent
FRONT_MATTER_PATTERN = re.compile(r'^---\s*\n(.*?)\n---\s*\n', re.DOTALL)
LINK_PATTERN = re.compile(r'\[([^\]]+)\]\((/docs/[^)]+)\)')
STATUS_EMOJI = {
    "Active": "🟢",
    "Draft": "🟡",
    "Review": "🟠",
    "Outdated": "🔴",
    "Archived": "⚫"
}

class DocManager:
    """Documentation management tools for MCP project."""
    
    def __init__(self, docs_root: Path):
        self.docs_root = docs_root
        self.docs = {}
        self.scan_documents()
    
    def scan_documents(self) -> None:
        """Scan all markdown documents in the docs directory."""
        print(f"Scanning documents in {self.docs_root}...")
        
        for path in self.docs_root.glob('**/*.md'):
            # Get relative path from docs root
            rel_path = path.relative_to(self.docs_root)
            doc_path = f"/docs/{rel_path}"
            
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract front matter
            front_matter = self.extract_front_matter(content)
            
            # Extract links
            links = self.extract_links(content)
            
            self.docs[doc_path] = {
                'path': path,
                'rel_path': rel_path,
                'front_matter': front_matter,
                'links': links,
                'content': content
            }
        
        print(f"Found {len(self.docs)} documents")
    
    def extract_front_matter(self, content: str) -> Dict:
        """Extract and parse front matter from document content."""
        match = FRONT_MATTER_PATTERN.match(content)
        if match:
            try:
                return yaml.safe_load(match.group(1))
            except yaml.YAMLError:
                return {}
        return {}
    
    def extract_links(self, content: str) -> List[str]:
        """Extract document links from content."""
        links = []
        for match in LINK_PATTERN.finditer(content):
            link = match.group(2)
            links.append(link)
        return links
    
    def validate(self, verbose: bool = False) -> bool:
        """Validate documentation structure and front matter."""
        print("Validating documentation...")
        
        valid = True
        required_fields = ['title', 'status', 'version', 'date_created', 'last_updated', 'contributors', 'tags']
        
        for doc_path, doc in self.docs.items():
            fm = doc['front_matter']
            
            # Check for front matter
            if not fm:
                print(f"ERROR: {doc_path} - Missing front matter")
                valid = False
                continue
            
            # Check required fields
            for field in required_fields:
                if field not in fm:
                    print(f"ERROR: {doc_path} - Missing required field: {field}")
                    valid = False
            
            # Check status value
            if 'status' in fm and fm['status'] not in STATUS_EMOJI:
                print(f"ERROR: {doc_path} - Invalid status: {fm['status']}")
                valid = False
            
            # Check version format
            if 'version' in fm:
                if not re.match(r'^\d+\.\d+(\.\d+)?$', str(fm['version'])):
                    print(f"ERROR: {doc_path} - Invalid version format: {fm['version']}")
                    valid = False
            
            # Check date formats
            for date_field in ['date_created', 'last_updated']:
                if date_field in fm:
                    try:
                        datetime.datetime.strptime(str(fm[date_field]), '%Y-%m-%d')
                    except ValueError:
                        print(f"ERROR: {doc_path} - Invalid date format in {date_field}: {fm[date_field]}")
                        valid = False
            
            # Check contributors is a list
            if 'contributors' in fm and not isinstance(fm['contributors'], list):
                print(f"ERROR: {doc_path} - Contributors must be a list")
                valid = False
            
            # Check tags is a list
            if 'tags' in fm and not isinstance(fm['tags'], list):
                print(f"ERROR: {doc_path} - Tags must be a list")
                valid = False
            
            if verbose and valid:
                print(f"OK: {doc_path}")
        
        if valid:
            print("✅ All documents have valid front matter")
        
        return valid
    
    def check_links(self) -> bool:
        """Check for broken cross-references."""
        print("Checking cross-references...")
        
        valid = True
        for doc_path, doc in self.docs.items():
            for link in doc['links']:
                if link.startswith('/docs/') and link not in self.docs:
                    print(f"ERROR: {doc_path} - Broken link: {link}")
                    valid = False
        
        if valid:
            print("✅ All cross-references are valid")
        
        return valid
    
    def generate_report(self) -> None:
        """Generate documentation status report."""
        print("Generating documentation status report...\n")
        
        # Count documents by status
        status_counts = {}
        for doc in self.docs.values():
            status = doc['front_matter'].get('status', 'Unknown')
            status_counts[status] = status_counts.get(status, 0) + 1
        
        # Print status summary
        print("Document Status Summary:")
        print("------------------------")
        for status, emoji in STATUS_EMOJI.items():
            count = status_counts.get(status, 0)
            print(f"{emoji} {status}: {count} documents")
        print(f"Total: {len(self.docs)} documents\n")
        
        # Print documents by category
        categories = {}
        for doc_path, doc in self.docs.items():
            # Extract category from path (first directory after /docs/)
            parts = doc_path.split('/')
            if len(parts) > 2:
                category = parts[2]
                if category not in categories:
                    categories[category] = []
                categories[category].append(doc_path)
        
        print("Documents by Category:")
        print("---------------------")
        for category, paths in sorted(categories.items()):
            print(f"{category}: {len(paths)} documents")
            for path in sorted(paths):
                doc = self.docs[path]
                status = doc['front_matter'].get('status', 'Unknown')
                emoji = STATUS_EMOJI.get(status, "❓")
                title = doc['front_matter'].get('title', path)
                print(f"  {emoji} {title} ({path})")
            print()
    
    def migrate_document(self, source_path: str, target_path: str, 
                         title: str, status: str, version: str, 
                         contributors: List[str], tags: List[str]) -> None:
        """Migrate a document to the new structure with proper front matter."""
        if not os.path.exists(source_path):
            print(f"ERROR: Source file does not exist: {source_path}")
            return
        
        # Create target directory if it doesn't exist
        target_dir = os.path.dirname(target_path)
        os.makedirs(target_dir, exist_ok=True)
        
        # Read source content
        with open(source_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove existing front matter if present
        content = re.sub(FRONT_MATTER_PATTERN, '', content)
        
        # Create new front matter
        today = datetime.date.today().strftime('%Y-%m-%d')
        front_matter = {
            'title': title,
            'status': status,
            'version': version,
            'date_created': today,
            'last_updated': today,
            'contributors': contributors,
            'related_docs': ['/docs/README.md'],
            'tags': tags
        }
        
        # Add navigation header
        content = f"[↩️ Back to Documentation Index](/docs/README.md)\n\n{content}"
        
        # Combine front matter and content
        full_content = f"---\n{yaml.dump(front_matter)}---\n\n{content}"
        
        # Write to target path
        with open(target_path, 'w', encoding='utf-8') as f:
            f.write(full_content)
        
        print(f"✅ Migrated document to {target_path}")
    
    def update_status(self, doc_path: str, new_status: str) -> bool:
        """Update the status of a document."""
        if doc_path not in self.docs:
            print(f"ERROR: Document not found: {doc_path}")
            return False
        
        if new_status not in STATUS_EMOJI:
            print(f"ERROR: Invalid status: {new_status}")
            return False
        
        doc = self.docs[doc_path]
        path = doc['path']
        content = doc['content']
        
        # Extract front matter
        match = FRONT_MATTER_PATTERN.match(content)
        if not match:
            print(f"ERROR: No front matter found in {doc_path}")
            return False
        
        front_matter_text = match.group(1)
        
        try:
            front_matter = yaml.safe_load(front_matter_text)
            front_matter['status'] = new_status
            front_matter['last_updated'] = datetime.date.today().strftime('%Y-%m-%d')
            
            # Replace front matter in content
            new_front_matter = yaml.dump(front_matter)
            new_content = re.sub(
                FRONT_MATTER_PATTERN,
                f'---\n{new_front_matter}---\n\n',
                content
            )
            
            # Write updated content back to file
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"✅ Updated status of {doc_path} to {STATUS_EMOJI[new_status]} {new_status}")
            return True
            
        except yaml.YAMLError as e:
            print(f"ERROR: YAML parsing error in {doc_path}: {e}")
            return False


def main():
    """Main function to parse arguments and run commands."""
    if len(sys.argv) < 2 or sys.argv[1] == 'help':
        print(__doc__)
        return
    
    manager = DocManager(DOCS_ROOT)
    command = sys.argv[1]
    
    if command == 'validate':
        verbose = len(sys.argv) > 2 and sys.argv[2] == '--verbose'
        manager.validate(verbose)
    
    elif command == 'check-links':
        manager.check_links()
    
    elif command == 'report':
        manager.generate_report()
    
    elif command == 'migrate':
        if len(sys.argv) < 8:
            print("ERROR: Missing arguments for migrate command")
            print("Usage: python doc-manager.py migrate SOURCE_PATH TARGET_PATH TITLE STATUS VERSION CONTRIBUTORS TAGS")
            print("Example: python doc-manager.py migrate old/file.md docs/new/file.md \"Document Title\" Active 1.0 \"Author1,Author2\" \"tag1,tag2\"")
            return
        
        source_path = sys.argv[2]
        target_path = sys.argv[3]
        title = sys.argv[4]
        status = sys.argv[5]
        version = sys.argv[6]
        contributors = sys.argv[7].split(',')
        tags = sys.argv[8].split(',') if len(sys.argv) > 8 else []
        
        manager.migrate_document(source_path, target_path, title, status, version, contributors, tags)
    
    elif command == 'update-status':
        if len(sys.argv) < 4:
            print("ERROR: Missing arguments for update-status command")
            print("Usage: python doc-manager.py update-status DOC_PATH NEW_STATUS")
            print("Example: python doc-manager.py update-status /docs/architecture/overview.md Active")
            return
        
        doc_path = sys.argv[2]
        new_status = sys.argv[3]
        
        manager.update_status(doc_path, new_status)
    
    else:
        print(f"Unknown command: {command}")
        print("Use 'python doc-manager.py help' for available commands")


if __name__ == '__main__':
    main()