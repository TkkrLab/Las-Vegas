/* 
** 
** Used altered Z_OSC from site http://arduino.cc/playground/uploads/Interfacing/Z_OSC.zip
*/

#include <Stepper.h>
//Z_OSC
#include <SPI.h>
#include <Ethernet.h>   // version IDE 0022
#include "Z_OSC.h"    // version IDE 0022

unsigned long time; //keeping track of passed time

//Wheels
const int stepsPerRevolution = 200;  // change this to fit the number of steps per revolution
// for your motor

int wheelmax = 20; //max positions
int wheelspeed = 30; //max speed (35) of stepper moter (without hickups)

int wheelPosSteps[]= {0,0,0,0}; //Position in steps (0-stepsPerRevolution) 
int wheelNewPos[]= {0,0,0,0}; //New postion in pos (0-wheelmax)


//Current definition of the wheels
////                        1   2   3   4   5   6   7   8   9   0   1   2   3   4   5   6   7  8    9   0
//char* wheeldef[4][20]={ {"G","K","B","S","M","C","S","U","P","S","O","C","J","C","U","A","L","C","T","S"},
//                        {"G","U","P","C","U","T","K","L","C","K","O","K","J","P","S","A","U","M","P","S"},
//                        {"G","K","M","L","P","T","M","L","K","L","O","S","L","J","S","A","K","M","U","C"},
//                        {"G","S","C","L","S","T","C","K","L","U","O","U","J","M","C","A","S","P","C","S"}
//};


//Current definition of the wheels
/* 
 1 G BAR BAR BAR
 2 K Kers
 3 B Bel
 4 S Sinasapple
 5 M Meloen
 6 C Citroen
 7 U Pruim
 8 P Peer
 9 O BAR
10 J Joker
11 A BAR BAR
12 T Ster
*/

// Definition of rolls 20 in total
//
//                                                 1                             2
//                      1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0
int wheeldef[4][20]={ { 1, 2, 3, 4, 5, 6, 4, 7, 8, 4, 9, 6,10, 6, 7,11, 3, 6,12, 4},
                      { 1, 7, 8, 6, 7,12, 2, 3, 6, 2, 9, 2,10, 8, 4,11, 7, 5, 8, 4},
                      { 1, 2, 5, 3, 8,12, 5, 3, 2, 3, 9, 4, 3,10, 4,11, 2, 5, 7, 6},
                      { 1 ,4, 6, 3, 4,12, 6, 2, 3, 7, 9, 7,10, 5, 6,11, 4, 8, 6, 4}};
                                 
//Pin 0,1 is used for the Serial communication
//DO NOT USE pins 11, 12, and 13 on the Duemilanove are used for Ethernet shield
Stepper myStepper1(stepsPerRevolution, 2,3);            
Stepper myStepper2(stepsPerRevolution, 4,5);            
Stepper myStepper3(stepsPerRevolution, 6,7);            
Stepper myStepper4(stepsPerRevolution, 8,9);            

//z_OSC
///////////////////////////
Z_OSCMessage *rcvMes;
Z_OSCClient client;
Z_OSCServer server;
Z_OSCMessage message;

