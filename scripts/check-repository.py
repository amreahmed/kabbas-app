"""Fail on accidentally tracked credentials, local output, or oversized files.

Checks the Git index so it also works before the initial commit. Values from
potential secret matches are never printed. This is a guard, not a full audit.
"""
from pathlib import PurePosixPath
import re
import subprocess
import sys


def git(*args):
    return subprocess.check_output(['git', *args])


blocked_dirs = {'.tools', '.dart_tool', '.local-archive', '.http-forge',
                'node_modules', 'build', 'releases', '.firebase', '.idea'}
blocked_names = {'google-services.json', 'GoogleService-Info.plist',
                 'key.properties', 'local.properties', 'local-settings.ps1', '.env'}
blocked_suffixes = {'.jks', '.keystore', '.pem', '.p12', '.pfx', '.pass',
                    '.apk', '.aab', '.apks', '.log', '.hprof', '.dmp'}
secret_patterns = [
    re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(rb'github_pat_[A-Za-z0-9_]{30,}'),
    re.compile(rb'AIza[0-9A-Za-z_-]{35}'),
    re.compile(rb'"type"\s*:\s*"service_account"'),
]
issues = []
paths = [p.decode('utf-8') for p in git('ls-files', '-z').split(b'\0') if p]
for path in paths:
    p = PurePosixPath(path)
    if (blocked_dirs.intersection(p.parts) or p.name in blocked_names
            or p.suffix in blocked_suffixes or path == 'lib/firebase_options.dart'
            or (p.name.startswith('.env.') and p.name != '.env.example')):
        issues.append(f'{path}: local or sensitive file must not be tracked')
        continue
    content = git('show', ':' + path)
    if len(content) > 5 * 1024 * 1024:
        issues.append(f'{path}: exceeds the 5 MB source-file limit')
    if any(pattern.search(content) for pattern in secret_patterns):
        issues.append(f'{path}: potential credential detected; review locally')
if issues:
    print('\n'.join(issues))
    sys.exit(1)
print(f'PASS: {len(paths)} tracked files checked; no blocked files or credential patterns.')
