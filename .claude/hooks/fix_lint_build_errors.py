#!/usr/bin/env python3
"""
PostToolUse hook to automatically fix Swift lint and build errors.
Runs SwiftLint and xcodebuild with xcbeautify after file modifications.
"""
import json
import sys
import subprocess
import os
import re
from pathlib import Path

def run_command(command, cwd=None, shell=True):
    """Run a shell command and return the result."""
    try:
        result = subprocess.run(
            command, 
            shell=shell, 
            cwd=cwd,
            capture_output=True, 
            text=True,
            timeout=300  # 5 minute timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 1, "", "Command timed out after 5 minutes"
    except Exception as e:
        return 1, "", str(e)

def is_swift_file(file_path):
    """Check if the file is a Swift source file."""
    return file_path.lower().endswith('.swift')

def run_swift_lint(project_dir):
    """Run SwiftLint and attempt to fix issues."""
    print("🔍 Running SwiftLint...")
    
    # First run SwiftLint with autocorrect
    returncode, stdout, stderr = run_command("swiftlint --fix", cwd=project_dir)
    
    if returncode == 0:
        if "Done linting" in stdout or not stdout.strip():
            print("✅ SwiftLint: No issues found")
            return True  # Success
        else:
            print("🔧 SwiftLint: Auto-fixed some issues")
            print(stdout)
            return True  # Auto-fixed, so success
    else:
        # Run regular lint to see remaining issues
        returncode2, stdout2, stderr2 = run_command("swiftlint", cwd=project_dir)
        if stdout2.strip():
            print("❌ SwiftLint issues that need manual attention:")
            print(stdout2)
            return False  # Has unfixable issues
        if stderr.strip():
            print("❌ SwiftLint error:", stderr)
            return False  # Has errors
        return True  # No output means success

def run_swift_typecheck(project_dir):
    """Run Swift type checking for fast error detection."""
    print("⚡ Running Swift type check...")
    
    # Find all Swift files in the project
    swift_files = list(Path(project_dir).glob("**/*.swift"))
    if not swift_files:
        print("⚠️  No Swift files found")
        return True
    
    # Create relative paths for the command
    swift_file_paths = [str(f.relative_to(project_dir)) for f in swift_files if "Tests" not in str(f)]
    
    if not swift_file_paths:
        print("⚠️  No non-test Swift files found")
        return True
    
    # Run swift typecheck on all Swift files
    files_str = " ".join(f'"{path}"' for path in swift_file_paths)
    typecheck_cmd = f"swiftc -typecheck {files_str}"
    
    returncode, stdout, stderr = run_command(typecheck_cmd, cwd=project_dir)
    
    if returncode == 0:
        print("✅ Swift type check passed")
        return True
    else:
        print("❌ Swift type check failed - must be fixed before proceeding:")
        if stderr.strip():
            print(stderr)
        if stdout.strip():
            print(stdout)
        return False

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)
        
        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")
        
        # Only process file modification tools
        if tool_name not in ["Write", "Edit", "MultiEdit"]:
            sys.exit(0)
        
        # Only process Swift files
        if not is_swift_file(file_path):
            sys.exit(0)
            
        project_dir = input_data.get("cwd", os.getcwd())
        
        print(f"🚀 PostToolUse hook triggered for {file_path}")
        
        # Run SwiftLint first
        lint_success = run_swift_lint(project_dir)
        
        # Then run fast type check
        typecheck_success = run_swift_typecheck(project_dir)
        
        # If either lint or type check failed, exit with code 2 to block Claude
        if not lint_success or not typecheck_success:
            print("❌ Errors detected! Claude must address these issues before proceeding.", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks Claude and shows stderr
        
        print("✨ Lint and build check completed successfully")
        
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Hook error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()