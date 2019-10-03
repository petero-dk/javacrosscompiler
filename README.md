# javacrosscompiler
Cross compile newer versions of Java (i.e. 11) to Java8 (and earlier)


## usage

Run `downpile.bat` existing.jar

If the jar file has dependencies just make sure they are in the same folder, or pass it as a `--lib` parameter to downpile like this

```cmd
downpile.bat existing.jar --lib "lib\nrjavaserial-3.15.0.jar"
```

The result is found in `out/`

## Other nice stuff

The file `build_calimero.bat` shows how to build a series of dependent jars.

## What does it do

When running downpile it will run Google R8 to turn a jar into a dex file that is compatible with previous java versions. Then use dex2jar to turn that dex file back to a runnable jar. R8 will automatically desugar recent java features and missing classes.

## Automagic

The prepare script will:

* Download Java8 and Java11 ( https://adoptopenjdk.net/ )
* Download Google Depot Tools ( https://www.chromium.org/developers/how-tos/install-depot-tools )
* Download Google R8 and D8 ( https://r8.googlesource.com/r8 )
* Compile R8 and D8 
* Download custom version of Dex2Jar because the original version has a problem with "unsafe" class names that R8 will create ( https://github.com/petero-dk/dex2jar )
* Compile dex2jar