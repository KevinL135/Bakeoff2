import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window, set later
int trialCount = 10; //WILL BE MODIFIED FOR THE BAKEOFF
 //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 1.0f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done
boolean dragging = false;
boolean resizing = false;
boolean rotating = false; // For rotation tool

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;
float offsetX, offsetY;
float initialAngle; // Initial angle for rotation
float initialDistance; // Initial distance for resizing

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

void setup() {
  size(1000, 800);  
  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);
  rectMode(CENTER); //draw rectangles not from upper left, but from the center outwards
  
  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  println("creating "+trialCount + " targets");
  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(border, width-border); //set a random x with some padding
    d.y = random(border, height-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    d.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}



void draw() {

  background(40); //background is dark grey
  fill(200);
  noStroke();
  
  //Test square in the top left corner. Should be 1 x 1 inch
  //rect(inchToPix(0.5), inchToPix(0.5), inchToPix(1), inchToPix(1));

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    Destination d = destinations.get(i); //get destination trial
    translate(d.x, d.y); //center the drawing coordinates to the center of the destination trial
    
    rotate(radians(d.rotation)); //rotate around the origin of the Ddestination trial
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192); //set color to semi translucent
    else
      stroke(128, 128, 128, 128); //set color to semi translucent
    rect(0, 0, d.z, d.z);
    popMatrix();
  }

  //===========DRAW LOGO SQUARE=================
  pushMatrix();
  translate(logoX, logoY); //translate draw center to the center oft he logo square
  rotate(radians(logoRotation)); //rotate using the logo square as the origin
  noStroke();
  fill(60, 60, 192, 192);
  rect(0, 0, logoZ, logoZ);
  
  // Corner handles (rotates with square)
  float halfSize = logoZ / 2;
  float dotSize = inchToPix(0.15f);
  fill(255, 0, 0);
  ellipse(-halfSize, -halfSize, dotSize, dotSize);
  ellipse(halfSize, -halfSize, dotSize, dotSize);
  ellipse(-halfSize, halfSize, dotSize, dotSize);
  ellipse(halfSize, halfSize, dotSize, dotSize);
  
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  text("confirm", width/2, height-inchToPix(.4f));
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  
  // Draw rotation handle
  float rotationHandleDistance = halfSize + inchToPix(0.3f);  
  float rotHandleX = logoX + rotationHandleDistance * sin(radians(logoRotation));
  float rotHandleY = logoY - rotationHandleDistance * cos(radians(logoRotation));
  
  fill(0, 255, 0);
  noStroke();
  ellipse(rotHandleX, rotHandleY, dotSize*1.2, dotSize*1.2);
  
  stroke(0, 255, 0, 150);
  strokeWeight(2);
  line(logoX, logoY, rotHandleX, rotHandleY);
  noStroke();
}

void mousePressed()
{
  if (startTime == 0) { // Start time on the first user click
    startTime = millis();
    println("time started!");
  }

  float halfSize = logoZ / 2;
  float dotSize = inchToPix(0.15f);
  
  // Check rotation handle
  float rotationHandleDistance = halfSize + inchToPix(0.3f);
  float rotHandleX = logoX + rotationHandleDistance * sin(radians(logoRotation));
  float rotHandleY = logoY - rotationHandleDistance * cos(radians(logoRotation));
  
  if (dist(mouseX, mouseY, rotHandleX, rotHandleY) < dotSize) {
    rotating = true;
    initialAngle = atan2(mouseY - logoY, mouseX - logoX);
    return;
  }

  // Calculate corner positions with rotation
  float tlX = logoX + (-halfSize * cos(radians(logoRotation)) - (-halfSize) * sin(radians(logoRotation)));
  float tlY = logoY + (-halfSize * sin(radians(logoRotation)) + (-halfSize) * cos(radians(logoRotation)));
  
  float trX = logoX + (halfSize * cos(radians(logoRotation)) - (-halfSize) * sin(radians(logoRotation)));
  float trY = logoY + (halfSize * sin(radians(logoRotation)) + (-halfSize) * cos(radians(logoRotation)));
  
  float blX = logoX + (-halfSize * cos(radians(logoRotation)) - (halfSize) * sin(radians(logoRotation)));
  float blY = logoY + (-halfSize * sin(radians(logoRotation)) + (halfSize) * cos(radians(logoRotation)));
  
  float brX = logoX + (halfSize * cos(radians(logoRotation)) - (halfSize) * sin(radians(logoRotation)));
  float brY = logoY + (halfSize * sin(radians(logoRotation)) + (halfSize) * cos(radians(logoRotation)));

  boolean clickedTopLeft = dist(mouseX, mouseY, tlX, tlY) < inchToPix(.1f);
  boolean clickedTopRight = dist(mouseX, mouseY, trX, trY) < inchToPix(.1f);
  boolean clickedBottomLeft = dist(mouseX, mouseY, blX, blY) < inchToPix(.1f);
  boolean clickedBottomRight = dist(mouseX, mouseY, brX, brY) < inchToPix(.1f);

  if (clickedTopLeft || clickedTopRight || clickedBottomLeft || clickedBottomRight) {
    resizing = true;
    initialDistance = dist(mouseX, mouseY, logoX, logoY);
  } else {
    // Check if inside rotated square
    float dx = mouseX - logoX;
    float dy = mouseY - logoY;
    float rotatedX = dx * cos(-radians(logoRotation)) - dy * sin(-radians(logoRotation));
    float rotatedY = dx * sin(-radians(logoRotation)) + dy * cos(-radians(logoRotation));
    
    if (abs(rotatedX) <= halfSize && abs(rotatedY) <= halfSize) {
      dragging = true;
      offsetX = dx;
      offsetY = dy;
    }
  }
}

void mouseDragged()
{
  if (rotating) {
    float currentAngle = atan2(mouseY - logoY, mouseX - logoX);
    float angleDiff = currentAngle - initialAngle;
    logoRotation += degrees(angleDiff);
    logoRotation = logoRotation % 360;
    if (logoRotation < 0) logoRotation += 360;
    initialAngle = currentAngle;
  }
  else if (resizing) {
    //  resizing
    float currentDistance = dist(mouseX, mouseY, logoX, logoY);
    float scaleFactor = currentDistance / initialDistance;
    
    float newSize = constrain(logoZ * scaleFactor, inchToPix(.5f), inchToPix(4f));
    logoZ = newSize;
    initialDistance = currentDistance;
  } 
  else if (dragging) {
    float rotatedOffsetX = offsetX * cos(radians(logoRotation)) - offsetY * sin(radians(logoRotation));
    float rotatedOffsetY = offsetX * sin(radians(logoRotation)) + offsetY * cos(radians(logoRotation));
    
    logoX = mouseX - rotatedOffsetX;
    logoY = mouseY - rotatedOffsetY;
  }
}

void mouseReleased()
{
  dragging = false;
  resizing = false;
  rotating = false;

  //  "confirm" button at the bottom of the screen
  if (dist(width / 2, height - inchToPix(.4f), mouseX, mouseY) < inchToPix(.8f)) {
    if (userDone == false && !checkForSuccess()) {
      errorCount++; // Increment error count if incorrect
    }
    trialIndex++; // Move to the next trial
    if (trialIndex == trialCount && userDone == false) {
      userDone = true;
      finishTime = millis();
    }
  }
}


//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation)<=5;
  boolean closeZ = abs(d.z - logoZ)<inchToPix(.1f); //has to be within +-0.1"  

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logoRotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