///////////////////////////////////////////////////////////////  
// SET THE RIGHT ADDRESS FOR ARDUINO 
///////////////////////////////////////////////////////////////
//byte myMac[]= {0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // TO SET ADDRESS MAC ARDUINO CARD
//byte myIp[] = { 192, 168, 100, 113 };      // TO SET ADDRESS IP ARDUINO CARD  
byte myMac[]= {0x0E, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // TO SET ADDRESS MAC ARDUINO CARD
byte myIp[] = { 10, 0, 0, 24 };      // TO SET ADDRESS IP ARDUINO CARD  
int  serverPort = 7000;                // TO SET RECEIVING PORT
//byte gateway[] = { 10, 0, 0, 250 };    // ROUTER
byte subnet[] = {255, 0, 0, 0 };    // SUBNET
byte destIp[] = {10, 0, 0, 120};      // TO SET ADDRESS IP COMPUTER
int  destPort = 8000;                  // TO SET SENDING PORT
///////////////////////////////////////////////////////////////  
///////////////////////////////////////////////////////////////  


void setup() {
  // initialize the serial port:
  Serial.begin(9600);

  // set the speed at max rpm
  myStepper1.setSpeed(wheelspeed);
  myStepper2.setSpeed(wheelspeed);
  myStepper3.setSpeed(wheelspeed);
  myStepper4.setSpeed(wheelspeed);  

  //Reset wheel positions
  //initWheels();
  
  //Ethernet.begin(serverMac ,serverIp);
  //Ethernet.begin(myMac ,myIp ,gateway ,subnet);
  Ethernet.begin(myMac ,myIp ,subnet);

  //setting osc receive server  
  server.sockOpen(serverPort);
  
  //Message to datadirigent
  time = millis();
  sendOSCinputs();  

  Serial.println("Setup done");



}

void loop() {
  int spinWheelsSeed=0;
  float floatValue=0;
  
  if ( server.available() ) {   //check if osc arrive 
    rcvMes=server.getMessage();
    rcvMes->setPortNumber(destPort);
    //Process message
    //spinWheels();
    Serial.print("Check for OSC message");
    if( !strcmp( rcvMes->getZ_OSCAddress() , "/pwm/1" ) ){
      //speedM1= rcvMes->getInteger32(0);
      floatValue = rcvMes->getFloat(0);   
      spinWheelsSeed = (int) floatValue*1000;
    }
    
    spinWheels(spinWheelsSeed);          

  }
  
 //for testing/debugin    
 if (Serial.available() > 0) {
  int incomingByte=0; 

  Serial.println("Press 1-4 for adjust wheel, abcd to spin the wheels");

  // read the incoming byte:
  incomingByte = Serial.read();

  switch (incomingByte) {
        case '1':
          spinWheels_oneStep(0);       
          break;
        case '2':    
          spinWheels_oneStep(1);       
          break;
        case '3':    
          spinWheels_oneStep(2);       
          break;
        case '4':    
          spinWheels_oneStep(3);       
          break;
        case 'a':    
          spinWheels_simple();
          break;
        case 'b':    
          spinWheels(0);
          break;
        case 'c':    
          spinWheels(1337);
          break;
        case 'd':    
          spinWheels(42);
          break;
        case 'z':    
          printarray();
          break;
        } 
  Serial.println("Done my work, next command please:");      
  }; //end serial

  //Send every 10 secs message for datadirigent 
  if (millis()-time>60000){
    sendOSCinputs();  
    time = millis();
  };
    
}//end loop

void spinWheels_oneStep(int wheel) {
  Serial.println("Function onestep");
 
  int npos =1;
  switch (wheel) {
  case 0:
    myStepper1.step(npos);
    break;
  case 1:
    myStepper2.step(npos);
    break;
  case 2:
    myStepper3.step(npos);
    break;
  case 3:
    myStepper4.step(npos);
    break;
  }
}


void spinWheels_simple() {
  Serial.println("Function Simple");
 
  int spin=stepsPerRevolution;
   myStepper1.step(spin+(random(wheelmax)*10));
   myStepper2.step(spin+(random(wheelmax)*10));
   myStepper3.step(spin+(random(wheelmax)*10));
   myStepper4.step(spin+(random(wheelmax)*10));
}
  
void spinWheels(int seed) {
  Serial.println("Function SpinWheels");
 
  Serial.print("Seed=");
  Serial.println(seed,DEC);
  
  
  Serial.println("Determine new pos\n");
//  if (seed==0) {
//    //Determine random pos for wheels
//    for(int i=0;i<4;i++) {
//      wheelNewPos[i] = random(wheelmax);
//      }
//   } else
   if (seed==1337) {
      //Test set all to Jokers
      wheelNewPos[0] = 0;
      wheelNewPos[1] = 0;
      wheelNewPos[2] = 0;//13 indien 
      wheelNewPos[3] = 0;
   } else if (seed==42) {
      //Test set all to BARBARBAR
      wheelNewPos[0] = 10;
      wheelNewPos[1] = 10;
      wheelNewPos[2] = 10; 
      wheelNewPos[3] = 10;
   }else { 
    for(int i=0;i<4;i++) {
      wheelNewPos[i] = random(wheelmax);
      }
   }
   

    //Debug print val 
    for(int i=0;i<4;i++) {
      Serial.print("Wheel :");
      Serial.print(i,DEC);
      Serial.print(" Random : ");
      Serial.println(wheelNewPos[i],DEC);
    }

    //Set position for each wheel
    for(int i=0;i<4;i++) {
      setWheel(i,wheelNewPos[i]);    
    }

    //Did we win something?
    int win =0;
    win = checkWin();

    //if we win : Send OSC Message
    if (win!=0){
      message.setAddress(destIp,destPort);
      client.send(&message);
      float valSW2=((float) win)/1000;
      message.setZ_OSCMessage("lasvegas/win" , "f", &valSW2);
      client.send(&message);
  
      message.flush();
      Serial.print("\nSend OSC message :");
      Serial.println(win,DEC);
    }
}

void setWheel(int wheel, int pos) {
  Serial.println("====SetWheel===");
  Serial.print("Setwheel:");
  Serial.println(wheel,DEC);
  Serial.print("To Position :");
  Serial.println(pos,DEC);
    
  int oneStepPos = stepsPerRevolution/wheelmax; // 200/20 so 10 
  int setSteps = 0;

  //steps to return to 0  
  Serial.print("Current step:");
  Serial.println(wheelPosSteps[wheel],DEC);
  
  //Methode 1 
  //setSteps=wheelPosSteps[wheel]%stepsPerRevolution; 
  //setSteps=stepsPerRevolution-setSteps; //roll till next 0 pos
  //setSteps  += (pos*oneStepPos); //add pos

  //Methode 2
  setSteps=stepsPerRevolution-wheelPosSteps[wheel]+(pos*oneStepPos); //roll till next 0 pos
  
  //force to make at least one turn
  if (setSteps<200){
    setSteps +=200;
  }; 
  
  Serial.print("Steps to new pos:");
  Serial.println(setSteps,DEC);
  
  Serial.print("Symbol:");
  int symbol =(int) wheeldef[wheel,pos];
  Serial.print(symbol,DEC);  
  Serial.print(" that should be a ");
  Serial.print(printSymbol(symbol));
 
  //store position for next run
  wheelPosSteps[wheel]=(pos*oneStepPos);
  
  switch (wheel) {
  case 0:
    myStepper1.step(setSteps);
    break;
  case 1:
    myStepper2.step(setSteps);
    break;
  case 2:
    myStepper3.step(setSteps);
    break;
  case 3:
    myStepper4.step(setSteps);
    break;
  }
}

int checkWin() {
    int win =0;
    for(int i=1;i<3;i++) {
      if ((int) wheeldef[i-1,wheelNewPos[i-1]]== (int) wheeldef[i,wheelNewPos[i]] ){
        win++;
    }
  }
  return win;
}

void printarray(){
  for(int wheel=0;wheel<4;wheel++) {
    for(int pos=0;pos<20;pos++) {
       Serial.print("Symbol:");
       Serial.println(printSymbol((int)  wheeldef[wheel,pos] )); //or BIN BYTE
    }
  }
}

void sendOSCinputs(){
  //Send message to datadirigent 
  message.setAddress(destIp,destPort);
  client.send(&message);
  //int valSW2=0;
  //message.setZ_OSCMessage("/lasvegas/2" , "i", &valSW2);
  char* valST1="spin";
  message.setZ_OSCMessage("lasvegas/out/inputs","s",valST1);
  client.send(&message);
  char* valST2="win";
  message.setZ_OSCMessage("lasvegas/out/outputs","s",valST2);
  client.send(&message);
  
  message.flush();
}

char* printSymbol(int symbol){
   /*
 1 G BAR BAR BAR
 2 K Kers
 3 B Bel
 4 S Sinasapple
 5 M Meloen
 6 C Citroen
 7 U Pruim
 8 P Peer
 9 O BAR
10 J Joker
11 A BAR BAR
12 T Ster
*/
  
  switch (symbol) {
  case 1:
    return "BAR BAR BAR";
    break;
  case 2:
    return "Kers";
    break;
  case 3:
    return "Klok";
    break;
  case 4:
    return "Sinasapple";
    break;
  default:
    return "unkown"; 
  }
 
}

//void initWheels(){
//  int button = analogRead(3);
// 
//  while(button!=0) {
//     myStepper1.step(1);
//     button = analogRead(3);
//  }
     
// 
//  //readbutton  
//  // while button<>0 
//
// 
//   if (button == 0)
//   {
//   Serial.println ("button1");
//   }
//   if (button == 47)
//   {
//   Serial.println ("button2");
//   }
//   if (button == 107)
//   {
//   delay (200);
//   Serial.println ("button3");
//   }
//   if (button == 325)
//   {
//   delay (200);
//   Serial.println ("button4");
//   }
//   if (button == 33)
//   {
//   delay (200);
//   Serial.println ("button 2 and 3");
// }
//}

