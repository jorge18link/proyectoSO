#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <signal.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#define SHMSZ     4
int id,comm,tipo,maximo, modoDiscreto;
int shmid,*shm;

char *registros;
FILE * archivo;

void sig_handlerINT(int signo){
  if (signo == SIGINT){
    printf("\nParando ejecucion\n");
    close(shmid);
  }

  exit(1);
}

int main(int argc, char *argv[]) { 
    if (signal(SIGINT, sig_handlerINT) == SIG_ERR){
        printf("\n Error al obtener la senal\n");
    }
	
    if (argc != 7)  
    { 
        printf("\nnumero incorrecto de argumentos\n"); 
        return 0; 
    } 
  
    id           = atoi(argv[1]);
    tipo         = atoi(argv[2]);
    comm         = atoi(argv[3]);
    maximo       = atoi(argv[4]);
    
    registros    = argv[5];
    modoDiscreto = atoi(argv[6]);


    if ((shmid = shmget(comm, SHMSZ,  0666)) < 0) {
        perror("shmget");
        return(1);
    }

    if ((shm = shmat(shmid, NULL, 0)) == (int *) -1) {
        perror("shmat");
        return(1);
    }

    //Lo hago para borrar lo anterior
    archivo = fopen(registros,"w");
    fclose(archivo);

    int datoAnterior = *shm;
    int nuevoDato;
    int acumulador=0;

    int bandera = 0;
    int contador=0;

    float promedio;

    int contadorLineas=0;

    while(1){
        if(bandera == 0){
            
            if(tipo<=5){
                archivo = fopen(registros,"a");
                fprintf(archivo,"%d\n",datoAnterior);
                fclose(archivo);

                if(modoDiscreto!=1){
                    printf("\n---------------------------------------------\n");
                    printf("Dato actual: %d", datoAnterior);
                    printf("\n---------------------------------------------\n");
                }
                

            }else{
                contador++;
                acumulador = datoAnterior;
                promedio = datoAnterior;

                if(modoDiscreto!=1){
                    printf("\n---------------------------------------------\n");
                    printf("Dato actual: %d", datoAnterior);
                    printf("\nSu contador es: %d; Su acumulador es: %d", contador,acumulador);
                    printf("\nPromedio = %.0f", promedio);
                    printf("\n---------------------------------------------\n");
                }
                

                archivo = fopen(registros,"w");
                fprintf(archivo,"%.0f\n",promedio);
                fclose(archivo);
            }

            bandera = 1;
            usleep(10000);
        }else{
            nuevoDato = *shm;

            if (datoAnterior != nuevoDato){
                
                //Si el tipo es menor a 5 guardo todos los datos porque necesito calcular la variancia al ser competitivo
                if (tipo<=5){
                    int numeroActualLinea;
                    int existe=0;
                
                    archivo = fopen(registros,"a+");

                    contadorLineas=0;

                    while(feof(archivo)==0){
                        fscanf(archivo, "%d", &numeroActualLinea);
                        contadorLineas++;
                        if (numeroActualLinea==nuevoDato){
                            existe=1;
                            break;
                        }
                    }
                    fclose(archivo);

                    if(contadorLineas >= maximo){
                        //Escribo el ultimo regiistro
                        if(existe==0){
                            archivo = fopen(registros,"a");
                            fprintf(archivo,"%d\n",nuevoDato);
                            fclose(archivo);
                        }

                        archivo = fopen(registros,"a");
                        fprintf(archivo,"-1\n");
                        fclose(archivo);

                        if(modoDiscreto!=1){
                            printf("\n----------------------------------------------------------------------------------------------------------\n");
                            printf(" Ya no se reciben datos diferentes, llego a su maximo configurado (%d) este sensor pasa a estar inactivo", maximo);
                            printf("\n----------------------------------------------------------------------------------------------------------\n");
                        }

                        break;
                    }

                    if(existe==0){
                        archivo = fopen(registros,"a");
                        fprintf(archivo,"%d\n",nuevoDato);
                        fclose(archivo);
                    }
                    
                    if(modoDiscreto!=1){
                        printf("\n---------------------------------------------\n");
                        printf("Dato actual: %d", nuevoDato);
                        printf("\n---------------------------------------------\n");
                    }
                    

                }else{//Si el tipo es mayor a 5 guardo solo el promedio
                    contador++;
                    acumulador = acumulador + nuevoDato;
                    promedio = acumulador/contador;

                    if(modoDiscreto!=1){
                        printf("\n---------------------------------------------\n");
                        printf("Dato actual: %d", nuevoDato);
                        printf("\nSu contador es: %d; Su acumulador es: %d", contador,acumulador);
                        printf("\nPromedio = %.0f", promedio);
                        printf("\n---------------------------------------------\n");
                    }
                    
                    archivo = fopen(registros,"w");
                    fprintf(archivo,"%.0f\n",promedio);
                    fclose(archivo);
                }

                datoAnterior = nuevoDato;
            }
            usleep(10000);
        }
        
        if (*shm==-1){

            archivo = fopen(registros,"a");
            fprintf(archivo,"%d\n",*shm);
            fclose(archivo);

	        close(shmid);
            
            printf("\n%d\n",*shm);
	        break;
        }
    }


    exit(1);
}


