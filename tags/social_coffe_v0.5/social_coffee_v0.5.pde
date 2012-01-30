/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab

The version 5 tries to post its emty or full state to Twitter after 1 coffe more than the first detection.
In order to post on Twitter we use the Thing Speak app: Available: https://www.thingspeak.com/apps/thingtweet
Furthermore, the coffe machine is ready to post when somebody is doing a coffe, the Energy that a coffe make waste and the total 
Energy consumption and number of coffes after one day of hard work.

**/

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <string.h>
//#include <Time.h>

/* define fixed values of pins to be used in the sketch */
#define O0 11
#define O1 10
#define O2 9
#define O3 6
#define O4 5
#define O5 3
#define POST_ENERGY 8640000

/** Setup for the RGB strip **/
int GreenPin = 3;                 // Digital Pin 10 Connected to Green
int RedPin = 5;                   // Digital Pin 11 Connected to Red
int x = 0;       // Sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // Sets Off Level 255 = 0% (Higher Number will be dimmer)

/** variables to read water level values **/
int waterLevelPin = 7;
int readWaterLevel = 0;

int currentMeasurePin = A2;
float readCurrentValue = 0;
boolean current = false; //To know if the previous state of the current measure
unsigned long totalTimeOn = 0.0; //the time that the coffee machine was operating (during a coffee make)
unsigned long timeCount = 0.0;  
unsigned long timeOn = 0.0;
int nCoffee = 0; // number of coffees done by the coffee machine during a day.
float consum; //total Energy consumption 
float V; //Value retrieved to know the current peak (calculate Energy consumption)
//int nTimes =0;
long timeToTweetEConsum = 0;


/** Data for the Internet connection **/
unsigned long m_prevTime = 0;
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

/** Twitter specific setup: ThingSpeak Settings**/
byte server[]  = { 184, 106, 153, 149 };         // IP Address for the ThingSpeak API (if DNS enabled you can directly set your DNSserver or use DHCP)
String thingtweetAPIKey = "7D794N24N8VC413J";  // Write API Key for a ThingSpeak Channel
Client client(server, 80);

int   tweetsCounter = 0; //The number of tweets posted
boolean coffeIsFull = true;
char tweetDRYTxt[] = "I'm empty, no coffe guys!! Coffees already done: ";
char tweetGREATTxt[] = "I'm filled and prepared for keep you awake. Tweets: ";

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
    Serial.println("failed to obtain an IP Address");
    for(;;);
  }

  delay(1000); // wait 1 sec
  Serial.print("IP gotten ");
  Serial.println(ip_to_str(ipObtained)); 
  
  pinMode(currentMeasurePin, INPUT); // sets the analog pin as input (current measure throug the coffe machine plug -mains)
  pinMode(waterLevelPin, INPUT); // sets the digital pin as input (water level)
  pinMode(GreenPin, OUTPUT);    // sets the digital pin as output
  pinMode(RedPin, OUTPUT);      // sets the digital pin as output

  analogWrite(GreenPin, x); //initialize pins to 0 (switch off)
  analogWrite(RedPin, x);   //initialize pins to 0 (switch off)
  
  timeToTweetEConsum = millis(); //time Stamp to know when the arduino begins to work.
  delay(1000); // wait 1 sec
}

void loop(){
  
  readWaterLevel = digitalRead(waterLevelPin);
  readCurrentValue = analogRead(currentMeasurePin);
  //Serial.println(readWaterLevel); //if we want to debug and print the read value on the screen.
  controlWaterLevel(); 
  controlCoffeMade();  
  
  if (millis() - timeToTweetEConsum > POST_ENERGY)/*hora == 00 AM*/{  
    computeEnergyConsumed();
  }
  
  delay(500); // wait 0.5 sec
  
}

