#!/usr/bin/env python3
import hashlib, os, sys, zipfile
ver=sys.argv[1] if len(sys.argv)>1 else "v0.1.0-alpha"
out=f"a50-ubuntu-touch-{ver}.zip"
def sha(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        for c in iter(lambda:f.read(1<<20),b''): h.update(c)
    return h.hexdigest()
sums=[(sha("boot.img"),"boot.img"),
      (open("rootfs.img.sha256").read().strip(),"rootfs.img"),
      (open("android-rootfs.img.sha256").read().strip(),"android-rootfs.img")]
open("checksums.sha256","w").write("".join(f"{h}  {n}\n" for h,n in sums))
with zipfile.ZipFile(out,"w",allowZip64=True) as z:
    zi=zipfile.ZipInfo("META-INF/com/google/android/update-binary",(2026,11,12,0,0,0)); zi.external_attr=0o755<<16; zi.compress_type=zipfile.ZIP_DEFLATED
    z.writestr(zi,open("zip/META-INF/com/google/android/update-binary","rb").read())
    z.write("zip/META-INF/com/google/android/updater-script","META-INF/com/google/android/updater-script",zipfile.ZIP_DEFLATED)
    for f in ("release.info","checksums.sha256","boot.img"):
        z.write(f,f,zipfile.ZIP_DEFLATED)
    for f in ("rootfs.img.gz","android-rootfs.img.gz"):
        z.write(f,f,zipfile.ZIP_STORED)
# unix permission for the installer script
print(out, os.path.getsize(out))
print(sha(out), out)
