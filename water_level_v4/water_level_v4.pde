/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab

The version 4 tries to post its emty or full state to Twitter after 1 coffe more than the first detection.
In order to post on Twitter we use the Thing Speak app: Available: https://www.thingspeak.com/apps/thingtweet

**/

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
//#include <EthernetDNS.h>

/** Setup for the RGB strip **/
int GreenPin = 3;                 // Digital Pin 10 Connected to Green
int RedPin = 5;                   // Digital Pin 11 Connected to Red
int x = 0;       // Sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // Sets Off Level 255 = 0% (Higher Number will be dimmer)

/** variables to read level values **/
int pinToRead = 7;
int readValue = 0;


/** Data for the Internet connection **/
unsigned long m_prevTime = 0;
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

/** Twitter specific setup: ThingSpeak Settings**/
byte server[]  = { 184, 106, 153, 149 };         // IP Address for the ThingSpeak API (if DNS enabled you can directly set your DNSserver or use DHCP)
String thingtweetAPIKey = "CJH79S74PLHWLFAC";  // Write API Key for a ThingSpeak Channel
Client client(server, 80);

int   tweetsCounter = 0;
boolean coffeIsFull = true;
char tweetDRYTxt[] = "I'm empty, no coffe guys!! 1";
char tweetGREATTxt[] = "Filled and prepared for keep you asleep 1";

/************************************   
 * Specific Methods declared in this sketch
 ************************************/
const char* ip_to_str(const uint8_t*);
const byte* getIPbyDHCP();
void twitterPost(const char *);

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
  Serial.print(ip_to_str(ipObtained)); 
  
  pinMode(pinToRead, INPUT);    // sets the digital pin as input (water level)
  pinMode(GreenPin, OUTPUT);    // sets the digital pin as output
  pinMode(RedPin, OUTPUT);      // sets the digital pin as output

  analogWrite(GreenPin, x); //initialize pins to 0 (switch off)
  analogWrite(RedPin, x);   //initialize pins to 0 (switch off)
  
  delay(1000); // wait 1 sec
}

void loop(){
  
  readValue = digitalRead(pinToRead);
  //Serial.println(readValue); //if we want to debug and print the read value on the screen.
  
  if (readValue == HIGH) {  // turn LED strip on --> Green color and post on Twitter  
    analogWrite(RedPin, x);
    analogWrite(GreenPin, y);
    if(!coffeIsFull){  // Test if the previous state was Empty, then print a post a message on Twitter.
      Serial.println(tweetGREATTxt);
      if(!client.connected()){
        updateTwitterStatus(tweetGREATTxt);
      }
      //twitterPost(tweetGREATTxt);
      coffeIsFull = true;
    }
  }
  else {      //  turn LED strip off --> Red color and post on Twitter  
    analogWrite(GreenPin, x);
    analogWrite(RedPin, y);
    if(coffeIsFull){  // Test if the previous state was Full, then print a post a message on Twitter.
      Serial.println(tweetDRYTxt);
      if(!client.connected()){
      updateTwitterStatus(tweetDRYTxt);      
      }
      coffeIsFull = false;
    }
  }
  delay(500); // wait 0.5 sec
  
}

void updateTwitterStatus(String tsData)
{
  if (client.connect() && tsData.length() > 0)
  { 
    // Create HTTP POST Data
    tsData = "api_key="+thingtweetAPIKey+"&status="+tsData;
    
    Serial.println("Connected to ThingTweet...");
    Serial.println();
        
    client.print("POST /apps/thingtweet/1/statuses/update HTTP/1.1\n");
    client.print("Host: api.thingspeak.com\n");
    client.print("Connection: close\n");
    client.print("Content-Type: application/x-www-form-urlencoded\n");
    client.print("Content-Length: ");
    client.print(tsData.length());
    client.print("\n\n");

    client.print(tsData);
    
    delay(3000);
    
    Serial.println(client.available());
    while(client.available() > 0)
    {
      char c = client.read();
      Serial.print(c);
    }
    
    delay(3000);
    
    
    Serial.println("...disconnecting.");
    Serial.println();
    client.flush();
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