void controlCoffeMade(){
  
  if ((readCurrentValue > 500) && (!current)){ //If the machine is working (hot water) and it was idle in the previous loop.
  
      delay(2500);
      if(analogRead(currentMeasurePin) > 500){
        char toConvert[5];
        String s_Coffees;
        String toTweet = "I'm preparing a hot drink. 2day I've prepared: ";
        current = true; //The state of the machine shift to working
        timeOn = 0.0;
        timeCount = millis();  // To calculate the time used to make the current coffee.
        V=readCurrentValue;
        //nTimes++; //It will be changed to do the summary after 24h
        s_Coffees = itoa(nCoffee+1, toConvert, 10);
        toTweet += s_Coffees;
        //String toTweet = part1 + s_Coffees;
        if(!client.connected()){
          updateTwitterStatus(toTweet);
        }
        tweetsCounter++;
      }
  }
    /*if ((readCurrentValue > 20)&&(readCurrentValue < 50)&&(!current)) {
      current = true;
      Serial.println("Cafetera echando agua fría"); //está echando agua fría
    }*/
  if ((readCurrentValue == 0) && (current)){ //If the machine is idle and it was working in the previous loop.
      
      current = false; //The state of the machine shift to idle
      timeOn = millis()-timeCount-2000; //Compute the time used to prepare a coffe
      delay(3000); //wait 3 seconds
      if (analogRead(currentMeasurePin) == 0){  //he cambiado por readCurrentValue
        totalTimeOn = totalTimeOn + timeOn; //Sumatory of partial times. It will be used afterwards to sumarize the whole energy consumption during a day
        //Serial.print("Tiempo en funcionamiento: ");
        //Serial.println(totalTimeOn);
        nCoffee++; // Coffee counter
        //Serial.println("Cafetera libre");
      }
      else{
        current = true;
      }      
  } 
  
  delay(200);
}

void computeEnergyConsumed(){

  char test[10];
  char test1[5];
  String tweetSumarize = String("Today I have done ");
//  String first = String("Today I have done ");
//  String part1 = " coffees. Working ";
  String part2 = String(" coffees. Total power consumption: ");
  String part3 = String(" Watt/h");
  
  consum = 220*(V*10/1024)*totalTimeOn/(24*60*60*1000); //  220V (Spain) *I (peak) * time_on/24h
  /*Serial.print("\n\nTiempo total en funcionamiento: ");
  Serial.println(totalTimeOn/1000);
  Serial.print("Intensidad medida: ");
  Serial.println(V*10/1024);//tweet consum
  Serial.print("Consumo W/h: ");
  Serial.println(consum);
  Serial.print("Number of coffees: ");//tweet nCoffee*/

  String s_Coffees = itoa(nCoffee, test1, 10);
  //Serial.println(s_Coffees);
    
  String consumWatt = floatToString(test, consum, 1, 4);
  //consumWatt = 
  consumWatt.concat(part3);
  String intermediate = s_Coffees + part2;
  tweetSumarize.concat(intermediate);
  String toPost = tweetSumarize + consumWatt;
  toPost = toPost.trim();
  //Serial.print(" Lenght: ");
  //Serial.println(toPost.length());
  //delay(400);
  //Serial.println(toPost);
  if(!client.connected()){
    //updateTwitterStatus("please...why not working?");
    //delay(4000);
    //Serial.println("*****************");
    updateTwitterStatus(toPost);
  }
  totalTimeOn = 0.0;
  nCoffee = 0;
  //nTimes = 0;
  timeToTweetEConsum = millis(); //time Stamp to know when the arduino begins to work.
  tweetsCounter++;
  
}
  
void controlWaterLevel(){
  
  if (readWaterLevel == HIGH) {  // turn LED strip on --> Green color and post on Twitter  
    analogWrite(RedPin, x);
    analogWrite(GreenPin, y);
    if(!coffeIsFull){  // Test if the previous state was Empty, then print a post a message on Twitter. 
      char test1[5];
      String aux = itoa(tweetsCounter, test1, 10);
      String toPost = tweetGREATTxt + aux;
      if(!client.connected()){
        updateTwitterStatus(toPost);
        tweetsCounter++;
      }
      //twitterPost(tweetGREATTxt);
      coffeIsFull = true;
    }
  }
  else {      //  turn LED strip off --> Red color and post on Twitter  
    analogWrite(GreenPin, x);
    analogWrite(RedPin, y);
    if(coffeIsFull){  // Test if the previous state was Full, then print a post a message on Twitter.
      char test1[5];
      String aux = itoa(nCoffee, test1, 10);
      String toPost = tweetDRYTxt + aux;      
      Serial.println(toPost);
      if(!client.connected()){
        updateTwitterStatus(toPost);      
        tweetsCounter++;
      }
      coffeIsFull = false;
    }
  }
}

