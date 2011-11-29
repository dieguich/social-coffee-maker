void updateTwitterStatus(String tsData)
{
  //Serial.println(tsData);
  //Serial.println(tsData.length());
  if (client.connect() && tsData.length() > 0)
  { 
    // Create HTTP POST Data
    String toPost = "api_key="+thingtweetAPIKey+"&status="; //prepare string to Post including API
    toPost.concat(tsData);
    toPost.trim();
    //tsData = "api_key="+thingtweetAPIKey+"&status="+tsData;
    /*Serial.println(toPost);    
    Serial.println("Connected to ThingTweet...");
    Serial.println();*/
      
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
    
    
    //Serial.println("...disconnecting.");
    //Serial.println();
    //client.flush();
    client.stop();
  }
  else
  {
    //Serial.println("Connection Failed.");   
    //Serial.println();
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

