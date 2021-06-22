//*********************************************
// Example Code for Interactive Intelligent Products
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************

import papaya.*;
import processing.serial.*;
Serial port1; 

import Weka4P.*;
Weka4P wp;

import oscP5.*;
import netP5.*;
 
OscP5 oscP5Location1;
NetAddress location2;

OscMessage myMessage = new OscMessage("test");

int sensorNum = 3; //number of sensors in use
int streamSize1 = 500; //number of data to show
int[] rawData = new int[sensorNum];
float[][] sensorHist = new float[sensorNum][streamSize1]; //history data to show
float[][] diffArray1 = new float[sensorNum][streamSize1]; //diff calculation: substract
float[] modeArray1 = new float[streamSize1]; //To show activated or not
float[] thldArray1 = new float[streamSize1]; //diff calculation: substract
int activationThld = 5; //The diff threshold of activiation

//segmentation parameters
float energyMax1 = 0;
float energyThld1 = 100; //use energy for activation
float[] energyHist1 = new float[streamSize1]; //history data to show

//FFT parameters
float sampleRate1 = 500;
int numBins1 = 65;
int bufferSize1 = (numBins1-1)*2;
//Band pass filter
final int LOW_THLD1 = 2; //check: why 2?
final int HIGH_THLD1 = 64; //high threshold of band-pass frequencies
int numBands1 = HIGH_THLD1-LOW_THLD1+1;
ezFFT[] fft = new ezFFT[sensorNum]; // fft per sensor
float[][] FFTHist1 = new float[numBands1][streamSize1]; //history data to show; //history data to show

//visualization parameters
float fftScale1 = 2;

//window
int windowSize1 = 20; //The size of data window
float[][][] windowArray1 = new float[sensorNum][numBands1][windowSize1]; //data window collection
boolean b_sampling1 = false; //flag to keep data collection non-preemptive
int sampleCnt1 = 0; //counter of samples

//Statistical Features
float[][] windowM1 = new float[sensorNum][numBands1]; //mean
float[][] windowSD1 = new float[sensorNum][numBands1]; //standard deviation
float[][] windowM1ax1 = new float[sensorNum][numBands1]; //mean

////Save
Table csvData;
boolean b_saveCSV = false;
String dataSetName = "ToothAccelTrain"; 
String[] attrNames;
boolean[] attrIsNominal;
int labelIndex = 0;

String str1 = "A";
String lastPredY1 = "";

void setDataType() {
  attrNames =  new String[numBands1+1];
  attrIsNominal = new boolean[numBands1+1];
  for (int j = 0; j < numBands1; j++) {
    attrNames[j] = "f_"+j;
    attrIsNominal[j] = false;
  }
  attrNames[numBands1] = "label";
  attrIsNominal[numBands1] = true;
}


void setup() {
  size(500, 500, P2D);
  wp = new Weka4P(this);
  initSerial();
  for (int i = 0; i < sensorNum; i++) { //ezFFT(number of samples, sampleRate1)
    fft[i] = new ezFFT(bufferSize1, sampleRate1);
  }
  for (int i = 0; i < streamSize1; i++) { //Initialize all modes as null
    modeArray1[i] = -1;
  }
    wp.loadTrainARFF("ToothAccelTrain.arff"); //load a ARFF dataset
  wp.loadModel("AccelLinearSVC.model"); //load a pretrained model.
  
  
  oscP5Location1 = new OscP5(this, 5001);
  location2 = new NetAddress("131.155.245.0", 6001);  
}

