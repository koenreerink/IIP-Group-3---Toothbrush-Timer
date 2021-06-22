#include <Arduino.h>
#include <TM1637Display.h>

#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>


Adafruit_MPU6050 mpu;

int sampleRate = 100; //samples per second
int sampleInterval = 1000000/sampleRate; //Inverse of SampleRate


 
// Module connection pins (Digital Pins)
#define CLK 15
#define DIO 16
 
// The amount of time (in milliseconds) between tests
#define TEST_DELAY   1000
 
TM1637Display display(CLK, DIO);
 
int second_ones,second_tens,minute_ones,minute_tens;
bool dot = true;


const int buttonPin = 12;
int buttonState;
int lastButtonState = LOW;

const byte numChars = 32;
char receivedChars[numChars];
int led = 13; 
int led2 = 14;  

bool shouldRead = false;
bool mic_on = false;
bool startnew = true; 

const int micIN = A1;
int audioVal = 0;
int Q = 1; 

unsigned long currentTime;
unsigned long prevTime;

int reading = 0;

void setup(void) {
  Serial.begin(115200);
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(micIN, INPUT);
  pinMode(led, OUTPUT);
  pinMode(led2, OUTPUT);

  currentTime = 0;
  prevTime = 0;


//
//  while (!Serial)
//    delay(10); 
//
//  
// if (!mpu.begin()) {
//    Serial.println("Failed to find MPU6050 chip");
//    while (1) {
//      delay(10);
//    }
//  }
// 
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);



}

void loop() {

 
    currentTime = millis();   
    reading = digitalRead(buttonPin);
    Serial.println(reading);
    

    if (reading == HIGH){    
      digitalWrite(led2, HIGH);
      timer();
     }else{
      digitalWrite(led2, LOW );
      digitalWrite(led, LOW);
      startnew = true;
      Q = 1;
      int t = 200;
     }

   while (reading == LOW){
    display.setBrightness(0x0F);
    display.showNumberDecEx(0, (0x80 >> dot), false);
    break;



      sensors_event_t a, g, temp;
      mpu.getEvent(&a, &g, &temp);
    
      Serial.print("X: ");
      Serial.print(a.acceleration.x);
      Serial.print(", Y: ");
      Serial.print(a.acceleration.y);
      Serial.print(", Z: ");
      Serial.print(a.acceleration.z);
    
      Serial.println("");


      sendDataToProcessing('A', a.acceleration.x);
      sendDataToProcessing('B', a.acceleration.y);
      sendDataToProcessing('C', a.acceleration.z);

      
    
   }
        
      
}



void timer(){
  int TB = Serial.read();
  
  int t = minute_tens * 1000 + minute_ones * 100 + second_tens * 10 + second_ones;

 

  if (TB == 1) {
      digitalWrite(led, HIGH);   
    } else if (TB == 0) {
      digitalWrite(led, LOW );
    }


if (startnew == true){
    t = 200;
    display.setBrightness(0x0F);
    display.showNumberDecEx(t, (0x80 >> dot), true);
    startnew = false;
} 

while (currentTime - prevTime >= 1000 && TB == 1){

     second_ones--;
  if (second_ones < 0) {
    second_tens--;
    second_ones = 9;
  }
  if (second_tens < 0) {
    second_tens = 5;
    minute_ones--;
  }
  if (minute_ones < 0 ) {
    minute_ones = 1;
  }
  
  if (t == 0){
     Q = 0;
  }

  
  dot = !dot;
  display.showNumberDecEx(t, (0x80 >> dot), true);
  prevTime = currentTime;
  break;
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}
