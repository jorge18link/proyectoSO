#primero tengo que parar todos los monitores para lo cual verifico cuantos estan activos
verificar=`ps -edaf | grep "monitorx" | grep -v grep | wc -l`


#Si encuentro procesos activos los bajo
if [ $verificar -ne 0 ]
then
    ps -edaf | grep "monitorx" | grep -v grep | awk '{ print $2 }' > listaPIDM.txt

    cat listaPIDM.txt | while read line 
    do
        kill -2 $line
    done

    rm -f listaPIDM.txt
fi

#Una vez que no hay procesos activos ordeno la data para simplificar la obtencion de los que ya no 
#estaban activos por medios naturales, esos no los tomo en cuenta para mirar si enciendo la alarma

ls data*.dat > tmp.dat
#aqui ordeno
cat tmp.dat | while read line 
do
    sort -n $line > $line.sort
    rm -f $line
    cat $line.sort > $line
    rm -f $line.sort
done

rm -f tmp.dat


rm -f reporteTMP1.dat
#aqui un reporte estan activos o inactivos los sensores
cat sensoresLevantados.cfg | while read line
do
    archivo=`echo $line | awk -F"|" '{ print $6 }'`
    isInactivo=`cat $archivo | grep -c "\-1"`

    if [ $isInactivo -gt 0 ]
    then
        echo $line | awk -F"|" '{printf $0"|I\n"}' >> reporteTMP1.dat
    else
        echo $line | awk -F"|" '{printf $0"|A\n"}' >> reporteTMP1.dat
    fi
done



rm -f reporteTMP2.dat
#aqui un reporte que me dice si hay que calcular varianza
cat reporteTMP1.dat | while read line
do
    calculaVariancia=0
    class=`echo $line | awk -F"|" '{ print $3 }'`

    if [ $class -le 5 ]
    then
        calculaVariancia=`cat sensoresLevantados.cfg | awk -F"|" '{print $3}' | grep -c $class`

        echo $calculaVariancia >> daaaa.txt

        if [ $calculaVariancia -gt 1 ]
        then
            echo $line | awk -F"|" '{printf $0"|S\n"}' >> reporteTMP2.dat
        else
            echo $line | awk -F"|" '{printf $0"|N\n"}' >> reporteTMP2.dat
        fi
    else
        echo $line | awk -F"|" '{printf $0"|N\n"}' >> reporteTMP2.dat
    fi
done

rm -f reporteTMP3.dat
#aqui le pego la cantidad de elementos y el promedio
cat reporteTMP2.dat | while read line
do
    tipo=`echo $line | awk -F"|" '{ print $3 }'`
    archivo=`echo $line | awk -F"|" '{ print $6 }'`
    
    if [ $tipo -le 5 ]
    then
        numeroElementos=`cat $archivo | grep -v "\-1" | wc -l`
        sumatotal=`cat $archivo | grep -v "\-1" | awk 'BEGIN{acumulador=0;}{acumulador=acumulador+$1;}END{print acumulador}'`
        
        promedio=`echo "Hola" | awk -v n=$numeroElementos -v t=$sumatotal 'BEGIN{promedio=0;}{promedio=t/n;}END{print promedio;}'`

        echo $line | awk -F"|" -v n=$numeroElementos -v p=$promedio '{printf $0"|"n"|"p"\n"}' >> reporteTMP3.dat
    else
        prome=`cat $archivo | grep -v "\-1" | awk '{ print $1 }'`

        echo $line | awk -F"|" -v p=$prome '{printf $0"|X|"p"\n"}' >> reporteTMP3.dat
    fi

    
done

