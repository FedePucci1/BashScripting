# Bash directory watcher

Academic Bash script by Federico Pucci that monitors a directory and performs actions on file changes, simulating a small continuous-integration workflow.

## Requirements

Linux/Bash, GNU command-line utilities and `inotify-tools`. The original sample inputs are in `Pruebas.zip`.

## Examples

```bash
bash Script.sh -c ./Carpeta -a listar,peso
bash Script.sh -c ./Carpeta -a listar,compilar,publicar -s ./Salidas
```

- `listar`: prints changed files and event types.
- `peso`: prints file size when available.
- `compilar`: concatenates input files into `bin/ArchivoCompilado.txt`; it does not invoke a language compiler.
- `publicar`: copies that generated file to the output directory; requires `compilar`.

The script and original academic behavior are preserved. Publication review checks Bash syntax; it does not claim a full long-running watcher test. Run examples against disposable sample directories.