void draw() {
  background(255);

  float[] X = new float[numBands1]; //Form a feature vector X;
  energyMax1 = 0; //reset the measurement of energySum
  for (int i = 0; i < sensorNum; i++) {
    fft[i].updateFFT(sensorHist[i]);
    for (int j = 0; j < numBands1; j++) {
      float x = fft[i].getSpectrum()[j+LOW_THLD1]; //get the energy of channel j
      if (x>energyMax1) energyMax1 = x;             //check energyMax1: the max energy of all channels
      appendArrayTail(FFTHist1[j], x);             //update fft history
      if (b_sampling1 == true) {
        //if (x>X[j]) X[j] = x; //simple windowed max
        windowArray1[i][j][sampleCnt1-1] = x; //windowed statistics
      }
    }
  }

  if (energyMax1>energyThld1) {
    if (b_sampling1 == false) { //if not sampling
      b_sampling1 = true; //do sampling
      sampleCnt1 = 0; //reset the counter
      for (int j = 0; j < numBands1; j++) {
        X[j] = 0; //reset the feature vector
      }
      for (int i = 0; i < sensorNum; i++) {
        for (int j = 0; j < numBands1; j++) {
          for (int k = 0; k < windowSize1; k++) {
            (windowArray1[i][j])[k] = 0; //reset the window
          }
        }
      }
    }
  }

  if (b_sampling1 == true) {
    ++sampleCnt1;
    if (sampleCnt1 == windowSize1) {
      for (int i = 0; i < sensorNum; i++) {
        for (int j = 0; j < numBands1; j++) {
          //windowM1[i][j] = Descriptive.mean(windowArray1[i][j]); //mean
          //windowSD1[i][j] = Descriptive.std(windowArray1[i][j], true); //standard deviation
          windowM1ax1[i][j] = max(windowArray1[i][j]); //mean
        }
      }

      for (int j = 0; j < numBands1; j++) {
        X[j] = max(windowM1ax1[0][j], windowM1ax1[1][j], windowM1ax1[2][j]);
      }
      lastPredY1 = wp.getPrediction(X);
      double yID = wp.getPredictionIndex(X);
      for(int n = 0 ; n < windowSize1 ; n++){
        appendArrayTail(modeArray1, (float)yID);
      }
      b_sampling1 = false;
    }
  } else {
    appendArrayTail(modeArray1, -1); //the class is null without mouse pressed.
  }

  appendArrayTail(energyHist1, energyMax1); //update energyMax1 history
  appendArrayTail(thldArray1, energyThld1);
  
  pushMatrix();
  fft[0].drawSpectrogram(fftScale1, 1024, true);
  translate(0, 200);
  fft[1].drawSpectrogram(fftScale1, 1024, true);
  translate(200, 0);
  fft[2].drawSpectrogram(fftScale1, 1024, true);
  popMatrix();
  
  barGraph(modeArray1, 0, height, 0, height-100, 500., 50);

  lineGraph(energyHist1, 0, height, 0, height-150, 500., 50, 0, color(0, 255, 0));
  lineGraph(thldArray1, 0, height, 0, height-150, 500., 50, 0, color(128, 0, 255));
  
  showInfo("Window size: "+windowSize1, 20, height-136, 18);
  showInfo("Threshold: "+energyThld1+" ([A]:+/[Z]:-)", 20, height-118, 18);
  String Y = lastPredY1;
  showInfo("Prediction: "+Y, 320+20, 100, 16);
  
  drawFFTInfo(20, height-100, 18);
  if (b_saveCSV) {
    saveCSV(dataSetName, csvData);
    saveARFF(dataSetName, csvData);
    b_saveCSV = false;
  }
  
  
     //if (str1.equals(Y) == true) {
     //                 myMessage.add("Toothbrush");  // They are equal, so this line will print
                      
     //                 oscP5Location1.send(myMessage, location2);
     //               } else {
     //                 myMessage.add("No Toothbrush"); // This line will not print
     //               }
     
                  
                  if (str1.equals(Y) == true) {
                      port1.write(1);
                      println("Toothbrush");  // They are equal, so this line will print
                    }  else{
                      port1.write(0);
                    }
                      
                    
                    if (str1.equals(Y) == false) {
                      port1.write(0);
                      println("No Toothbrush");  // This line will not print
                    }
                    
                    
                    if (Y.equals(null) == true) {
                      port1.write(0);
                      println("No Toothbrush");  // This line will not print
                    }
                                        

}

void keyPressed() {
  if (key == 'A' || key == 'a') {
    energyThld1 = min(energyThld1+5, 100);
  }
  if (key == 'Z' || key == 'z') {
    energyThld1 = max(energyThld1-5, 10);
  }
}

float[] appendArrayTail (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, 1, tempArray, 0, tempArray.length);
  array[tempArray.length] = _val;
  arrayCopy(tempArray, 0, array, 0, tempArray.length);
  return array;
}

void serialEvent(Serial port1) {   
  String inData = port1.readStringUntil('\n');  // read the serial string until seeing a carriage return
  //assign data index based on the header
  if (inData.charAt(0) == 'A') {  
    rawData[0] = int(trim(inData.substring(1))); //store the value
    appendArrayTail(sensorHist[0], rawData[0]); //store the data to history (for visualization)
    float diff = abs(sensorHist[0][sensorHist[0].length-1] - sensorHist[0][sensorHist[0].length-2]); //normal diff
    appendArrayTail(diffArray1[0], diff);
    return;
  }
  if (inData.charAt(0) == 'B') {  
    rawData[1] = int(trim(inData.substring(1))); //store the value
    appendArrayTail(sensorHist[1], rawData[1]); //store the data to history (for visualization)
    float diff = abs(sensorHist[1][sensorHist[1].length-1] - sensorHist[1][sensorHist[1].length-2]); //normal diff
    appendArrayTail(diffArray1[1], diff);
    return;
  }
  if (inData.charAt(0) == 'C') {  
    rawData[2] = int(trim(inData.substring(1))); //store the value
    appendArrayTail(sensorHist[2], rawData[2]); //store the data to history (for visualization)
    float diff = abs(sensorHist[2][sensorHist[2].length-1] - sensorHist[2][sensorHist[2].length-2]); //normal diff
    appendArrayTail(diffArray1[2], diff);
    return;
  }
}

void initSerial() {
  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String port1Name = Serial.list()[Serial.list().length-1];//MAC: check the printed list
  //String port1Name = Serial.list()[9];//WINDOWS: check the printed list
  port1 = new Serial(this, port1Name, 115200);
  port1.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port1.clear();           // flush the Serial buffer
}
