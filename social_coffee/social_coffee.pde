
/**

Arduino Workshop @moreLAb

These set of sketches are to test the wether the level of a liquid in a tank is empty or full.
all of them are part of the coffe-machine2.0 project @Smartlab

This version 2 demonstrate how to post the water state (emty or full )of the coffe machine to its Twitter account @Social_Coffee.
In order to post on Twitter we use the Thing Speak social app: Available: https://www.thingspeak.com/apps/thingtweet

Furthermore, the coffe machine post when somebody is doing a coffe and the Energy that a coffe implies to make it. At the end of the day  the coffee machine posts the number of coffes after one day of hard work and the total effective Energy that have been used to prepare coffees and the part which have been wasted by misussing the coffee maker. 
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

/* define fixed values of pins to be used in the sketch */
#define POST_ENERGY     86400000
#define LIGHT_THRESHOLD 1
#define GREEN_PIN       3
#define RED_PIN         5
#define WATER_LEVEL_PIN 7       // pin to test the level of water in the coffee tank
#define CURRENT_PIN     A2      // pin to measure the current (Amperes)
#define ECHO_TO_SERIAL  0       // echo data to serial port (DEBUG mode)

/** Define and Setup for the RGB strip **/
int x = 0;       // sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // sets Off Level 255 = 0% (Higher Number will be dimmer)

/** Data for the Internet connection **/
//unsigned long m_prevTime = 0;
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

/** Twitter specific setup: ThingSpeak Settings**/
byte server[]  = { 184, 106, 153, 149 };         // IP Address for the ThingSpeak API (if DNS enabled you can directly set your DNSserver or use DHCP)
String thingtweetAPIKey = "7D794N24N8VC413J";    // write API Key for a ThingSpeak Channel
Client client(server, 80);

/* Relevant to tweet*/
int  tweetsCounter = 0;     // store the number of tweets posted by the coffee machine.
const char tweetDRYTxt[]   = "I'm empty, no coffe guys!! Coffees already done: ";
const char tweetGREATTxt[] = "I'm filled and prepared for keep you awake. Tweets: ";

/* variables to read water level values */
int readWaterLevel = 0;

/* variables to read light dependent resistor (LDR) values */
int lightMeasurePin = A4;  // pin to measure the luminosity
int readLuminosity = 0;
boolean labIsClose = false;

/*  Current */
float readCurrentValue = 0;       // to store the the current flow value [0..1024]
boolean currentIsFlowing = false; // to know if the previous state of the current measure

/* Time working */
unsigned long totalTimeOn        = 0.0; // the time that the coffee machine was operating (during the cicle of 24h)
unsigned long timeCount          = 0.0;  
unsigned long timeOn             = 0.0; // the time that the coffee machine was operating (One hot drink!)
unsigned long timeToTweetEConsum = 0;   // to store the time stamp when the Energy post was done

/* Number of coffees, Energy consumption & water level*/
boolean      coffeIsFull = true;
unsigned int nCoffee     = 0;   // number of coffees done by the coffee machine during a day.
float peakValue;                // value retrieved to know the current peak (calculate Energy consumption)


/************************************   
 * Specific Methods declared in this sketch
 ************************************/
const char*  ip_to_str(const uint8_t*); // format the Ip obtained.
const byte*  getIPbyDHCP();             // function to get a IP from DHCP service

void updateTwitterStatus(String);      // function to post on twitter.
void controlWaterLevel();              // algorithm to Control the coffee machine water level 
void controlCoffeMade();               // algorithm to measure the coffee machine current and coffe counter
void computeEnergyConsumed();          // algorithm to measure energy consumption and coffees made during a work day.

void setup(){

#if ECHO_TO_SERIAL  
  Serial.begin(9600); 
  Serial.println("Start");
#endif  
  /** Ethernet setup **/
  EthernetDHCP.begin(mac, 1);
  const byte* ipObtained = getIPbyDHCP();
  if(!ipObtained){
#if ECHO_TO_SERIAL  
  Serial.println("failed to obtain an IP Address");
#endif      
    //
    for(;;);
  }
  delay(1000); // wait 1 sec
#if ECHO_TO_SERIAL  
  Serial.print("IP gotten ");
  Serial.println(ip_to_str(ipObtained)); 
#endif        
  
  pinMode(CURRENT_PIN, INPUT);         // sets the analog pin as input (current measure throug the coffe machine plug -mains)
  pinMode(WATER_LEVEL_PIN, INPUT);     // sets the digital pin as input (water level)
  pinMode(lightMeasurePin, INPUT);     // sets the analog pin as input (light sensed) 
  pinMode(GREEN_PIN, OUTPUT);          // sets the digital pin as output
  pinMode(RED_PIN, OUTPUT);            // sets the digital pin as output

  timeToTweetEConsum = millis(); //time Stamp to know when the arduino begins to work.
  
  if(digitalRead(WATER_LEVEL_PIN) == HIGH){
    analogWrite(GREEN_PIN, y); //initialize pins to 255 (switch on)
    analogWrite(RED_PIN, x);   //initialize pins to 0 (switch off)  
  }
  else{
    analogWrite(GREEN_PIN, x); //initialize pins to 0 (switch off)
    analogWrite(RED_PIN, y);   //initialize pins to 255 (switch on)
    coffeIsFull = false;  
  }
  delay(1000); // wait 1 sec
}

