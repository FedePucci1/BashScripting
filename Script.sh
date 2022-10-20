#!/bin/bash

dpkg -l $pkg > /dev/null

#Validaciones iniciales

if [ $# = 0 ]
then 
    echo "No se ha enviado ningun parametro"
    exit 1
fi
 
if [ $1 = "-?" ]
then
    ayuda
    exit 0
fi

#Señales

function salir() {
    grep -v "#$(pwd $rutaEntrada)/$rutaEntrada#" "$pathMonitoreados" > ".temp" | echo
    cat .temp > "$pathMonitoreados"
    rm ".temp" 
    trap - SIGINT SIGTERM 
    kill -- -$$ 
}

trap salir SIGINT SIGTERM
 
#Ayuda del script

function ayuda(){
    echo ""
    echo "Esta es la seccion de ayuda proporcionada para el script."
    echo ""
    echo "Para utilizar el script es necesario tener instalado el paquete de inotify-tools"
    echo "Para instalar dicho paquete, use el siguiente comando: apt install inotify-tools"
    echo ""
    echo "Este script simula un sistema de integracion continua, para ello, monitoriza un directorio"
    echo "y realiza ciertas acciones al detectar un cambio en el mismo."
    echo "Para ver que directorios estan siendo monitoreados, se crea un archivo oculto en la carpeta donde se ejecuto el script"
    echo ""
    echo "Si el directorio a monitorear tiene dentro subdirectorios, se llamaran a nuevas instancias del inotify-tools"
    echo "ya que la propia herramienta reporta un bug respecto al parametro “-r” que indica recursividad en la herramienta."
    echo ""
    echo "Para el caso de borrado de archivos, se considera borrado a un comando rm ejecutado por consola."
    echo ""
    echo "Dichas acciones, detalladas a continuacion, pueden ser:"
    echo ""
    echo "-“listar”: muestra por pantalla los nombres de los archivos que sufrieron"
    echo "cambios (archivos creados, modificados, renombrados, borrados)."
    echo "-“peso”: muestra por pantalla el peso de los archivos que sufrieron cambios."
    echo "-“compilar”: compila los archivos dentro de “c”, una ruta pasada por parametro"
    echo "y los guarda en una carpeta llamada “bin”, ubicada en el directorio donde se ejecuto el script."
    echo "-“publicar”: copia el archivo compilado (el generado con la opción “compilar”) a un directorio pasado como parámetro “-s”."
    echo "Cabe resaltar, que no se puede “publicar” sin “compilar”."
    echo ""
    echo "Los parametros permitidos por el script son:"
    echo ""
    echo "-a, seguido por una accion."
    echo "-c, seguido por una ruta."
    echo "-s, seguido por una ruta."
    echo "-h, para mostrar la ayuda."
    echo "-?, para mostrar la ayuda."
    echo "--help, para mostrar la ayuda."
    echo ""
    echo "A continuacion se detallan ejemplos de ejecucion:"
    echo ""
    echo "./Script.sh -c ./Carpeta -a listar,peso"
    echo "./Script.sh -c “./Con espacio” -a listar,peso"
    echo "./Script.sh -c ./Carpeta -a listar,compilar,publicar -s ./Salidas/Publicar"
    echo "./Script.sh -c ./Carpeta -a listar,compilar,publicar -s “./Salidas con espacio/Publicar”"
    echo "./Script.sh -c “./Con espacio” -a listar,compilar,publicar -s ./Salidas/Publicar"
    echo "./Script.sh -c “./Con espacio” -a listar,compilar,publicar -s “./Salidas con espacio/Publicar”"
}

#Declaraciones

declare -a acciones
ent=false
sal=false
compilar=false
publicar=false
pathCompDef="./bin/ArchivoCompilado.txt"
pathMonitoreados="./.directoriosMonitoreados"
pkg="inotify-tools"

#Ejecutar acciones

function ejecutar(){
    IFS='
    '
    for i in ${acciones[@]}
    do
        case $i in 
        "listar")
            echo "Nombre: $2"
            echo "Accion: $3"
        ;;
        "peso")
            res=$(stat --printf="%s" "$1$2" 2>/dev/null)
            if [ ! $res = "" ]
            then
                echo "El peso de $2 es: $res bytes"
            else
                echo "No se pudo calcular el peso porque el archivo fue borrado o se creo un directorio"
            fi
        ;;
        "compilar")
            echo "Iniciando compilacion..."
            echo ""
            if [ ! -e "./bin" ]
            then
                mkdir ./bin
            fi
            cp /dev/null $pathCompDef
            find "$rutaEntrada" -maxdepth 1 -type f | while read arch;do
            cat "$arch" >> "$pathCompDef"
            done
            echo "Compilacion finalizada"
            echo ""
            if [ $publicar == true ]
            then
                echo "Iniciando publicacion..."
                echo ""
                cp $pathCompDef "$rutaSalida"
                echo "Publicacion finalizada"
                echo ""
            fi
        ;;
        *)
        ;;
        esac
    done
}

