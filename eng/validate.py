from pathlib import Path
import hashlib,json,sys
R=Path(__file__).resolve().parents[1]
REQ=('.agents', '.claude-plugin', '.config', '.cursor-plugin', '.github', '.vscode', 'agentic-workflows', 'docs', 'eng', 'plugins', 'tests')
fail=[]
for name in REQ:
    if not (R/name).is_dir(): fail.append('missing '+name)
cat=json.loads((R/'.pmcro/control/catalog.json').read_text(encoding='utf-8-sig'))
for row in cat.get('skills',[]):
    s=R/'.pmcro/plugins'/row['plugin']/'skills'/row['id']
    if not (s/'SKILL.md').is_file(): fail.append(f"{row['plugin']}/{row['id']} SKILL.md")
    for part in ('agents', 'scripts', 'references', 'assets', 'tests'):
        p=s/part
        if not p.is_dir() or not any(x.is_file() for x in p.rglob('*')): fail.append(f"{row['plugin']}/{row['id']} {part}")
lockp=R/'.pmcro/upstream-lock.json'
if lockp.is_file():
    lock=json.loads(lockp.read_text(encoding='utf-8-sig'))
    mirror=R/lock.get('mirror','.pmcro/upstream/dotnet-skills')
    if not mirror.is_dir(): fail.append('missing pinned upstream mirror')
    else:
        h=hashlib.sha256(); count=0
        for p in sorted(x for x in mirror.rglob('*') if x.is_file() and '.git' not in x.parts):
            rel=p.relative_to(mirror).as_posix(); d=hashlib.sha256(p.read_bytes()).hexdigest()
            h.update(rel.encode()); h.update(b'\0'); h.update(d.encode()); h.update(b'\n'); count+=1
        if h.hexdigest()!=lock.get('treeDigest') or count!=lock.get('files'): fail.append('pinned upstream mirror digest/files mismatch')
print('REPOSITORY-STRUCTURE-PASS' if not fail else 'REPOSITORY-STRUCTURE-FAIL')
for item in fail: print('FAIL',item)
sys.exit(1 if fail else 0)
