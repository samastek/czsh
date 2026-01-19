#!/usr/bin/env python3
"""
GitLab Group Cloner

This script clones all repositories from a GitLab group and its subgroups recursively.
It uses the python-gitlab library to interact with the GitLab API.

Usage:
    python gitlab_clone.py <group_url> [options]

Example:
    python gitlab_clone.py https://gitlab.com/my-group
    python gitlab_clone.py https://gitlab.com/my-group --token your_token --clone-dir ./projects
"""

import os
import sys
import argparse
import subprocess
import urllib.parse
from pathlib import Path
from typing import List, Optional

try:
    import gitlab
except ImportError:
    print("Error: python-gitlab module is required. Install it with:")
    print("pip install python-gitlab")
    sys.exit(1)


class GitLabCloner:
    def __init__(self, gitlab_url: str, token: Optional[str] = None, clone_dir: str = "./gitlab_projects"):
        """
        Initialize the GitLab cloner.
        
        Args:
            gitlab_url: Base GitLab URL (e.g., https://gitlab.com)
            token: GitLab access token (optional, for private repos)
            clone_dir: Directory to clone repositories into
        """
        self.gitlab_url = gitlab_url
        self.clone_dir = Path(clone_dir)
        self.clone_dir.mkdir(exist_ok=True)
        
        # Initialize GitLab connection
        if token:
            self.gl = gitlab.Gitlab(gitlab_url, private_token=token)
        else:
            self.gl = gitlab.Gitlab(gitlab_url)
        
        try:
            self.gl.auth()
            print(f"✓ Connected to GitLab at {gitlab_url}")
        except Exception as e:
            print(f"✓ Connected to GitLab at {gitlab_url} (anonymous access)")
    
    def clone_repository(self, project, group_path: str = "") -> bool:
        """
        Clone a single repository.
        
        Args:
            project: GitLab project object
            group_path: Path of the parent group for organizing cloned repos
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create directory structure based on group path
            if group_path:
                repo_dir = self.clone_dir / group_path / project.name
            else:
                repo_dir = self.clone_dir / project.name
            
            repo_dir.parent.mkdir(parents=True, exist_ok=True)
            
            # Skip if already exists
            if repo_dir.exists() and (repo_dir / '.git').exists():
                print(f"⏭️  Skipping {project.path_with_namespace} (already exists)")
                return True
            
            # Get clone URL (prefer SSH if available, fallback to HTTPS)
            clone_url = project.ssh_url_to_repo if hasattr(project, 'ssh_url_to_repo') else project.http_url_to_repo
            
            print(f"📥 Cloning {project.path_with_namespace}...")
            print(f"   URL: {clone_url}")
            print(f"   Destination: {repo_dir}")
            
            # Clone the repository
            result = subprocess.run(
                ["git", "clone", clone_url, str(repo_dir)],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"✅ Successfully cloned {project.path_with_namespace}")
                return True
            else:
                print(f"❌ Failed to clone {project.path_with_namespace}")
                print(f"   Error: {result.stderr.strip()}")
                return False
                
        except Exception as e:
            print(f"❌ Error cloning {project.path_with_namespace}: {str(e)}")
            return False
    
    def get_group_projects(self, group) -> List:
        """
        Get all projects in a group.
        
        Args:
            group: GitLab group object
            
        Returns:
            List of project objects
        """
        try:
            projects = group.projects.list(all=True, include_subgroups=False)
            return projects
        except Exception as e:
            print(f"❌ Error getting projects for group {group.full_path}: {str(e)}")
            return []
    
    def get_subgroups(self, group) -> List:
        """
        Get all subgroups of a group.
        
        Args:
            group: GitLab group object
            
        Returns:
            List of subgroup objects
        """
        try:
            subgroups = group.subgroups.list(all=True)
            return [self.gl.groups.get(sg.id) for sg in subgroups]
        except Exception as e:
            print(f"❌ Error getting subgroups for group {group.full_path}: {str(e)}")
            return []
    
    def clone_group_recursively(self, group, parent_path: str = "") -> dict:
        """
        Recursively clone all projects in a group and its subgroups.
        
        Args:
            group: GitLab group object
            parent_path: Path of parent groups for directory structure
            
        Returns:
            dict: Statistics about the cloning process
        """
        stats = {
            'total_projects': 0,
            'successful_clones': 0,
            'failed_clones': 0,
            'skipped_projects': 0
        }
        
        current_path = os.path.join(parent_path, group.path) if parent_path else group.path
        
        print(f"\n🔍 Processing group: {group.full_path}")
        
        # Clone projects in current group
        projects = self.get_group_projects(group)
        for project in projects:
            stats['total_projects'] += 1
            
            if self.clone_repository(project, current_path):
                stats['successful_clones'] += 1
            else:
                stats['failed_clones'] += 1
        
        # Recursively process subgroups
        subgroups = self.get_subgroups(group)
        for subgroup in subgroups:
            subgroup_stats = self.clone_group_recursively(subgroup, current_path)
            
            # Merge statistics
            for key in stats:
                stats[key] += subgroup_stats[key]
        
        return stats
    
    def clone_group_by_url(self, group_url: str) -> dict:
        """
        Clone a group by its URL.
        
        Args:
            group_url: Full URL to the GitLab group
            
        Returns:
            dict: Statistics about the cloning process
        """
        # Extract group path from URL
        parsed_url = urllib.parse.urlparse(group_url)
        group_path = parsed_url.path.strip('/')
        
        try:
            # Get the group
            group = self.gl.groups.get(group_path)
            print(f"📁 Found group: {group.full_name}")
            print(f"   Path: {group.full_path}")
            print(f"   Description: {group.description or 'No description'}")
            
            # Start cloning
            return self.clone_group_recursively(group)
            
        except gitlab.exceptions.GitlabGetError as e:
            print(f"❌ Group not found: {group_path}")
            print(f"   Error: {str(e)}")
            return {'total_projects': 0, 'successful_clones': 0, 'failed_clones': 0, 'skipped_projects': 0}
        except Exception as e:
            print(f"❌ Unexpected error: {str(e)}")
            return {'total_projects': 0, 'successful_clones': 0, 'failed_clones': 0, 'skipped_projects': 0}


def main():
    parser = argparse.ArgumentParser(
        description="Clone all repositories from a GitLab group and its subgroups recursively",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python gitlab_clone.py https://gitlab.com/my-group
  python gitlab_clone.py https://gitlab.com/my-group --token glpat-xxxxxxxxxxxxxxxxxxxx
  python gitlab_clone.py https://gitlab.com/my-group --clone-dir ./my-projects
  python gitlab_clone.py https://custom-gitlab.com/group --gitlab-url https://custom-gitlab.com
        """
    )
    
    parser.add_argument(
        'group_url',
        help='Full URL to the GitLab group (e.g., https://gitlab.com/my-group)'
    )
    
    parser.add_argument(
        '--token',
        help='GitLab access token for private repositories'
    )
    
    parser.add_argument(
        '--clone-dir',
        default='./gitlab_projects',
        help='Directory to clone repositories into (default: ./gitlab_projects)'
    )
    
    parser.add_argument(
        '--gitlab-url',
        help='GitLab instance URL (auto-detected from group URL if not specified)'
    )
    
    args = parser.parse_args()
    
    # Extract GitLab base URL if not provided
    if args.gitlab_url:
        gitlab_url = args.gitlab_url
    else:
        parsed_url = urllib.parse.urlparse(args.group_url)
        gitlab_url = f"{parsed_url.scheme}://{parsed_url.netloc}"
    
    print(f"🚀 GitLab Group Cloner")
    print(f"   Group URL: {args.group_url}")
    print(f"   GitLab URL: {gitlab_url}")
    print(f"   Clone Directory: {args.clone_dir}")
    print(f"   Token: {'✓ Provided' if args.token else '✗ Not provided (public repos only)'}")
    
    # Initialize cloner
    cloner = GitLabCloner(gitlab_url, args.token, args.clone_dir)
    
    # Start cloning
    stats = cloner.clone_group_by_url(args.group_url)
    
    # Print summary
    print(f"\n📊 Clone Summary:")
    print(f"   Total projects: {stats['total_projects']}")
    print(f"   Successful clones: {stats['successful_clones']}")
    print(f"   Failed clones: {stats['failed_clones']}")
    print(f"   Skipped projects: {stats['skipped_projects']}")
    
    if stats['failed_clones'] > 0:
        print(f"\n⚠️  Some repositories failed to clone. Check the output above for details.")
        sys.exit(1)
    else:
        print(f"\n✅ All repositories cloned successfully!")


if __name__ == "__main__":
    main()