#Validar que no se monitoree dos veces el mismo directorio

function archivoMonitoreo(){
    if [ "${1:0:2}" = "./" ]
    then
        reemp=$(echo | awk -v myvar=$1 '{ print substr( myvar, 3 ) }') ##REDIRECCIONAR LA SALIDA DE ERROR
        reemp=$1
    fi

    if [ ! -e $pathMonitoreados ]
    then
        touch $pathMonitoreados
    fi

    observado="$(grep "#$(pwd $reemp)/$reemp#" $pathMonitoreados)"
    if [ -z "$observado" ]
    then
        echo "#$(pwd $reemp)/$reemp#" >> $pathMonitoreados
    else
        echo "Este directorio ya esta siendo monitoreado"
        exit 1
    fi    
}

#Opciones

options=$(getopt -o c:a:s:h --l help,entrada:,acciones:,salida: -- "$@" 2> /dev/null)
 
if [ "$?" -ne 0 ] || [ "$#" -eq 0 ]
then
    echo "No se recibio ningun parametro"
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in
        -c )
            declare -a rutaEntrada="$2"
            ent=true
            shift 2 
            ;;
        -s | "-salida")
            rutaSalida="$2"
            sal=true
            shift 2
            ;;
        -a )
            acciones=$(echo $2 | tr "," "\n")
            for i in $acciones
            do
                case "$i" in 
                "listar" | "peso")
                ;;
                # "compilar,publicar" | "publicar,compilar")
                #     publicar2=true
                # ;;                
                "publicar")
                    publicar=true
                ;;
                "compilar")
                    compilar=true
                ;;
                *)
                    echo "No se permite esta accion"
                    exit 1
                ;;
                esac
            done
            shift 2
            ;;
        -h | --help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "El envio de parametros es erroneo"
            exit 1
            ;;
    esac
done

#Validaciones

if [ ! -e "$rutaEntrada" ]
then 
    echo "La ruta de entrada es invalida o no existe"
    exit 1
fi
 
if [ $ent = false ]
then 
    echo "Se necesita una ruta de entrada para monitorear"
    exit 1
else
    if [ ! -r "$rutaEntrada" ]
    then
        echo "No tiene permisos para monitorear este directorio"
        exit
    fi
fi

if [ $compilar = false ] && [ $publicar = true ]
then
    echo "No se puede publicar el codigo sin antes compilarlo"
    exit 1 
fi
 
if [ $sal = true ] && [ $publicar = false ] 
then 
    echo "Se necesita el parametro de accion publicar para poder publicar el codigo"
    exit 1
fi

if [ $sal = false ] && [ $publicar = true ] 
then 
    echo "Se necesita una ruta de salida para publicar"
    exit 1
fi
 
if [ $sal = true ] && [ ! -e "$rutaSalida" ]
then 
    verificarRutaSalida="${rutaSalida%/*}"
    if [ $rutaSalida == $verificarRutaSalida ]
    then 
        verificarRutaSalida="./"
    fi
    if [ -w $verificarRutaSalida ]
    then
        mkdir "$rutaSalida"
    else
        echo "No tiene permisos para publicar en este directorio"
        exit 1
    fi
fi

#Parte principal del script

archivoMonitoreo "$rutaEntrada"

function principal(){
    echo "La carpeta a monitorear es: $1"
    inotifywait -m --format "%w,%e,%f" "$1" -e create,modify,delete,move | while IFS=','
    read path action file ;do
        case "${action}" in 
        "CREATE")
            ejecutar "${path}" "${file}" "${action}" 
        ;;
        "MODIFY")
            ejecutar "${path}" "${file}" "${action}" 
        ;;
        "DELETE")
            ejecutar "${path}" "${file}" "${action}" 
        ;;
        "MOVED_FROM")
            renombre="${path}"
        ;;
        "MOVED_TO")
            if [ $renombre == ${path} ]
            then
                ejecutar "${path}" "${file}" "RENAME"
            fi
        ;;
        *)
        ;;
        esac
    done
}

shopt -s globstar nullglob

for f in "$rutaEntrada"/**/*/
do
    principal "$f" &
done