void loop(){
  
  readWaterLevel   = digitalRead(WATER_LEVEL_PIN);
  readCurrentValue = analogRead(CURRENT_PIN);
  readLuminosity   = analogRead(lightMeasurePin);
  
#if ECHO_TO_SERIAL  
  //Serial.println(readWaterLevel); //if we want to debug and print the read value on the screen. 
#endif   
  
  /* TODO...Light Sensor
  if(readLuminosity < LIGHT_THRESHOLD){
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
  }*/
  
  controlCoffeMade();  
  if(!currentIsFlowing){
    controlWaterLevel();
  }
  if (millis() - timeToTweetEConsum > POST_ENERGY){ //   
    computeEnergyConsumed();
  }
  delay(500); // wait 0.5 sec
}

void controlSmartLabPresence(){
  
  delay(10000);
  if (analogRead(lightMeasurePin) < LIGHT_THRESHOLD){
          
    if(!labIsClose){             // if value lower than threshold turn on LED strip OFF and Lab was open --> close the lab
      analogWrite(GREEN_PIN, x); //initialize pins to 0 (switch off)
      analogWrite(RED_PIN, x);   //initialize pins to 0 (switch off)
      labIsClose = true;
      //TODO: Shift the relay to swithch off the coffee machine.
    }
  }
}


/** 
  This function controls when the coffee machine is operating. Not matter if is a peak, start time or coffee.
**/
void controlCoffeMade(){
  
  if ((readCurrentValue > 500) && (!currentIsFlowing)){ // if the machine is working (hot water) and it was idle in the previous loop.
  
      delay(2500);                           // to assure that it is not a coffe peak (fake coffee prepared)
      if(analogRead(CURRENT_PIN) > 500){
        
        char toConvert[5];
        String s_Coffees;
        String toTweet = "I'm preparing a hot drink. 2day I've prepared: ";
        
        currentIsFlowing = true;             // the state of the machine shift to working
        timeCount = millis();                // to calculate the time used to make the current coffee.
        peakValue = analogRead(CURRENT_PIN); // this is the peak value (Ampers) to compute after the Energy
        int coffeeAux = nCoffee + 1;
        s_Coffees = itoa(coffeeAux, toConvert, 10); // convert from integer to String
        toTweet += s_Coffees;                       // prepare the String to tweet
        //String toTweet = part1 + s_Coffees;
        if(!client.connected()){
          updateTwitterStatus(toTweet);
        }
        tweetsCounter++; //Tweets posted ++
      }
  }
   
  if ((readCurrentValue == 0) && (currentIsFlowing)){ // if the machine is idle and it was working in the previous loop.
      
      currentIsFlowing = false;              // the state of the machine shift to idle
      timeOn = millis()-timeCount-2500;      // compute the time used to prepare a coffee (2secons to establish the current to 0 after a hot drink made) 
      delay(3000);                           // wait 3 seconds
      if (analogRead(CURRENT_PIN) == 0){  
        totalTimeOn = totalTimeOn + timeOn;  // sumatory of partial times. It will be used afterwards to sumarize the whole energy consumption during a day
        timeOn = 0.0;
#if ECHO_TO_SERIAL  
        //Serial.print("coffee machine time working: ");
        //Serial.println(totalTimeOn);
#endif          
        nCoffee++;               // number of coffees counter ++
      }
      else{
        currentIsFlowing = true; // it was not a coffe (fake)
      }      
  } 
  delay(200);
}


void controlWaterLevel(){
  
  if (readWaterLevel == HIGH) {  // turn LED strip on --> Green color and post on Twitter  
    if(!coffeIsFull){            // Test if the previous state was Empty, then print a post a message on Twitter. 
      analogWrite(RED_PIN, x);
      analogWrite(GREEN_PIN, y);
      char test1[5];
      tweetsCounter++;
      String aux = itoa(tweetsCounter, test1, 10); // convert from integer to String
      String toPost = tweetGREATTxt + aux;         //prepare string to Post
      if(!client.connected()){
        updateTwitterStatus(toPost);
      }
      coffeIsFull = true;       //boolean to know the state change (Full --> Empty)
    }
  }
  else {                        // turn LED strip off --> Red color and post on Twitter  
    if(coffeIsFull){            // Test if the previous state was Full, then print a post a message on Twitter.
      analogWrite(GREEN_PIN, x);
      analogWrite(RED_PIN, y);    
      char test1[5];
      int coffeeAux = nCoffee;
      String aux = itoa(coffeeAux, test1, 10); // convert from integer to String
      String toPost = tweetDRYTxt + aux;       // prepare string to Post   
      Serial.println(toPost);
      if(!client.connected()){
        updateTwitterStatus(toPost);      
        tweetsCounter++;
      }
      coffeIsFull = false; //boolean to know the state change (Empty --> Full)
    }
  }
}
