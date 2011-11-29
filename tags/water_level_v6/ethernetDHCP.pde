


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
      //Serial.println();

      switch (state) {  
      case DhcpStateDiscovering:
        //Serial.print("Discovering servers.");
        break;
      case DhcpStateRequesting:
        //Serial.print("Requesting lease.");
        break;
      case DhcpStateRenewing:
        //Serial.print("Renewing lease.");
        break;
      case DhcpStateLeased: 
        {
          //Serial.println("Obtained lease!");

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
      //Serial.print('.');
      if (millis() - previousMillis > interval) {
        previousMillis = millis();
        //Serial.println("\ntime out");
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
