/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab
**/

int pinToRead = 7;
int pinToBlink = 13;

int readValue = 0;

void setup(){
  
  pinMode(pinToRead, INPUT);
  pinMode(pinToBlink, OUTPUT);  
  
  Serial.begin(9600);
}

void loop(){
  
  readValue = digitalRead(pinToRead);
  if (readValue == HIGH) {    
    // turn LED on:    
    digitalWrite(pinToBlink, LOW);  
  }
  else {
    // turn LED off:
    digitalWrite(pinToBlink, HIGH);
  }
  //Serial.println(readValue);
  
  delay(500);
  
}

