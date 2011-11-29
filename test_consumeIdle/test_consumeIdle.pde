/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab

The version 6 tries to post its emty or full state to Twitter after 1 coffe more than the first detection.
In order to post on Twitter we use the Thing Speak app: Available: https://www.thingspeak.com/apps/thingtweet
Furthermore, the coffe machine is ready to post when somebody is doing a coffe, the Energy that a coffe make waste and the total 
Energy consumption and number of coffes after one day of hard work.

It is an almost ready version to left the arduino in an stand-alone way. Post energy consumption after 24h
Note that the Serial constructor and methods are commented to debug only. Uncomment then when you want to see the debug info.

**/

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <string.h>
//#include <Time.h>

/* define fixed values of pins to be used in the sketch */
#define POST_ENERGY 86400000
#define LIGHT_THRESHOLD 1

/** Setup for the RGB strip **/
int GreenPin = 3;                 // Digital Pin 10 Connected to Green
int RedPin = 5;                   // Digital Pin 11 Connected to Red
int x = 0;       // Sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // Sets Off Level 255 = 0% (Higher Number will be dimmer)


/** Data for the Internet connection **/
unsigned long m_prevTime = 0;
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

/** Twitter specific setup: ThingSpeak Settings**/
byte server[]  = { 184, 106, 153, 149 };         // IP Address for the ThingSpeak API (if DNS enabled you can directly set your DNSserver or use DHCP)
String thingtweetAPIKey = "7D794N24N8VC413J";  // Write API Key for a ThingSpeak Channel
Client client(server, 80);

/* Relevant to tweet*/
int  tweetsCounter = 0; //The number of tweets posted by the coffee machine.
const char tweetDRYTxt[]   = "I'm empty, no coffe guys!! Coffees already done: ";
const char tweetGREATTxt[] = "I'm filled and prepared for keep you awake. Tweets: ";

/* variables to read water level values */
int waterLevelPin = 7;
int readWaterLevel = 0;

/* variables to read light dependent resistor (LDR) values */
int lightMeasurePin = A4; //Pin to measure the luminosity
int readLuminosity = 0;
boolean labIsClose = false;

/*  Current */
int currentMeasurePin = A2; //Pin to measure the current flow
float readCurrentValue = 0; // To store the the current flow value [0..1024]
boolean currentIsFlowing = false; //To know if the previous state of the current measure
boolean startHead = false; //To know if the values are started being saved

/* Time working */
unsigned long totalTimeOn = 0.0; //the time that the coffee machine was operating (during the cicle of 24h)
unsigned long timeCount = 0.0;  
unsigned long timeOn = 0.0; //the time that the coffee machine was operating (One hot drink!)
unsigned long timeToTweetEConsum = 0; //To store the time stamp when the Energy post was done

/* Number of coffees, Energy consumption & water level*/
boolean coffeIsFull = true;
unsigned int nCoffee = 0; // number of coffees done by the coffee machine during a day.
float consum; //total Energy consumption 
float V; //Value retrieved to know the current peak (calculate Energy consumption)


/************************************   
 * Specific Methods declared in this sketch
 ************************************/
const char* ip_to_str(const uint8_t*); //Format the Ip obtained.
const byte* getIPbyDHCP(); //Function to get a IP from DHCP service
void updateTwitterStatus(String); //Function to post on twitter.
void controlWaterLevel(); //Algorithm to Control the coffee machine water level 
void controlCoffeMade(); //Algorithm to measure the coffee machine current and coffe counter
void computeEnergyConsumed(); //Algorithm to measure energy consumption and coffees made during a work day.

void setup(){
 
  Serial.begin(9600); //Establish Serial connection with the laptop (for testing)
  /** Ethernet setup **/
  EthernetDHCP.begin(mac, 1);
  const byte* ipObtained = getIPbyDHCP();
  if(!ipObtained){
    //Serial.println("failed to obtain an IP Address");
    for(;;);
  }

  delay(1000); // wait 1 sec
  //Serial.print("IP gotten ");
  //Serial.println(ip_to_str(ipObtained)); 
  
  pinMode(currentMeasurePin, INPUT); // sets the analog pin as input (current measure throug the coffe machine plug -mains)
  //pinMode(waterLevelPin, INPUT);     // sets the digital pin as input (water level)
  //pinMode(lightMeasurePin, INPUT);   // sets the analog pin as input (light sensed) 
  pinMode(GreenPin, OUTPUT);         // sets the digital pin as output
  pinMode(RedPin, OUTPUT);           // sets the digital pin as output

  analogWrite(GreenPin, x); //initialize pins to 0 (switch off)
  analogWrite(RedPin, x);   //initialize pins to 0 (switch off)
  
  timeToTweetEConsum = millis(); //time Stamp to know when the arduino begins to work.
  
  delay(1000); // wait 1 sec
  Serial.print("#S|LOGTEST|["); //Command to save current values in arduinoCurrentValues.txt
  Serial.print("Empezamos: ");
  Serial.print(millis());
  Serial.println("]#");
}

