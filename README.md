# Zotero AppImage

AppImages for [Zotero](https://www.zotero.org), a free and open-source reference manager. Built from the official release tarball and published as versioned GitHub Releases.

## Get it

Download the latest `Zotero-<version>-x86_64.AppImage` from [Releases](https://github.com/erickCantu/zotero-appimage/releases/latest), make it executable, and run it:

```sh
chmod +x Zotero-*-x86_64.AppImage
./Zotero-*-x86_64.AppImage
```

## Update

Each AppImage carries zsync update information pointing at this repository. Update with AppImageUpdate:

```sh

./appimageupdate Zotero-*-x86_64.AppImage
```