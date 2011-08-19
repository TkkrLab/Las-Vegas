
/* 
 
 */

#include <Stepper.h>
//Z_OSC
#include <SPI.h>
#include <Ethernet.h>   // version IDE 0022
#include "Z_OSC.h"    // version IDE 0022

//Wheels
///////////////////////////
const int stepsPerRevolution = 200;  // change this to fit the number of steps per revolution
// for your motor

int wheelpos[]= {0,0,0,0};
int wheelnew[]= {0,0,0,0};
int wheelmax = 20;


//// initialize the stepper library on pins 8 through 11:
//Stepper myStepper1(stepsPerRevolution, 1,2,3,4);            
//Stepper myStepper2(stepsPerRevolution, 5,6,7,8);            
//Stepper myStepper3(stepsPerRevolution, 9,10,11,12);            
//Stepper myStepper4(stepsPerRevolution, 13,A0,A1,A2);            

//Pin 0,1 is used for the Serial communication

//DO NOT USE pins 11, 12, and 13 on the Duemilanove are used for Ethernet shield
Stepper myStepper1(stepsPerRevolution, 3,4);            
Stepper myStepper2(stepsPerRevolution, 5,6);            
Stepper myStepper3(stepsPerRevolution, 7,8);            
Stepper myStepper4(stepsPerRevolution, 9,10);            


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

  // set the speed at 60 rpm:
  myStepper1.setSpeed(60);
  myStepper2.setSpeed(60);
  myStepper3.setSpeed(60);
  myStepper4.setSpeed(60);
  
  // initialize the serial port:
  //SoftwareSerial Serial(6, 7);
  Serial.begin(9600);

  //TODO:Reset wheel positions
  // Call function

}

//Serial.println("Enter a letter A:");
 

void loop() {
  int speedM1=0;
  if ( server.available() ) {   //check if osc arrive 
    rcvMes=server.getMessage();
    rcvMes->setPortNumber(destPort);
    //Process message
    //spinWheels();
    Serial.print("Check for OSC message");
    if( !strcmp( rcvMes->getZ_OSCAddress() , "/pwm/1" ) ){
      speedM1= rcvMes->getInteger32(0);      
    }
    
    spinWheels(speedM1);          

  }
     
 if (Serial.available() > 0) {
                int incomingByte=0; 
		// read the incoming byte:
		incomingByte = Serial.read();

		// say what you got:
		Serial.print("I received Serial: ");
		Serial.println(incomingByte, DEC);
             
                spinWheels(incomingByte);          
	}
 
}

void spinWheels(int speedM1) {
  Serial.print("Speed M1=");
  Serial.println(speedM1,DEC);
  
  int prevwheel = 0;
  int win =0;
  
  Serial.println("Check for speed\n");
  if (speedM1!=0) {
    //Determine random pos for wheels
    for(int i=0;i<4;i++) {
      wheelnew[i] = random(wheelmax);
      Serial.print("Wheel :");
      Serial.println(i,DEC);
      Serial.print("Random : ");
      Serial.println(wheelnew[i],DEC);
    }

    //Set position for each wheel

    for(int i=0;i<4;i++) {
      //setWheel(i,wheelnew[i]);
      Serial.print("\nSet Wheel :");
      Serial.println(wheelnew[i],DEC);      
    }

    //TODO: Did we win something?
    prevwheel = wheelnew[0];
    for(int i=1;i<4;i++) {
      if (prevwheel == wheelnew[i]){
        win = win +10;
      }
    }

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
  int steps=stepsPerRevolution/wheelmax;
  int npos = (pos*steps)-(steps/2);
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
//
//  //step one revolution  in one direction:
//  Serial.println("clockwise");
//  myStepper1.step(stepsPerRevolution);
//  delay(500);
//
//  // step one revolution in the other direction:
//  Serial.println("counterclockwise");
//  myStepper1.step(-stepsPerRevolution);
//  delay(500); 

}
