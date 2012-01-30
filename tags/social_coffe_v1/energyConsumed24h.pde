void computeEnergyConsumed(){

  char test[10];
  char test1[5];
  String tweetSumarize = String("Today I have done ");
//  String first = String("Today I have done ");
//  String part1 = " coffees. Working ";
  String part2 = String(" coffees. Total power consumption: ");
  String part3 = String(" Wh");
  
  consum = 220*(V*10/1024)*totalTimeOn/(60*60*1000); //  220V (Spain) *I (peak) * time_on/24h
  /*Serial.print("\n\nTiempo total en funcionamiento: ");
  Serial.println(totalTimeOn/1000);
  Serial.print("Intensidad medida: ");
  Serial.println(V*10/1024);//tweet consum
  Serial.print("Consumo W/h: ");
  Serial.println(consum);
  Serial.print("Number of coffees: ");//tweet nCoffee*/

  String s_Coffees = itoa(nCoffee, test1, 10);  // convert from integer to String
  //Serial.println(s_Coffees);
    
  String consumWatt = floatToString(test, consum, 1, 4);  // convert from float to String
  //consumWatt = 
  consumWatt.concat(part3);
  String intermediate = s_Coffees + part2;
  tweetSumarize.concat(intermediate);
  String toPost = tweetSumarize + consumWatt;
  toPost = toPost.trim(); //clear and eliminate the spaces and not important characters
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
  if(!client.connected()){
    //updateTwitterStatus("please...why not working?");
    //delay(4000);
    //Serial.println("*****************");
    int minutesWorking = totalTimeOn/(60*1000);
    String toPostTime = "The coffee machine was working ";
    String toPostTime1 = " minutes during the day";
    toPostTime.concat(minutesWorking);
    toPostTime1 = toPostTime + toPostTime1;
    updateTwitterStatus(toPostTime1);
  }
  totalTimeOn = 0.0; //reset totalTime that the coffe machine was on
  nCoffee = 0; //reset # of coffees
  //nTimes = 0;
  timeToTweetEConsum = millis(); //restart time Stamp to know when the arduino begins to work.
  tweetsCounter++;
  
}
