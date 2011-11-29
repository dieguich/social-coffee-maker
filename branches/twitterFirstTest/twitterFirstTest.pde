#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>

unsigned long m_prevTime = 0;

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x1F, 0x86 };  //MAC address to use

// Your Token to Tweet (get it from http://arduino-tweet.appspot.com/)
//Twitter twitter("417809941-ZPwaCIhV8k53sBxJcCkdKhsm7iVCsiw6nA4Qpy76");

// ThingSpeak Settings
byte server[]  = { 184, 106, 153, 149 };         // IP Address for the ThingSpeak API
String thingtweetAPIKey = "CJH79S74PLHWLFAC";  // Write API Key for a ThingSpeak Channel
Client client(server, 80);

// Variable Setup
boolean lastConnected = false;

// Message to post
String msgToTwitter = "Hello @juanarmentia! I'm an Arduino at moreLAB (Diego's desk): works?";


/************************************   
 * Specific Methods declared in this sketch
 ************************************/
const char* ip_to_str(const uint8_t*);
const byte* getIPbyDHCP();

void setup()
{
  Serial.begin(9600);
  delay(1000);

  EthernetDHCP.begin(mac, 1);
  const byte* ipObtained = getIPbyDHCP();
  if(!ipObtained){
    Serial.println("failed to obtain an IP Address");
    for(;;);
  }

  delay(1000);
  Serial.print("IP gotten ");
  Serial.println(ip_to_str(ipObtained)); 
  
   if(!client.connected())
  {
    updateTwitterStatus(msgToTwitter);
  }
}
 
void loop()
{
  // Print Update Response to Serial Monitor
  if (client.available())
  {
    char c = client.read();
    Serial.print(c);
  }
  
  // Disconnect from ThingSpeak
  if (!client.connected() && lastConnected)
  {
    Serial.println();
    Serial.println("...disconnected.");
    Serial.println();
    client.flush();
    client.stop();
  }
  
  lastConnected = client.connected();
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
  }
  else
  {
    Serial.println("Connection Failed.");   
    Serial.println();
  }
}


