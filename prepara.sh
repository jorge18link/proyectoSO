#este shell recibe como parametro el nombre del archivo de configuracion y 
#el tiempo deltaT y la velocidad con la que quieres que se generen los datos
rm -f proyectoSAT2.c

cp proyectoSAT.c proyectoSAT2.c

echo "sed -i 's%{{archivoConf}}%$1%g' proyectoSAT2.c" > ejecuta.sh
chmod 777 ejecuta.sh
sh ejecuta.sh 
rm -f ejecuta.sh

echo "sed -i 's%{{tiempo}}%$2%g' proyectoSAT2.c" > ejecuta.sh
chmod 777 ejecuta.sh
sh ejecuta.sh 
rm -f ejecuta.sh

echo "sed -i 's%{{velocidad}}%$3%g' proyectoSAT2.c" > ejecuta.sh
chmod 777 ejecuta.sh
sh ejecuta.sh 
rm -f ejecuta.sh

gcc proyectoSAT2.c -o proyectoSO_SAT

exit 0