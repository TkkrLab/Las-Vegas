/* 
** 
** Used altered Z_OSC from site http://arduino.cc/playground/uploads/Interfacing/Z_OSC.zip
*/

// TODO : lasvegas/out/output “spin″


#include <Stepper.h>
//Z_OSC
#include <SPI.h>
#include <Ethernet.h>   // version IDE 0022
#include "Z_OSC.h"    // version IDE 0022

//Wheels
const int stepsPerRevolution = 200;  // change this to fit the number of steps per revolution
// for your motor

int wheelpos[]= {0,0,0,0};
int wheelnew[]= {0,0,0,0};
int wheelmax = 20;
int wheelspeed = 35;

char wheeldef[4][20]={ {'G','K','B','S','M','C','S','U','P','S','O','C','J','C','U','A','L','C','T','S'},
                       {'G','U','P','C','U','T','K','L','C','K','O','K','J','P','S','A','U','M','P','S'},
                       {'G','K','M','L','P','T','M','L','K','L','O','S','L','J','S','A','K','M','U','C'},
                       {'G','S','C','L','S','T','C','K','L','U','O','U','J','M','C','A','S','P','C','S'}};

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
byte myMac[]= {
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // TO SET ADDRESS MAC ARDUINO CARD
byte myIp[] = { 192, 168, 100, 113 };      // TO SET ADDRESS IP ARDUINO CARD  
int  serverPort = 10011;                // TO SET RECEIVING PORT
//byte gateway[] = { 192, 168, 1, 1 };    // ROUTER
byte subnet[] = {255, 255, 255, 0 };    // SUBNET
byte destIp[] = {192, 168, 100, 250};      // TO SET ADDRESS IP COMPUTER
int  destPort = 10012;                  // TO SET SENDING PORT
///////////////////////////////////////////////////////////////  
///////////////////////////////////////////////////////////////  


void setup() {
  //Ethernet.begin(serverMac ,serverIp);
  //Ethernet.begin(myMac ,myIp ,gateway ,subnet);
  Ethernet.begin(myMac ,myIp ,subnet);
  //setting osc receive server
  server.sockOpen(serverPort);

  // set the speed at 35 rpm, is current max so dont increase
  myStepper1.setSpeed(wheelspeed);
  myStepper2.setSpeed(wheelspeed);
  myStepper3.setSpeed(wheelspeed);
  myStepper4.setSpeed(wheelspeed);
  
  // initialize the serial port:
  //SoftwareSerial Serial(6, 7);
  Serial.begin(9600);

  //Reset wheel positions
  //initWheels();

}

//Serial.println("Enter a letter A:");
 

void loop() {
  int spinWheelsRandom=0;
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
      spinWheelsRandom = (int) floatValue*1000;
    }
    
    spinWheels(spinWheelsRandom);          

  }
     
 if (Serial.available() > 0) {
 		Serial.println("Press 1-4 for adjust wheel, A or B to spin the wheels");

  int incomingByte=0; 
  // read the incoming byte:
  incomingByte = Serial.read();

  // say what you got:
  Serial.print("I received Serial: ");
  Serial.println(incomingByte, DEC);
 
  
  if ((incomingByte =49)|(incomingByte =50)|(incomingByte =51)|(incomingByte =52)){ 
    int wheel=incomingByte-49;
    spinWheels__oneStep(wheel);          
  };
  
  if (incomingByte =65){ 
    spinWheels_simple(incomingByte);          
  };
  if (incomingByte =66){ 
    spinWheels_simple(incomingByte);          
  };
 
 } 
}


void spinWheels_oneStep(int wheel) {
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


void spinWheels_simple(int seed) {
  int spin=200;
   myStepper1.step(spin+(random(wheelmax)*10));
   myStepper2.step(spin+(random(wheelmax)*10));
   myStepper3.step(spin+(random(wheelmax)*10));
   myStepper4.step(spin+(random(wheelmax)*10));
  }
  
void spinWheels(int seed) {
  Serial.print("Seed=");
  Serial.println(seed,DEC);
  
  int prevwheel = 0;
  int win =0;
  
  Serial.println("Check for speed\n");
  //if (seed=0) {
    //Determine random pos for wheels
    for(int i=0;i<4;i++) {
      wheelnew[i] = random(wheelmax);
      Serial.print("Wheel :");
      Serial.println(i,DEC);
      Serial.print("Random : ");
      Serial.println(wheelnew[i],DEC);
   // }
    
    if (seed=96){
      wheelnew[0] = 1;
      wheelnew[1] = 1;
      wheelnew[2] = 1;
      wheelnew[3] = 1;
    }

    //Set position for each wheel

    for(int i=0;i<4;i++) {
      setWheel(i,wheelnew[i]);
      //Serial.print("\nSet Wheel :");
      //Serial.println(wheelnew[i],DEC);      
    }

    //TODO: Did we win something?
//    prevwheel = wheelnew[0];
//    for(int i=1;i<4;i++) {
//      if (prevwheel == wheelnew[i]){
//        win = win +10;
//      }
//    }

    //if we win : Send OSC Message
    if (win!=0){
      message.setAddress(destIp,destPort);
      client.send(&message);
      int valSW2=0;
      message.setZ_OSCMessage("/sw/2" , "i", &valSW2);
      client.send(&message);
  
      message.flush();
      Serial.print("\nSend OSC message :");
      Serial.println(win,DEC);
    }
  }
}

void setWheel(int wheel, int pos) {
  //calculate postion in steps
  int steps = stepsPerRevolution/wheelmax; //so 10
  int npos  = (pos*steps)-(steps/2)+wheelmax;
 
  Serial.println("====SetWheel===");
  
  Serial.print("Setwheel:");
  Serial.println(wheel,DEC);

  Serial.print("Position :");
  Serial.println(npos,DEC);
  
  Serial.print("Steps :");
  Serial.println(steps,DEC);
    
    
  wheelpos[wheel]=wheelpos[wheel]+steps;
 
 
  
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