rm -f reporteTMP4.dat
#aqui calculo la varianza para los que tienen S en la 8va columna del reporteTMP2.dat
cat reporteTMP3.dat | while read line
do
    calculaVariancia=`echo $line | awk -F"|" '{ print $8 }'`
    archivo=`echo $line | awk -F"|" '{ print $6 }'`

    if [ $calculaVariancia = "S" ]
    then
        numeroElementos=`echo $line | grep -v "\-1" | awk -F"|" '{ print $9 }'`
        promedio=`echo $line | grep -v "\-1" | awk -F"|" '{ print $10 }'`

        
        varianza=`cat $archivo | grep -v "\-1" | awk -v nvj=$numeroElementos -v pvj=$promedio 'BEGIN{acumulador=0;varianza=0;calculo=0;}{calculo=(($1-pvj)*($1-pvj));acumulador=(acumulador+calculo);}END{varianza=(acumulador/nvj);print varianza;}'`
        echo $line | awk -F"|" -v varian=$varianza '{printf $0"|"varian"\n"}' >> reporteTMP4.dat
    else
        echo $line | awk -F"|" '{printf $0"|X\n"}' >> reporteTMP4.dat
    fi
done

#aqui van unos y ceros
acumScoop=0

#aqui calculo del scoorp
cat reporteTMP4.dat | while read line
do
    tipo=`echo $line | awk -F"|" '{ print $3 }'`
    archivo=`echo $line | awk -F"|" '{ print $6 }'`

    if [ $tipo -gt 5 ]
    then
        unoCero=`cat $archivo | grep -v "\-1" | awk '{if($10>$4){print "1"}else{print "0"}}'`
        acumScoop=$(($acumScoop+$unoCero))
    fi
         
done

cat reporteTMP4.dat | awk -F"|" -v acu=$acumScoop '{print $0"|"acu}' > reporteFinal.tmp


echo "---------------------------------------------------------------------------------------------------------- \n" >> sumarizacion.log
echo "Los siguientes sensores estuvieron inactivos:" >> sumarizacion.log

cat reporteFinal.tmp | while read line
do
    
    estado=`echo $line | awk -F"|" '{print $7}'`
    id=`echo $line | awk -F"|" '{print $1}'`
    tipo=`echo $line | awk -F"|" '{print $3}'`
    th=`echo $line | awk -F"|" '{print $4}'`
    pro=`echo $line | awk -F"|" '{print $10}'`
    calVarianza=`echo $line | awk -F"|" '{print $8}'`
    varianza=`echo $line | awk -F"|" '{print $10}'`
    archivo=`echo $line | awk -F"|" '{print $6}'`

    if [ $estado = "I" ]
    then
        echo "Si hay inactivo" > inactivo.exist
        if [ $calVarianza = S ]
        then
            echo "Sensonr --> id=$id, \ttipo=$tipo, \tth=$th, \tprom=$pro, \tarchivo=$archivo, \tvarianza=$varianza" >> sumarizacion.log
        else
            echo "Sensonr --> id=$id, \ttipo=$tipo, \tth=$th, \tprom=$pro, \tarchivo=$archivo" >> sumarizacion.log
        fi
    fi
    
done

if [ ! -s inactivo.exit ]
then
    echo "\nNinguno estuvo inactivo al finalizar el delta T\n" >> sumarizacion.log
fi
rm - f inactivos.exist

echo "Los siguientes sensores estuvieron activos: \n" >> sumarizacion.log

entreActivos=0
cat reporteFinal.tmp | while read line
do
    estado=`echo $line | awk -F"|" '{print $7}'`
    id=`echo $line | awk -F"|" '{print $1}'`
    tipo=`echo $line | awk -F"|" '{print $3}'`
    th=`echo $line | awk -F"|" '{print $4}'`
    pro=`echo $line | awk -F"|" '{print $10}'`
    calVarianza=`echo $line | awk -F"|" '{print $8}'`
    varianza=`echo $line | awk -F"|" '{print $10}'`
    archivo=`echo $line | awk -F"|" '{print $6}'`

    if [ $estado = "A" ]
    then
        echo "Si hay Activo" > activos.exist
        if [ $calVarianza = S ]
        then
            echo "Sensonr --> id=$id, \ttipo=$tipo, \tth=$th, \tprom=$pro, \tarchivo=$archivo, \tvarianza=$varianza" >> sumarizacion.log
        else
            echo "Sensonr --> id=$id, \ttipo=$tipo, \tth=$th, \tprom=$pro, \tarchivo=$archivo" >> sumarizacion.log
        fi
    fi      
done

if [ ! -s activos.exist ]
then
    echo "\nNinguno estuvo activo al finalizar el delta T\n" >> sumarizacion.log
