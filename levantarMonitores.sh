#Levanta los sensores de tipo competitivo

if [ ! -s sensoresLevantados.cfg ]
then
    echo "no existe el archivo sensoresLevantados.cfg por favor primero inicia los sensores"
    exit 1
fi

cat sensoresLevantados.cfg | while read line 
do 
    id=`echo $line | awk -F"\|" '{print $1}'`
    comm=`echo $line | awk -F"\|" '{print $2}'`
    tipo=`echo $line | awk -F"\|" '{print $3}'`
    th=`echo $line | awk -F"\|" '{print $4}'`
    max=`echo $line | awk -F"\|" '{print $5}'`
    regfile=`echo $line | awk -F"\|" '{print $6}'`

    touch $regfile
    chmod 777 $regfile

    #------------------------------------------se levanta el proceso------------------------------------------------------
    verificar=`ps -edaf | grep "monitorx $id" | grep -v grep | wc -l` #verifico si ya hay un proceso levantado con ese id

    if [ $verificar -eq 0 ]
    then
        ./monitorx $id $tipo $comm $max "$regfile" 1 &
    else
        #obtengo el pid para bajar el proceso y volverlo a levantar
        pidM=`ps -edaf | grep "monitorx $id" | grep -v grep | awk '{ print $2 }'`
        kill -2 $pidM
        ./monitorx $id $tipo $comm $max $regfile & 
    fi

done

exit 0