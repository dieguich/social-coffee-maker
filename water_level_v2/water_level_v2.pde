/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab
The version 2 tries to swith on and off the RGB strip instead of a simple led.

**/

int pinToRead = 7;
//int BluePin = 6;                   // Digital Pin 9 Connected to B on Amp
int GreenPin = 10;                 // Digital Pin 10 Connected to G on Amp
int RedPin = 11;                   // Digital Pin 11 Connected to R on Amp


int readValue = 0;

int x = 0;     // Sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // Sets Off Level 255 = 0% (Higher Number will be dimmer)

void setup(){
  
  pinMode(pinToRead, INPUT);
  pinMode(GreenPin, OUTPUT);      // sets the digital pin as output
  pinMode(RedPin, OUTPUT);      // sets the digital pin as output

  analogWrite(GreenPin, x);
  analogWrite(RedPin, x);
  Serial.begin(9600);
  delay(1000);
  
  Serial.begin(9600);
}

void loop(){
  
  readValue = digitalRead(pinToRead);
  if (readValue == HIGH) {    
    // turn LED on:    
    analogWrite(RedPin, x);
    analogWrite(GreenPin, y);
  }
  else {
    // turn LED off:
    analogWrite(GreenPin, x);
    analogWrite(RedPin, y);
  }
  Serial.println(readValue);
  
  delay(500);
  
}

