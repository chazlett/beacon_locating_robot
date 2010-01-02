#include <Servo.h>
#include <AFMotor.h>
#define TOPSPEED 200

// SERVO SCANNING VARIABLES //
Servo myservo;  // create servo object to control a servo 
int servoPosition = 0;    // variable to store the servo position 
const int SERVO_PIN = 10;
int floorState = 0;
long frontReading = 0;
boolean scanIncrement = true;  //increase position?
byte servoIncrementValue = 6;
byte servoDecrementValue = 6;

// MOTOR VARIABLES //
AF_DCMotor rightMotor(4, MOTOR12_8KHZ); 
AF_DCMotor leftMotor(3, MOTOR12_8KHZ); 

// TRANSCEIVER VARIABLES //
int notFoundSensitivity = 500;
int west = 0;
int south = 0;
int east = 0;
int north = 0;
int dir = 0;
boolean detected = false;

// TRANSCEIVER DIRECTION MODE VARIABLES //
const int NUM_READINGS = 10;
int directionReadings[NUM_READINGS];
int modeOfDirections = 1;
int index = 0;

void setup() 
{
  Serial.begin(38400);
  myservo.attach(SERVO_PIN);  // attaches the servo on pin 9 to the servo object 
  myservo.write(0);
  rightMotor.setSpeed(200);
  leftMotor.setSpeed(200);
  delay(1500);
} 

void loop() 
{
  scan();
  move();
  printToSerial();
} 

void printToSerial(){
  Serial.print(servoPosition);
  Serial.print("|");
  Serial.print(frontReading);
  Serial.print(";");
  if(dir==1){
    Serial.println("N");
  }else if(dir == 2){
    Serial.println("E");    
  }else if(dir == 3){
    Serial.println("S");
  }else{
    Serial.println("W");
  }
}

void move()
{
    if(servoPosition >= 0 && servoPosition <= 84 && frontReading > 550){ //Object on the left
      turnLeft();
    }else if((servoPosition >= 85 && servoPosition <= 105) && frontReading > 600){ // Object in Front
      turnAround();
    }else if((servoPosition >= 106 && servoPosition <= 180) && frontReading > 550){ // Object on the Right
      turnRight();
    }else{
      moveTowardBeacon();
    }
}

void moveTowardBeacon()
{
  readTransceiverandSetDirection();
  if(modeOfDirections == 3 || modeOfDirections == 4){ //South or West
    turnRight();
  } else if(modeOfDirections == 2) { // East
    turnLeft();
  } else if(modeOfDirections == 1){ //North
    moveForward();
  }
}

void scan()
{
   scanIncrement ? servoPosition+=servoIncrementValue : servoPosition-=servoDecrementValue; //increment or decrement current position
   if (servoPosition>=180){
     scanIncrement = false;
     servoPosition = 180;
   } else if (servoPosition <= 1){
     scanIncrement = true;
     servoPosition = 1;
   }
   frontReading = measureFront();
   //Serial.print(servoPosition);
   //Serial.print("|");
   //Serial.print(frontReading);
   //Serial.print(";");
   myservo.write(servoPosition);
   delay(15);
}

long measureFront()
{
  return analogRead(0); 
}

void moveForward(){
  //Serial.println("Move Forward");
  rightMotor.run(FORWARD);
  leftMotor.run(FORWARD);
}

void speedUp(){
  for (int i=0; i==TOPSPEED; i++) {
    rightMotor.setSpeed(i);  
    leftMotor.setSpeed(i);
  } 
}

void slowToStop(){
  for (int i=TOPSPEED; i==0; i--) {
    rightMotor.setSpeed(i);  
    leftMotor.setSpeed(i);
  }
  rightMotor.run(RELEASE);
  leftMotor.run(RELEASE);
}

void turnLeft(){
  //Serial.println("Turn Left");
  rightMotor.run(BACKWARD);
  leftMotor.run(FORWARD);
}

void turnRight(){
  //Serial.println("Turn Right");
  rightMotor.run(FORWARD);
  leftMotor.run(BACKWARD);
}

void stop(){
  //Serial.println("Stop");
  rightMotor.run(RELEASE);
  leftMotor.run(RELEASE);
  delay(500);
}

void turnAround(){
   stop();
   delay(500);
   moveBackward();
   delay(300);
   turnLeft();
   delay(300);
   stop();
   //runAway = true;  
}

void moveBackward(){
  //Serial.println("Move Backward");
  rightMotor.run(RELEASE);
  leftMotor.run(RELEASE);
  rightMotor.run(BACKWARD);
  leftMotor.run(BACKWARD);
}


//  BEACON LOGIC  //
void readTransceiverandSetDirection(){
  west = analogRead(2);
  south = analogRead(3);
  east = analogRead(4);
  north = analogRead(5);
  getDirection();
  setModeOfDirections();
}

boolean foundBeacon(){
  if(west < notFoundSensitivity and east < notFoundSensitivity and south < notFoundSensitivity and north < notFoundSensitivity){
    return false;
  }else{
    return true;
  }
}

void getDirection(){
  int minValue = 1200;
  if(minValue > west){
    minValue = west;
    dir = 4;
  }
 
  if(minValue > south){
    minValue = south;
    dir = 3;
  }
 
  if(minValue > east){
    minValue = east;
    dir = 2;
  }
 
  if(minValue > north){
    minValue = north;
    dir = 1;
  }
  
  addDirectionToReadings();
  
  //Serial.print("W:");
  //Serial.print(west);
  //Serial.print(" | S:");
  //Serial.print(south);
  //Serial.print(" | E:");
  //Serial.print(east);
  //Serial.print(" | N:");
  //Serial.println(north);
  //Serial.println("=================================");
  //if(dir == 1){
  //  Serial.println("North");
  //}else if(dir == 2){
  //  Serial.println("East");
  //}else if(dir == 3){
  //  Serial.println("South");
  //}else if(dir == 4){
  //  Serial.println("West");
  //}
}

void addDirectionToReadings(){
  directionReadings[index] = dir;
  
  index = (index + 1);
  if (index >= NUM_READINGS)             // if we're at the end of the array...
    index = 0;
}

// =========================================
// In order to smooth out the directions readings from the
// IR transceiver, You have to take the mode (most prevalent number in a collection)
// of the directionReadings Array.  This allows the program to determine which 
// direction is being read the most from the device.
// Otherwise, the readings make the robot squirrelly.
// ========================================
void setModeOfDirections(){
  int currentValue = directionReadings[0];
  int counter = 1;
  int maxCounter = 1;
  int modeValue = modeOfDirections;
  int directionCounts[4] = {0,0,0,0}; //{North(1), East(2), South(3), West(4)}
  
  for (int i = 1; i < NUM_READINGS; ++i){
    //Serial.print(directionReadings[i]);
    //Serial.print("|");
     ++directionCounts[directionReadings[i]-1];
  }
  
  
  //Determine mode of directions from count array
  Serial.println("");
  int modeCount[2] = {1,directionCounts[0]}; //This array holds the current maximum count and the direction it points to.
  for(int i = 0; i < 4; ++i){
    //Serial.print(directionCounts[i]);
    //Serial.print("|");
    if(modeCount[1] <= directionCounts[i]){
      modeCount[0] = i + 1; // set direction
      modeCount[1] = directionCounts[i]; //set count
    }
  }
  
  modeOfDirections = modeCount[0];
}
