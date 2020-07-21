#Este shell levanta o para todos los procesos paralelamente
#parametros: $1=nombre del archivo de configuracion
#            $2= 0, 1 o nada ; si es 1 se bajan todos los procesos sensores configurados en el archivo de configuracion



comm=2501

rm -f sensoresLevantados.cfg

velocidad=$2
parar=$3

if [ -z $parar ]
then
parar=0
fi

cat $1 | while read line 
do 
    id=`echo $line | awk -F"," '{print $1}'`
    tipo=`echo $line | awk -F"," '{print $2}'`
    th=`echo $line | awk -F"," '{print $3}'`
    regfile="data-$id-$tipo.dat"

    rand=`shuf -i 1-$th -n 1`
    max=$(($th+$rand)) #Le puse esto porque se me ocurrio

    min=`shuf -i 10-$th -n 1`
    permitidos=$(($max-$min+1))

    #------------------------------------------se levantara el proceso------------------------------------------------------
    verificar=`ps -edaf | grep "sensorx $id" | grep -v grep | wc -l` #verifico si ya hay un proceso levantado con ese id

    if [ $verificar -eq 0 ]
    then
        if [ $parar -eq 0 ]
        then
            #----------------------------------Se registra las configuraciones de los procesos a levantar-------------------------
            echo "$id|$comm|$tipo|$th|$permitidos|$regfile" >> sensoresLevantados.cfg #registro es el nombre del archivo donde se guardara la data
            ./sensorx $id $tipo $comm $velocidad $min $max 1 &
        else
            rm -f sensoresLevantados.cfg
        fi
    else
        #obtengo el pid para bajar el proceso si es que lo quieren
        pidS=`ps -edaf | grep "sensorx $id" | grep -v grep | awk '{ print $2 }'`
        
        if [ $parar -eq 1 ]
        then
           kill -2 $pidS
           rm -f sensoresLevantados.cfg
        fi
    fi

    comm=$(($comm+10))
done