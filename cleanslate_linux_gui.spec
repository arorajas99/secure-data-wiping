# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['cleanslate_linux_gui.py'],
    pathex=[],
    binaries=[],
    datas=[('/usr/share/tcltk/tcl8.6', './tcl8.6'), ('/usr/share/tcltk/tk8.6', './tk8.6')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='cleanslate_linux_gui',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