void updateTwitterStatus(String tsData)
{
  Serial.println(tsData);
  Serial.println(tsData.length());
  if (client.connect() && tsData.length() > 0)
  { 
    // Create HTTP POST Data
    String toPost = "api_key="+thingtweetAPIKey+"&status=";
    toPost.concat(tsData);
    toPost.trim();
    tsData = "api_key="+thingtweetAPIKey+"&status="+tsData;
    /*Serial.println(toPost);    
    Serial.println("Connected to ThingTweet...");
    Serial.println();*/
        
    client.print("POST /apps/thingtweet/1/statuses/update HTTP/1.1\n");
    client.print("Host: api.thingspeak.com\n");
    client.print("Connection: close\n");
    client.print("Content-Type: application/x-www-form-urlencoded\n");
    client.print("Content-Length: ");
    client.print(toPost.length());
    client.print("\n\n");

    client.print(toPost);
    
    delay(3000);
    
    while(client.available() > 0)
    {
      char c = client.read();
      //Serial.print(c);
    }
    
    delay(3000);
    
    
    Serial.println("...disconnecting.");
    Serial.println();
    //client.flush();
    client.stop();
  }
  else
  {
    Serial.println("Connection Failed.");   
    Serial.println();
  }
  // Disconnecting from ThingSpeak.
  /*if(!client.connected()){
    Serial.println();
    Serial.println("...disconnecting.");
    Serial.println();
    client.flush();
    client.stop();
  }*/
}

/***********************************************
 * Code to get suitable IP-address by DHCP Service
 ***********************************************/
const byte* getIPbyDHCP(){

  static DhcpState prevState = DhcpStateNone;
  //  unsigned long m_prevTime = 0;
  unsigned long interval = 10000;
  unsigned long previousMillis = 0;        // will store last time LED was updated
  const byte* ipAddr = NULL;

  while(prevState != DhcpStateLeased)
  {
    DhcpState state = EthernetDHCP.poll();
    if (prevState != state)
    {
      Serial.println();

      switch (state) {  
      case DhcpStateDiscovering:
        Serial.print("Discovering servers.");
        break;
      case DhcpStateRequesting:
        Serial.print("Requesting lease.");
        break;
      case DhcpStateRenewing:
        Serial.print("Renewing lease.");
        break;
      case DhcpStateLeased: 
        {
          Serial.println("Obtained lease!");

          // Since we're here, it means that we now have a DHCP lease, so we
          // print out some information.
          ipAddr = EthernetDHCP.ipAddress();
          m_prevTime = 0;
          break;
        }  
      }
    }
    else if (state != DhcpStateLeased && millis() - m_prevTime > 200)
    {
      m_prevTime = millis();
      Serial.print('.');
      if (millis() - previousMillis > interval) {
        previousMillis = millis();
        Serial.println("\ntime out");
        return NULL;   
      }
    }
    prevState = state;
  }
  return ipAddr;
}

/***********************************************
 * Just a utility function to nicely format an IP address.
 ***********************************************/
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}


char * floatToString(char * outstr, double val, byte precision, byte widthp){
  char temp[16];
  byte i;

  // compute the rounding factor and fractional multiplier
  double roundingFactor = 0.5;
  unsigned long mult = 1;
  for (i = 0; i < precision; i++)
  {
    roundingFactor /= 10.0;
    mult *= 10;
  }
  
  temp[0]='\0';
  outstr[0]='\0';

  if(val < 0.0){
    strcpy(outstr,"-\0");
    val = -val;
  }

  val += roundingFactor;

  strcat(outstr, itoa(int(val),temp,10));  //prints the int part
  if( precision > 0) {
    strcat(outstr, ".\0"); // print the decimal point
    unsigned long frac;
    unsigned long mult = 1;
    byte padding = precision -1;
    while(precision--)
      mult *=10;

    if(val >= 0)
      frac = (val - int(val)) * mult;
    else
      frac = (int(val)- val ) * mult;
    unsigned long frac1 = frac;

    while(frac1 /= 10)
      padding--;

    while(padding--)
      strcat(outstr,"0\0");

    strcat(outstr,itoa(frac,temp,10));
  }

  // generate space padding
  if ((widthp != 0)&&(widthp >= strlen(outstr))){
    byte J=0;
    J = widthp - strlen(outstr);
    
    for (i=0; i< J; i++) {
      temp[i] = ' ';
    }

    temp[i++] = '\0';
    strcat(temp,outstr);
    strcpy(outstr,temp);
  }
  
  return outstr;
} 