fi

rm -f activos.exist




rm -f participanComp.dat
#analizar si encender la alarma
cat reporteFinal.tmp | while read line
do
    estado=`echo $line | awk -F"|" '{print $7}'`
    id=`echo $line | awk -F"|" '{print $1}'`
    tipo=`echo $line | awk -F"|" '{print $3}'`
    th=`echo $line | awk -F"|" '{print $4}'`
    varianza=`echo $line | awk -F"|" '{print $10}'`

    if [ $estado = "A" ]
    then
        if [ $tipo -lt 5 ]
        then
            cat reporteFinal.tmp | awk -v type=$tipo -F"|" '{if($3==type){print $11" "$1" "$3" "$10" "$4}}' | sort -n | head -n1 | awk '{print $2"|"$3"|"$4"|"$5}' >> participanComp.dat
        fi
    fi      
done

echo "\nLos sensores competitivos que son evaluados son:\n" >> sumarizacion.log

cat participanComp.dat | sort -n | uniq > participanComp.dat.tmp
rm -f cat participanComp.dat
cat participanComp.dat.tmp > participanComp.dat 
rm -f participanComp.dat.tmp

cat participanComp.dat | awk -F"|" '{ print "id="$1", tipo="$2", valor="$3", th="$4}' >> sumarizacion.log

scoop=`cat reporteFinal.tmp | awk -F"|" '{print $12 }' | uniq`

echo "\nEl Scoop es igual a: $scoop\n" >> sumarizacion.log

validadorScoop=`echo "hola" | awk -v scoo=$scoop '{if(scoo>0.7){ print 1}else{print 0}}'`

if [ $validadorScoop -eq 1 ]
then
    cantidadParticipan=`cat participanComp.dat | wc -l`
    contadorSePasan=0
    cat participanComp.dat | while read line
    do
        valida=`echo $line | awk -F"|" '{if($3>$4){ print 1}else{print 0}}'`

        if [ $valida -eq 1 ]
        then
            contadorSePasan=$(($contadorSePasan+1))
        fi

        if [ $contadorSePasan -eq $cantidadParticipan ]
        then
            echo "Alarma Encendida!!" >> sumarizacion.log 

            echo "---------------------------------------------------------------------------------------------------------- \n" >> sumarizacion.log

            echo "ID;Tipo;Umbral;Archivo data;Estado;Promedio;Varianza;Scoop" > reporteFinal.csv
            cat reporteFinal.tmp | awk -F"|" '{print $1";"$3";"$4";"$6";"$7";"$10";"$11";"$12 }' >> reporteFinal.csv

            rm -f reporteTMP1.dat
            rm -f reporteTMP2.dat
            rm -f reporteTMP3.dat
            rm -f reporteTMP4.dat
            rm -f reporteFinal.tmp

            exit 1
        fi

    done
else
    echo "Alarma no encendida" >> sumarizacion.log

    echo "---------------------------------------------------------------------------------------------------------- \n" >> sumarizacion.log

    echo "ID;Tipo;Umbral;Archivo data;Estado;Promedio;Varianza;Scoop" > reporteFinal.csv
    cat reporteFinal.tmp | awk -F"|" '{print $1";"$3";"$4";"$6";"$7";"$10";"$11";"$12 }' >> reporteFinal.csv


    rm -f reporteTMP1.dat
    rm -f reporteTMP2.dat
    rm -f reporteTMP3.dat
    rm -f reporteTMP4.dat
    rm -f reporteFinal.tmp

    exit 0
fi

echo "Alarma no Encendida!!" >> sumarizacion.log 

echo "---------------------------------------------------------------------------------------------------------- \n" >> sumarizacion.log

echo "ID;Tipo;Umbral;Archivo data;Estado;Promedio;Varianza;Scoop" > reporteFinal.csv
cat reporteFinal.tmp | awk -F"|" '{print $1";"$3";"$4";"$6";"$7";"$10";"$11";"$12 }' >> reporteFinal.csv

rm -f reporteTMP1.dat
rm -f reporteTMP2.dat
rm -f reporteTMP3.dat
rm -f reporteTMP4.dat
rm -f reporteFinal.tmp

exit 1










