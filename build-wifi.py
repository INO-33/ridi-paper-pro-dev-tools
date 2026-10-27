#!/usr/bin/env python3
"""Build the preserved GPL RTL8189FS sources against an already-built kernel."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check',action='store_true',help='Validate inputs only; no compilation or writes')
parser.add_argument('--kernel-out',type=Path)
parser.add_argument('--output',type=Path,help='Generated .ko destination outside the source directory')
parser.add_argument('--jobs',type=int,default=4)
args=parser.parse_args()
workspace=Path(os.environ.get('RIDI_WORKSPACE','')).expanduser()
if not os.environ.get('RIDI_WORKSPACE') or not os.environ.get('ANDROID_BUILD_TOP'):
    parser.error('Source the restored workspace/env.sh first')
source=Path(os.environ['ANDROID_BUILD_TOP']).resolve()
driver=source/'device/ridi/e70q10/wifi/rtl8189fs'
kernel=source/'vendor/nxp-opensource/kernel_imx'
output_root=Path(os.environ.get('E70Q10_OUT_DIR',str(workspace/'android-out/e70q10_reference'))).resolve()
kernel_out=(args.kernel_out or output_root/'target/product/e70q10/obj/KERNEL_OBJ').resolve()
module=(args.output or output_root/'wifi/8189fs.ko').resolve()
compiler=source/'prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-gcc'
required=[driver/'Makefile',driver/'COPYING',kernel/'Makefile',compiler,
          kernel_out/'.config',kernel_out/'Module.symvers',kernel_out/'include/config/kernel.release']
missing=[str(p) for p in required if not p.is_file()]
if missing:parser.error('Build the matching product kernel first (kernelimage). Missing: '+', '.join(missing))
if args.jobs<1:parser.error('--jobs must be positive')
if module.is_relative_to(source):parser.error('Module output must be outside the source tree')
release=(kernel_out/'include/config/kernel.release').read_text().strip()
if args.check:
    print('Wi-Fi inputs ready; kernel='+release+'; output='+str(module))
else:
    logs=workspace/'.orchestrator/logs';logs.mkdir(parents=True,exist_ok=True)
    module.parent.mkdir(parents=True,exist_ok=True)
    logfile=logs/('wifi-build-'+time.strftime('%Y%m%d-%H%M%S')+'.log')
    with tempfile.TemporaryDirectory(prefix='wifi-source-',dir=module.parent) as temp:
        stage=Path(temp)/'rtl8189fs';shutil.copytree(driver,stage)
        command=['make','-C',str(kernel),'O='+str(kernel_out),'M='+str(stage),
                 'ARCH=arm','CROSS_COMPILE='+str(compiler).removesuffix('gcc'),
                 'HOSTCFLAGS=-fcommon','KCFLAGS=-mno-android','CONFIG_RTL8189FS=m',
                 '-j'+str(args.jobs),'modules']
        with logfile.open('w') as log:
            result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT)
        if result.returncode:raise SystemExit('Wi-Fi build failed; log: '+str(logfile))
        built=stage/'8189fs.ko'
        if not built.is_file():raise SystemExit('Wi-Fi build produced no module; log: '+str(logfile))
        strings=subprocess.check_output(['strings',str(built)],text=True)
        if not any(line.startswith('vermagic='+release+' ') for line in strings.splitlines()):
            raise SystemExit('Built Wi-Fi module does not match the selected kernel release')
        shutil.copy2(built,module)
    print('Wi-Fi module ready: '+str(module)+'; log: '+str(logfile))