void loop(){
  
  //readWaterLevel   = digitalRead(waterLevelPin);
  readCurrentValue = analogRead(currentMeasurePin);
  controlCoffeMade(); 
  //readLuminosity   = analogRead(lightMeasurePin);
  //Serial.println(readWaterLevel); //if we want to debug and print the read value on the screen. 
  /*if(readLuminosity < LIGHT_THRESHOLD){
    controlSmartLabPresence();  
  }
  else if(labIsClose){
    labIsClose = false;
    if(coffeIsFull){
      analogWrite(GreenPin, y); //initialize pins to 0 (switch off)
    }
    else{
      analogWrite(RedPin, y);   //initialize pins to 0 (switch off)
    }      
    //TODO Switch on the coffee machine
  }
  
  controlCoffeMade(); 
  if(!currentIsFlowing){
    controlWaterLevel();
  }
  
  if (millis() - timeToTweetEConsum > POST_ENERGY){ //   
    computeEnergyConsumed();
  }
  */
  
  //delay(500); // wait 0.5 sec
  
}

void controlSmartLabPresence(){
  
  delay(10000);
  if (analogRead(lightMeasurePin) < LIGHT_THRESHOLD){
          
    if(!labIsClose){ // if value lower than threshold turn on LED strip OFF and Lab was open --> close the lab
      analogWrite(GreenPin, x); //initialize pins to 0 (switch off)
      analogWrite(RedPin, x);   //initialize pins to 0 (switch off)
      labIsClose = true;
      //TODO: Shift the relay to swithch off the coffee machine.
    }
  }
}

void controlCoffeMade(){
  
  if((readCurrentValue > 20)){
    if ((!currentIsFlowing)){ //If the machine is working (hot water) and it was idle in the previous loop.
        Serial.print("#S|LOGTEST|["); //Command to save current values in arduinoCurrentValues.txt
        Serial.print(" millis: ");
        Serial.print(millis());
        Serial.print(" :");
      //delay(2500); // To assure that it is not a coffe peak (fake coffee prepared)
      //if(analogRead(currentMeasurePin) > 500){
        
        //char toConvert[5];
        //String s_Coffees;
        //String toTweet = "I'm preparing a hot drink. 2day I've prepared: ";
        String toTweet = "I've been activated myself. Working: ";        
        currentIsFlowing = true; //The state of the machine shift to working
        timeCount = millis();  // To calculate the time used to make the current coffee.
        V=readCurrentValue; // this is the peak value (Ampers) to compute after the Energy
        //int coffeeAux = nCoffee + 1;
        //s_Coffees = itoa(coffeeAux, toConvert, 10); // convert from integer to String
        //toTweet += s_Coffees; // Prepare the String to tweet
        //String toTweet = part1 + s_Coffees;
        //if(!client.connected()){
        //  updateTwitterStatus(toTweet);
        //}
        tweetsCounter++; //Tweets posted ++
        Serial.print(toTweet);
        Serial.print(tweetsCounter);
        Serial.println("]#");
         
      //}
    }
    if (!startHead){
      Serial.print("#S|LOGTEST|["); //Command to save current values in arduinoCurrentValues.txt
      startHead = true;
    }
    Serial.print("; ");
    Serial.print(readCurrentValue);
  }
  
  if ((readCurrentValue == 0) && (currentIsFlowing)){ //If the machine is idle and it was working in the previous loop.
      
      currentIsFlowing = false; //The state of the machine shift to idle
      timeOn = millis()-timeCount; //Compute the time used to prepare a coffee (2secons to establish the current to 0 after a hot drink made) 
      delay(100); //wait 3 seconds
      if (analogRead(currentMeasurePin) == 0){  
        totalTimeOn = totalTimeOn + timeOn; //Sumatory of partial times. It will be used afterwards to sumarize the whole energy consumption during a day
        Serial.println("]#");
        startHead = false;
        Serial.print("#S|LOGTEST|["); //Command to save current values in arduinoCurrentValues.txt
        Serial.print("Tiempo en funcionamiento: ");
        Serial.print(timeOn/1000.0);
        Serial.print(" -   Tiempo en funcionamiento acumulado: ");
        Serial.print(totalTimeOn/1000.0);
        Serial.println("]#");        
        timeOn = 0.0;
        //nCoffee++; // Coffee counter ++
        //Serial.println("Cafetera libre");
        Serial.println("#S|LOGTEST|[***************************************************************]#");

      }
      else{
        currentIsFlowing = true; //it was not a coffe (fake)
      }      
  } 
  delay(100);
}


void controlWaterLevel(){
  
  if (readWaterLevel == HIGH) {  // turn LED strip on --> Green color and post on Twitter  
    analogWrite(RedPin, x);
    analogWrite(GreenPin, y);
    if(!coffeIsFull){  // Test if the previous state was Empty, then print a post a message on Twitter. 
      char test1[5];
      tweetsCounter++;
      String aux = itoa(tweetsCounter, test1, 10); // convert from integer to String
      String toPost = tweetGREATTxt + aux; //prepare string to Post
      if(!client.connected()){
        updateTwitterStatus(toPost);
      }
      //twitterPost(tweetGREATTxt);
      coffeIsFull = true; //boolean to know the state change (Full --> Empty)
    }
  }
  else {      //  turn LED strip off --> Red color and post on Twitter  
    analogWrite(GreenPin, x);
    analogWrite(RedPin, y);
    if(coffeIsFull){  // Test if the previous state was Full, then print a post a message on Twitter.
      char test1[5];
      int coffeeAux = nCoffee + 1;
      String aux = itoa(coffeeAux, test1, 10); // convert from integer to String
      String toPost = tweetDRYTxt + aux;   //prepare string to Post   
      Serial.println(toPost);
      if(!client.connected()){
        updateTwitterStatus(toPost);      
        tweetsCounter++;
      }
      coffeIsFull = false; //boolean to know the state change (Empty --> Full)
    }
  }
}
