#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <signal.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h> 

int dato=0;
int i;
int numero_hilos=0;

FILE * archivo;

void accionarConfiguracion();

int  tiempoEnMilis;


int main(int argc, char *argv[]){
    tiempoEnMilis={{tiempo}};
    accionarConfiguracion(); //Levanta los sensores de acuerdo al archivo de configuracion
    
    while(1){
        system("sh levantarMonitores.sh");
        usleep(tiempoEnMilis);
        system("sh pausarMonitores.sh");
        system("sh sensarData.sh");

        archivo = fopen("sumarizacion.log","r");
        int c;

        while((c=fgetc(archivo))!= EOF){
            putchar(c);
        }

        printf("\n");

        fclose(archivo);

    }
}

void accionarConfiguracion(){
    system("sh iniciarSensores.sh {{archivoConf}} {{velocidad}} 0");
}