#!/usr/bin/env python3
"""Root-only, isolated chroot tests; never create users in the host OS.

Requires an existing Buildroot rootfs only to supply BusyBox + its libraries.
Ubuntu host binaries supply sudo/coreutils in the test jail, not in a release VM.
"""
import gzip
import json
import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from types import SimpleNamespace

LAB = Path(__file__).resolve().parents[1]
WORKSPACE = LAB.parent
THEME_FIELDS = ('title','org','place','system','project','asset','event',
                'status','service','host','file','person')

def theme_data(index, source=LAB/'polylinux-theme-catalog.sh'):
    script = '. "$1"; THEME_INDEX=$2; export THEME_INDEX; for field in ' + \
        ' '.join(THEME_FIELDS) + '; do printf "%s\\t" "$(theme_field "$field")"; done'
    result = subprocess.run(['sh','-c',script,'sh',str(source),str(index)],
                            check=True,capture_output=True,text=True)
    values = result.stdout.rstrip('\t\n').split('\t')
    assert len(values) == len(THEME_FIELDS) and all(values)
    return dict(zip(THEME_FIELDS,values))

def theme_index(email, day):
    material = b'polylinux-theme-v1\0polylinux-permissions\0' + \
        email.encode() + b'\0' + day.encode() + b'\0'
    return hashlib.sha256(material).digest()[0] % 16
def parse_newc(blob):
    """Minimal read-only newc reader; keep the source test suite self-contained."""
    pos = 0
    while True:
        header = blob[pos:pos+110]
        assert len(header)==110 and header[:6] in (b'070701',b'070702')
        values = [int(header[i:i+8],16) for i in range(6,110,8)]
        pos += 110
        name = blob[pos:pos+values[11]-1].decode()
        pos = (pos+values[11]+3)&~3
        data = blob[pos:pos+values[6]]
        assert len(data)==values[6]
        pos = (pos+values[6]+3)&~3
        if name=='TRAILER!!!': return
        while name.startswith('./'): name=name[2:]
        yield SimpleNamespace(name=name,data=data,fields={'mode':values[1]})

def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()

