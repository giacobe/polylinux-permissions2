#!/usr/bin/env python3
"""Emit only runtime files. Test oracles/solvers never enter the VM payload."""
import hashlib
import io
from pathlib import Path
import tarfile

ROOT = Path(__file__).resolve().parent
RUNTIME = ['.profile','profile','install.sh','resources.sh','runtime.sh',
           'company-data.sh','polylinux-colors.sh','nextlevel','prevlevel','validate',
           'LICENSE'] + [f'level{n}.sh' for n in range(1,11)]

def main():
    dist = ROOT/'dist'
    dist.mkdir(exist_ok=True)
    manifest = []
    with tarfile.open(dist/'permissions-v1-root-payload.tar.gz','w:gz') as archive:
        for name in sorted(RUNTIME):
            data = (ROOT/name).read_bytes()
            if name != 'LICENSE':
                assert b'\r' not in data and not data.startswith(b'\xef\xbb\xbf'), name
            info = tarfile.TarInfo('root/'+name)
            info.size = len(data)
            info.mode = 0o644 if name in ['LICENSE','profile','.profile','polylinux-colors.sh'] else 0o755
            info.uid = info.gid = 0
            info.mtime = 0
            archive.addfile(info,io.BytesIO(data))
            manifest.append(hashlib.sha256(data).hexdigest()+'  root/'+name)
    (dist/'payload-sha256.txt').write_text('\n'.join(manifest)+'\n')
    with tarfile.open(dist/'permissions-v1-root-payload.tar.gz') as archive:
        assert set(archive.getnames()) == {'root/'+name for name in RUNTIME}
        assert not any(any(x in name for x in ['checklevel','verify','test','answer']) for name in archive.getnames())
    print(f'Packaged {len(RUNTIME)} runtime files; no solvers or expected-state data: {dist}')

if __name__ == '__main__': main()
