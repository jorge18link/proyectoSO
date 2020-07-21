cat sensoresLevantados.cfg | while read line 
do 
    id=`echo $line | awk -F"\|" '{print $1}'`

    #------------------------------------------se levanta el proceso------------------------------------------------------
    verificar=`ps -edaf | grep "monitorx $id" | grep -v grep | wc -l` #verifico si ya hay un proceso levantado con ese id

    if [ $verificar -ne 0 ]
    then
        #obtengo el pid para bajar el proceso y volverlo a levantar
        pidM=`ps -edaf | grep "monitorx $id" | grep -v grep | awk '{ print $2 }'`
        kill -2 $pidM
    fi

done