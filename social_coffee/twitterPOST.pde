
/**
  This fucntion publish a tweet to Twitter by POSTING to a server url the appropiate text with POST parameters.
**/
void updateTwitterStatus(String tsData)
{
  if (client.connect() && tsData.length() > 0)
  { 
    // Create HTTP POST Data
    String toPost = "api_key="+thingtweetAPIKey+"&status="; //prepare string to Post including API
    toPost.concat(tsData);
    toPost.trim();
      
    /*Send POST method to the Server*/    
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
    client.stop();
  }
  else
  {
    //Serial.println("Connection Failed.");   
    //Serial.println();
  }
}