def expected(n, email, day, secret='testSecret', password_root='levelPassword'):
    seed = digest(email + day + secret + password_root + str(n))
    h = lambda label: digest(seed + ':' + label)
    ix = lambda label, length: int(h(label)[:2], 16) % length
    theme = theme_data(theme_index(email,day))
    groups = ['management', 'engineering', 'sales', 'support']
    people = ['ajohnson bdavis csmith dwilson ethomas fmiller', 'gchen hkim ipatel jbrown knguyen lgarcia', 'mscott nlopez owhite ptorres qreed radams', 'sclark tevans uyoung vmartinez wbrooks xhall']
    idx = ix('department', 4)
    group = groups[idx]
    person = people[idx].split()[ix('employee', 6)]
    project = theme['project'] + '-' + h('project-name')[:6]
    document = theme['file'] + '-' + h('document-name')[:6] + '.txt'
    nodes = {'.': ['d', 0o755, 'root', 'root', None]}
    def directory(p, mode=0o755, owner='root', grp='root'):
        parent = str(Path(p).parent)
        if parent != '.' and parent not in nodes:
            directory(parent)
        nodes[p] = ['d', mode, owner, grp, None]
    def file(p, mode, owner, grp):
        parent = str(Path(p).parent)
        if parent not in nodes:
            directory(parent)
        content = (f"{theme['title']} operations record\nOrganization: {theme['org']}\n" +
                   f"Department: {group}\nLocation: {theme['place']}\n" +
                   f"System: {theme['system']}\nProject: {theme['project']}\n" +
                   f"Asset: {theme['asset']}\nEvent: {theme['event']}\n" +
                   f"Status: {theme['status']}\nService: {theme['service']}\n" +
                   f"Host: {theme['host']}\nContact: {theme['person']}\n" +
                   'Reference: ' + h('content:work/' + p) + '\n')
        nodes[p] = ['f', mode, owner, grp, content.encode()]
    if n == 1: file('records/'+document,0o640,person,group)
    elif n == 2: file('departments/'+group+'/'+document,0o640,person,group)
    elif n == 3: file('reports/'+document,0o640,person,group)
    elif n == 4:
        directory('projects/'+project,0o750,person,group)
        file('projects/'+project+'/'+document,0o640,person,group)
    elif n == 5:
        directory('homes/'+person,0o700,person,group)
        directory('homes/'+person+'/private',0o700,person,group)
        file('homes/'+person+'/private/notes.txt',0o600,person,group)
    elif n == 6:
        directory('path',0o751,person,group)
        directory('path/'+project,0o750,person,group)
        directory('path/'+project+'/archive',0o750,person,group)
        file('path/'+project+'/archive/'+document,0o640,person,group)
    elif n == 7:
        directory('shared/'+group,0o2770,'root',group)
        file('shared/'+group+'/starter.txt',0o660,'root',group)
    elif n == 8:
        directory('workspaces/'+project,0o3770,'root',group)
        file('workspaces/'+project+'/draft.txt',0o660,person,group)
    elif n == 9:
        directory('audit/'+group,0o2750,'root',group)
        file('audit/'+group+'/'+document,0o640,person,group)
        file('audit/'+group+'/control.txt',0o440,'root',group)
    else:
        directory('company/'+group,0o2750,'root',group)
        directory('company/'+group+'/'+project,0o2770,'root',group)
        file('company/'+group+'/'+document,0o640,person,group)
        file('company/'+group+'/'+project+'/plan.txt',0o660,person,group)
        directory('company/homes/'+person,0o700,person,group)
        file('company/homes/'+person+'/notes.txt',0o600,person,group)
    canonical = f'permissions-state-v1\nlevel{n}\n'
    for p, (kind, mode, owner, grp, data) in sorted(nodes.items()):
        canonical += f'{"." if p == "." else "./"+p}|{kind}|{mode:o}|{owner}|{grp}\n'
        if data is not None: canonical += hashlib.sha256(data).hexdigest() + '\n'
    return digest(canonical)[:16], nodes, person, group

