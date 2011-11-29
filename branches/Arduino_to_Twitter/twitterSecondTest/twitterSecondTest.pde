// a brute test of twittering with arduino.
// source for handling the twitter api was http://pratham.name/post/39551949/twitter-php-script-without-curl
// the scetch lacks a lot of functionality, the encoding of username and password must be done separately
// and the message is fixed (text is "Yahoo, im twittering!")
//
// this is due to my ony basic knowledge
// maybe someone can use this snippet and have fun with it


#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 2, 10 };			    // this is the ip within my lan
byte gateway[] = { 192, 168, 2, 1 };			// neccessary to get access to the internet via your router
byte subnet[] = { 255, 255, 255, 0 };
byte server[] = { 128, 121, 146, 100 };		   // Twitter's ip

Client client(server, 80);

void setup()
{
  Ethernet.begin(mac, ip, gateway, subnet);
  Serial.begin(9600);

  delay(1000);
  Serial.println("connecting...");

  if (client.connect()) {
    Serial.println("connected");
    client.println("POST http://twitter.com/statuses/update.json HTTP/1.1");
    client.println("Host: twitter.com");
    client.println("Authorization: Basic #################");    // the string of ###s after "Basic" is the base64_encoded Text of username:password of your twitter account
												// you can do the encoding at this site: http://www.functions-online.com/en/base64_encode.html
    client.println("Content-type: application/x-www-form-urlencoded");
    client.println("Content-length: 28");					 // this is the length of the text "Yahoo, im twittering!"
    client.println("Connection: Close");
    client.println();
    client.print("status=Yahoo, im twittering!");

  } else {
    Serial.println("connection failed");
  }
}

void loop()
{
  if (client.available()) {
    char c = client.read();
    Serial.print(c);
  }

  if (!client.connected()) {
    Serial.println();
    Serial.println("disconnecting.");
    client.stop();
    for(;;)
	;
  }
} 
