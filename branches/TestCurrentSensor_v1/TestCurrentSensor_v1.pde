
/**
Sketch to read current. 
**/
#include <Time.h>

 #define O0 11
 #define O1 10
 #define O2 9
 #define O3 6
 #define O4 5
 #define O5 3


float readPin = 0;
boolean current = false;
unsigned long totalTimeOn = 0.0; 
unsigned long timeCount = 0.0;
unsigned long timeOn = 0.0;
int nCoffee = 0;
float consum; //consumo total
float V;
int nVeces =0;
boolean level = true;

void setup(){
  pinMode(A2, INPUT);
  Serial.begin(9600);
  delay(1000);
}

void loop(){
  
  readPin = analogRead(A2);
  //Serial.println(readPin);
    if ((readPin > 500)&&(!current)){
      //está echando agua caliente
      //Serial.println(readPin);
      current = true;
      timeOn = 0.0;
      timeCount = millis();//contador de tiempo parcial a funcionar
      V=readPin;
      Serial.println("Cafetera en funcionamiento"); //tweet
      nVeces++;
    }
    /*if ((readPin > 20)&&(readPin < 50)&&(!current)) {
      current = true;
      Serial.println("Cafetera echando agua fría"); //está echando agua fría
    }*/
    if ((readPin == 0)&&(current)){
      //no está funcionando
      current = false;
      timeOn = millis()-timeCount-2000; //parar contador de tiempo parcial
      delay(3000);
      if (readPin == 0){  
        totalTimeOn = totalTimeOn + timeOn; 
        //Serial.print("Tiempo en funcionamiento: ");
        //Serial.println(totalTimeOn);
        nCoffee++;
        Serial.println("Cafetera libre");
      }
      else{
        current = true;
      }      
    }
    delay(100);
    
    if (nVeces >2)/*hora == 00 AM*/{
      delay (4000);
      consum = 220*(V*10/1024)*totalTimeOn/(24*60*60*1000); //  220V*I*time_on/24h
      Serial.print("Tiempo total en funcionamiento");
      Serial.println(totalTimeOn);
      Serial.print("I: ");
      Serial.println(V*10/1024);//tweet consum
      Serial.print("Consumo W/h: ");
      Serial.println(consum);
      totalTimeOn = 0.0;
      Serial.print("Número de cafes: ");//tweet nCoffee
      Serial.println(nCoffee);
      nCoffee = 0;
      nVeces = 0;
    }
    
}

