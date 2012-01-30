/**
  This funtion is called when a day has expired and the coffee machine is ready to post the summarize of the day.
  This function prints to the summary of the day and internally it calls to a string to send it to Twitter.
**/
void computeEnergyConsumed(){

  float  consum = 0.0;     //total Energy consumption 
  char   test[10];
  char   test1[5];
  String tweetSumarize = String("Today I have done ");
  String part2 = String(" coffees. Total power consumption: ");
  String part3 = String(" Wh");
  
  consum = peakValue*2.148*totalTimeOn; //  220V (Spain) *I (peak) * time_on/24h
  consum = consum/3600/1000;
  /*Serial.print("\n\nTotal time working: ");
  Serial.println(totalTimeOn/1000);
  Serial.print("Current measured: ");
  Serial.println(V*10/1024);//tweet consum
  Serial.print("Consum W/h: ");
  Serial.println(consum);
  Serial.print("Number of coffees: ");//tweet nCoffee*/

  String s_Coffees = itoa(nCoffee, test1, 10);            // convert from integer to String
  //Serial.println(s_Coffees);
    
  String consumWatt = floatToString(test, consum, 1, 4);  // convert from float to String
  //consumWatt = 
  consumWatt.concat(part3);
  String intermediate = s_Coffees + part2;
  tweetSumarize.concat(intermediate);
  String toPost = tweetSumarize + consumWatt;
  toPost = toPost.trim();                     // clear and eliminate the spaces and not relevant characters
  if(!client.connected()){
    updateTwitterStatus(toPost);
  }
  if(!client.connected()){
    int minutesWorking = totalTimeOn/(60*1000);
    String toPostTime  = "The coffee machine was working ";
    String toPostTime1 = " minutes during the day";
    toPostTime.concat(minutesWorking);
    toPostTime1 = toPostTime + toPostTime1;
    updateTwitterStatus(toPostTime1);
  }
  totalTimeOn = 0.0;             // reset totalTime that the coffe machine was on
  nCoffee     = 0;  // reset # of coffees
  consum      = 0.0;  //reset consumed energy
  timeToTweetEConsum = millis(); // restart time Stamp to know when the arduino begins to work.
  tweetsCounter++;
  
}
