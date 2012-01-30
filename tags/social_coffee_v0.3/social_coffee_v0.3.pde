/**

Arduino Workshop @moreLAb

This sketch is to test the wether the level of a liquid in a tank is empty or full.
This sketch is a first part of the coffe-machine2.0 @Smartlab

The version 3 tries to post its emty or full state to Twitter

**/
#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>
#include <Twitter.h>

/** Setup for the RGB strip **/
int GreenPin = 5;                 // Digital Pin 10 Connected to G on Amp
int RedPin = 3;                   // Digital Pin 11 Connected to R on Amp
int x = 0;     // Sets On Level 0 = 100% (Lower Number will be brighter)
int y = 255;     // Sets Off Level 255 = 0% (Higher Number will be dimmer)

/** variables to read level values **/
int pinToRead = 7;
int readValue = 0;


/** Data for the Internet connection **/
unsigned long m_prevTime = 0;
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

/** Twitter specific setup**/
// Your Token to Tweet (get it from http://arduino-tweet.appspot.com/)
Twitter twitter("410011004-CaWXVl5I1uUILIk8Vg4sn5SGUUHQGBFhjFB2dwco");

int   tweetsCounter = 0;
boolean coffeIsFull = true;
char tweetDRYTxt[] = "I'm empty, no coffe guys!! ";
char tweetGREATTxt[] = "Filled and prepared for make you asleep";

/************************************   
 * Specific Methods declared in this sketch
 ************************************/
const char* ip_to_str(const uint8_t*);
const byte* getIPbyDHCP();
void twitterPost(const char *);

void setup(){
 
  Serial.begin(9600);
    /** Ethernet **/
  EthernetDHCP.begin(mac, 1);
  const byte* ipObtained = getIPbyDHCP();
  if(!ipObtained){
    Serial.println("failed to obtain an IP Address");
    for(;;);
  }

  delay(1000);
  Serial.print("IP gotten ");
  Serial.print(ip_to_str(ipObtained)); 
  
  pinMode(pinToRead, INPUT);
  pinMode(GreenPin, OUTPUT);      // sets the digital pin as output
  pinMode(RedPin, OUTPUT);      // sets the digital pin as output

  analogWrite(GreenPin, x);
  analogWrite(RedPin, x);
  
  delay(1000);
}

void loop(){
  
  readValue = digitalRead(pinToRead);
  if (readValue == HIGH) {    
    // turn LED on:    
    analogWrite(RedPin, x);
    analogWrite(GreenPin, y);
    if(!coffeIsFull){
      Serial.println(tweetGREATTxt);
      //twitterPost(tweetGREATTxt);
      //Serial.println(tweetGREATTxt);      
      coffeIsFull = true;
    }
  }
  else {
    // turn LED off:
    analogWrite(GreenPin, x);
    analogWrite(RedPin, y);
    if(coffeIsFull){
      Serial.println(tweetDRYTxt);    
      //twitterPost(tweetDRYTxt);      
      coffeIsFull = false;
//      tweetsCounter++;
//      tweetTime = millis();
    }
  }
  //Serial.println(readValue);
  
  delay(500);
  
}

void twitterPost(const char* msgToTweet){
  
//  const char* msgToTweet = msg.c_str();
  if (twitter.post(msgToTweet)) {
    // Specify &Serial to output received response to Serial.
    // If no output is required, you can just omit the argument, e.g.
    // int status = twitter.wait();
    int status = twitter.wait(&Serial);
    if (status == 200) {
      Serial.println("OK.");
    } else {
      Serial.print("failed : code ");
      Serial.println(status);
    }
  } else {
    Serial.println("connection failed.");
  }

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