def main():
    if os.geteuid() != 0:
        sys.exit('Run with sudo; all user/account changes are confined to a temporary chroot.')
    catalog = [theme_data(index) for index in range(16)]
    shared_catalog = [theme_data(index,WORKSPACE/'tools/polylinux-common.sh') for index in range(16)]
    assert catalog == shared_catalog
    assert len({item['title'] for item in catalog}) == 16
    baseline = Path(sys.argv[1]) if len(sys.argv) > 1 else WORKSPACE/'buildroot-baseline/processes-v1/images/processes-v1-rootfs.cpio.gz'
    with tempfile.TemporaryDirectory(prefix='polylinux-permissions-tests-') as tmp:
        jail = Path(tmp)
        jail.chmod(0o755)
        def write(p, text):
            target = jail/p.lstrip('/')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
        def copy_binary(src):
            src = Path(src)
            target = jail/str(src).lstrip('/')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src.resolve(), target)
            linked = subprocess.run(['ldd',str(src)],capture_output=True,text=True).stdout
            for dep in re.findall(r'(/[^\s()]+)',linked):
                dst = jail/dep.lstrip('/')
                dst.parent.mkdir(parents=True, exist_ok=True)
                if not dst.exists(): shutil.copy2(Path(dep).resolve(),dst)
        # Copy only BusyBox and its runtime libraries from the existing baseline.
        for entry in parse_newc(gzip.decompress(baseline.read_bytes())):
            name = entry.name
            if not (name == 'bin/busybox' or name.startswith('lib/')): continue
            if '..' in Path(name).parts or name.startswith('/'): raise AssertionError(name)
            target = jail/name
            mode = entry.fields['mode']
            target.parent.mkdir(parents=True, exist_ok=True)
            if stat.S_ISDIR(mode): target.mkdir(exist_ok=True)
            elif stat.S_ISREG(mode): target.write_bytes(entry.data); target.chmod(stat.S_IMODE(mode))
            elif stat.S_ISLNK(mode): target.symlink_to(entry.data.decode())
        for cmd in 'sh awk cat chmod chgrp chown cp cut date find grep head id ls mkdir mktemp mv passwd readlink rm rmdir sed sha256sum sleep sort stat su sudo touch tr true visudo env'.split():
            src = shutil.which(cmd)
            assert src, cmd
            copy_binary(src)
            dst = jail/'usr/bin'/cmd
            if not dst.exists(): dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(src,dst)
        # BusyBox account-management syntax is exactly what the guest installer uses.
        for cmd in ['adduser','addgroup']:
            (jail/'usr/bin'/cmd).symlink_to('/bin/busybox')
        if not (jail/'bin/sh').exists(): (jail/'bin/sh').symlink_to('/usr/bin/sh')
        for lib in Path('/usr/lib').glob('**/sudo/*.so'): copy_binary(lib)
        for lib in Path('/usr/libexec/sudo').glob('*.so'): copy_binary(lib)
        for config in ['pam.d','security']:
            shutil.copytree(Path('/etc')/config,jail/'etc'/config,dirs_exist_ok=True)
        for lib in Path('/usr/lib').glob('**/security/*.so'): copy_binary(lib)
        for lib in Path('/lib/x86_64-linux-gnu').glob('libnss_*.so*'): copy_binary(lib)
        write('/etc/passwd','root:x:0:0:root:/root:/bin/sh\n')
        write('/etc/shadow','root::19000:0:99999:7:::\n')
        write('/etc/group','root:x:0:\n')
        write('/etc/gshadow','root:::\n')
        write('/etc/nsswitch.conf','passwd: files\ngroup: files\nshadow: files\nhosts: files\n')
        write('/etc/hosts','127.0.0.1 localhost '+os.uname().nodename+'\n')
        write('/etc/sudoers','Defaults !use_pty\nroot ALL=(ALL:ALL) ALL\n')
        (jail/'etc/sudoers').chmod(0o440)
        for d in ['run','var/log','tmp','home','dev','root','etc/profile.d']:
            (jail/d).mkdir(parents=True,exist_ok=True)
        (jail/'tmp').chmod(0o1777)
        for name, major, minor in [('null',1,3),('tty',5,0),('urandom',1,9)]:
            os.mknod(jail/'dev'/name,stat.S_IFCHR|0o666,os.makedev(major,minor))
        shutil.copytree(LAB,jail/'root',dirs_exist_ok=True)
        def run(args, user=None, input=None, ok=True):
            command = ['chroot',str(jail),'/usr/bin/env','PATH=/usr/sbin:/usr/bin:/sbin:/bin','LC_ALL=C']
            if user: command += ['sudo','-u',user,'-H']
            result = subprocess.run(command+args,input=input,text=True,capture_output=True)
            if ok and result.returncode:
                log = jail/'var/log/polylinux-permissions.log'
                raise AssertionError(f'{args}: {result.stdout}\n{result.stderr}\n'+(log.read_text() if log.exists() else 'No build log yet'))
            return result
        def install(email, day, secret='testSecret', workers='10'):
            result = run(['env',f'USER_ID={email}',f'CURRENT_DATE={day}',f'SYSTEM_PASSWORD={secret}',f'MAX_PARALLEL={workers}','sh','/root/install.sh','--non-interactive','--no-login'])
            assert 'Preparing all ten levels' in result.stdout
            assert all(f'Level {n}: ready' in result.stdout for n in range(1,11))
            return result
        # Preflight must fail before creating accounts or homes.
        visudo = jail/'usr/sbin/visudo'
        if not visudo.exists(): visudo = jail/'usr/bin/visudo'
        # Hide every alias of sudo to exercise dependency detection.
        sudo_paths = [p for p in [jail/'usr/bin/sudo',jail/'bin/sudo'] if p.exists()]
        for p in sudo_paths: p.rename(p.with_name('sudo.hidden'))
        result = run(['env','USER_ID=learner@example.edu','sh','/root/install.sh','--non-interactive','--no-login'],ok=False)
        assert result.returncode and 'required command not found: sudo' in result.stderr, (result.stdout,result.stderr)
        assert not (jail/'home/level1').exists()
        for p in sudo_paths: p.with_name('sudo.hidden').rename(p)
        solver = (LAB/'verify.sh').read_text()
        email='learner@example.edu'; day='2026-10-01'
        initial_by_seed = {}
        captured_vectors = []
        blockers = set()
        def peer_in_group(person,group):
            gid=next(line.split(':')[2] for line in (jail/'etc/group').read_text().splitlines() if line.startswith(group+':'))
            return next(line.split(':')[0] for line in (jail/'etc/passwd').read_text().splitlines() if line.split(':')[3]==gid and not line.startswith(person+':'))
        def solve_case(email,day,secret='testSecret',workers='10'):
            install(email,day,secret,workers)
            selected_theme = theme_data(theme_index(email,day))
            readme = (jail/'home/level1/README.txt').read_text()
            assert f"Theme: {selected_theme['title']}" in readme
            assert '__POLYLINUX_DIVIDER__' not in readme, readme
            keys=[]
            for n in range(1,11):
                initial = run(['validate'],user=f'level{n}').stdout.strip()
                answer,nodes,person,group = expected(n,email,day,secret)
                initial_id = (email,day,secret,n)
                assert initial_by_seed.setdefault(initial_id,initial)==initial
                if n == 6:
                    doc=next(p for p,v in nodes.items() if v[0]=='f')
                    assert run(['cat','/home/level6/work/'+doc],user=peer_in_group(person,group),ok=False).returncode
                    blocked=[p for p in (jail/'home/level6/work/path').rglob('*') if p.is_dir() and stat.S_IMODE(p.stat().st_mode)==0o740]
                    assert len(blocked)==1
                    blockers.add(blocked[0].name=='archive')
                key = run(['sh','-s','--',str(n)],user=f'level{n}',input=solver).stdout.strip()
                assert initial != key, (n,'initial state already correct',
                                        (jail/f'home/level{n}/README.txt').read_text())
                # Compare every real path, byte, owner/group and mode independently.
                root = jail/f'home/level{n}/work'
                actual_paths = {'.'}|{str(p.relative_to(root)) for p in root.rglob('*')}
                assert actual_paths == set(nodes), (n,actual_paths,set(nodes))
                for p,(kind,mode,owner,grp,data) in nodes.items():
                    artifact=root/p
                    assert stat.S_IMODE(artifact.stat().st_mode)==mode,(n,p)
                    info=run(['stat','-c','%U:%G',f'/home/level{n}/work/'+p]).stdout.strip()
                    assert info == owner+':'+grp,(n,p,info)
                    if data is not None: assert artifact.read_bytes()==data,(n,p)
                assert key == answer, (n,key,answer)
                keys.append(key)
            captured_vectors.append({'email':email,'exerciseDate':day,'exerciseCode':format(int(day.replace('-','')),'X'),
                'secrets':{'Exercise':secret,**{f'Level {n}':f'levelPassword{n}' for n in range(1,11)}},'answers':keys})
            return keys
        first=solve_case(email,day)
        second=solve_case(email,day,workers='1')
        assert first==second
        assert all(a!=b for a,b in zip(first,solve_case('another@example.edu',day)))
        assert all(a!=b for a,b in zip(first,solve_case(email,'2026-10-02')))
        assert all(a!=b for a,b in zip(first,solve_case(email,day,'changedSecret')))
        if os.environ.get('PERMISSIONS_VECTOR_OUTPUT'):
            solve_case('nxg13@psu.edu',day,'systemPassword')
            solve_case('Learner.Mixed@example.edu',day,'systemPassword')
        solve_case(email,day)
        if os.environ.get('PERMISSIONS_VECTOR_OUTPUT'):
            Path(os.environ['PERMISSIONS_VECTOR_OUTPUT']).write_text(json.dumps({'provenance':'Actual reference repairs and validate in isolated Linux chroot; independently checked metadata/content', 'vectors':captured_vectors},indent=2)+'\n')
        assert blockers == {True,False}, 'both seeded blocker locations must be exercised'
        # Navigation is passwordless and does not consult completion or keys.
        for user,helper,target in [('level1','nextlevel','level2'),('level2','prevlevel','level1')]:
            navigation=run([helper],user=user,input='id -un\nexit\n')
            assert target in navigation.stdout.splitlines(), navigation.stdout
        color=run(['sh','-c','. /etc/profile.d/polylinux-colors.sh\nls /home'],user='level1')
        assert '\x1b' not in color.stdout
        assert hashlib.sha256((LAB/'polylinux-colors.sh').read_bytes()).hexdigest()=='ddd2dc3060c611da8c6f7d1cafc2e6fdf41b22094ed2f7256cbc3dcb2fcfa4df'
        write('/home/unrelated/sentinel','keep\n')
        denied=run(['sh','-c','. /root/resources.sh; . /root/runtime.sh; safe_remove_home /home/unrelated'],ok=False)
        assert denied.returncode and (jail/'home/unrelated/sentinel').read_text()=='keep\n'
        # Real unprivileged directory traversal, setgid, and sticky-bit behavior.
        _,nodes,person,group=expected(6,email,day)
        doc=next(p for p,v in nodes.items() if v[0]=='f')
        member=peer_in_group(person,group)
        assert run(['cat','/home/level6/work/'+doc],user=member).returncode==0
        _,nodes,person,group=expected(7,email,day)
        directory=next(p for p,v in nodes.items() if v[1]==0o2770)
        run(['touch','/home/level7/work/'+directory+'/probe'],user=person)
        assert run(['stat','-c','%G','/home/level7/work/'+directory+'/probe']).stdout.strip()==group
        _,nodes,person,group=expected(8,email,day)
        directory=next(p for p,v in nodes.items() if v[1]==0o3770)
        peer=peer_in_group(person,group)
        result=run(['rm','/home/level8/work/'+directory+'/draft.txt'],user=peer,ok=False)
        assert result.returncode and (jail/'home/level8/work'/directory/'draft.txt').exists()
        # Fingerprints ignore timestamps and home control files, detect wrong work.
        key=run(['validate'],user='level1').stdout
        run(['sh','-c','touch /home/level1/work/records/*; echo note >> /home/level1/README.txt'])
        assert run(['validate'],user='level1').stdout==key
        run(['sh','-c','chmod 777 /home/level1/work/records/*'])
        assert run(['validate'],user='level1').stdout!=key
        control_key=run(['validate'],user='level9').stdout
        run(['sh','-c','chmod 644 /home/level9/work/audit/*/control.txt'])
        assert run(['validate'],user='level9').stdout!=control_key
        # Failed workers leave failure notices; --no-login reports failure.
        (jail/'root/level4.sh').write_text('#!/bin/sh\nexit 7\n')
        failure=run(['env',f'USER_ID={email}',f'CURRENT_DATE={day}','sh','/root/install.sh','--non-interactive','--no-login'],ok=False)
        assert failure.returncode and (jail/'run/polylinux-permissions/level4.failed').exists()
        assert 'This level could not be prepared.' in (jail/'home/level4/README.txt').read_text()
        assert not (jail/'run/polylinux-permissions/lock').exists()
        assert (jail/'home/unrelated/sentinel').read_text()=='keep\n'
        print(f'PASS: {len(captured_vectors)*10} level repairs; shared 16-theme catalog/selection and themed records; independent state/key oracle; repeatability; learner/date/password variation; serial/parallel guarded reset; dependency/failure handling; both traversal variants; setgid/sticky; navigation/colors; fingerprint sensitivity.')

if __name__ == '__main__': main()
