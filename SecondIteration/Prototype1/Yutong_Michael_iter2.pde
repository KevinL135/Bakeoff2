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
// Add this with the other variables at the top
long lastClickTime = 0;
int doubleClickInterval = 300; // milliseconds between clicks to count as double-click

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
float originalLogoZ; // To remember the original size when starting resize

// Variables for the confirmation button
float confirmButtonSize;
boolean isTargetCorrect = false;

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
  
  // Set confirmation button size
  confirmButtonSize = inchToPix(0.2f);

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
  
  // Check if the target is correctly positioned
  isTargetCorrect = checkPositionAccuracy();
  
  // Draw confirmation button in the center of the logo
  if (isTargetCorrect) {
    fill(0, 255, 0); // Green when correct
  } else {
    fill(200, 200, 200); // Gray when incorrect
  }
  ellipse(0, 0, confirmButtonSize, confirmButtonSize);
  
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  text("Double-click on the middle button for submission", width/2, height-inchToPix(.4f));
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  
  // Calculate the base distance for the handle from the center
  float halfSize = logoZ / 2;
  float baseHandleDistance = inchToPix(0.3f); // Additional distance from the square edge
  float rotationHandleDistance = halfSize + baseHandleDistance;
  
  // Calculate rotation handle position
  float rotHandleX = logoX + rotationHandleDistance * sin(radians(logoRotation));
  float rotHandleY = logoY - rotationHandleDistance * cos(radians(logoRotation));
  
  float dotSize = inchToPix(0.15f);
  
  // Draw rotation/resize handle
  fill(0, 255, 0);
  noStroke();
  ellipse(rotHandleX, rotHandleY, dotSize*1.2, dotSize*1.2);
  
  // Draw line connecting center to handle
  stroke(0, 255, 0, 150);
  strokeWeight(2);
  line(logoX, logoY, rotHandleX, rotHandleY);
  noStroke();
  
  // Draw the target indicator
  if (trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    drawTargetIndicators(d);
  }
}

void mousePressed()
{
  if (startTime == 0) { // Start time on the first user click
    startTime = millis();
    println("time started!");
  }

  float halfSize = logoZ / 2;
  float dotSize = inchToPix(0.15f);
  float baseHandleDistance = inchToPix(0.3f);
  float rotationHandleDistance = halfSize + baseHandleDistance;
  
  // Calculate rotation handle position
  float rotHandleX = logoX + rotationHandleDistance * sin(radians(logoRotation));
  float rotHandleY = logoY - rotationHandleDistance * cos(radians(logoRotation));
  
  // Check if clicked on rotation/resize handle
  if (dist(mouseX, mouseY, rotHandleX, rotHandleY) < dotSize) {
    rotating = true; // This will now handle both rotation and resizing
    initialAngle = atan2(mouseY - logoY, mouseX - logoX);
    initialDistance = dist(mouseX, mouseY, logoX, logoY);
    originalLogoZ = logoZ; // Remember original size
    return;
  }

  // Check if clicked on center confirmation button or inside the square for dragging
  float dx = mouseX - logoX;
  float dy = mouseY - logoY;
  float rotatedX = dx * cos(-radians(logoRotation)) - dy * sin(-radians(logoRotation));
  float rotatedY = dx * sin(-radians(logoRotation)) + dy * cos(-radians(logoRotation));
  
  if (sqrt(rotatedX*rotatedX + rotatedY*rotatedY) <= confirmButtonSize/2) {
      //handleConfirmation();
      long currentTime = millis();
      if (currentTime - lastClickTime <= doubleClickInterval) {
          // Double click detected
          handleConfirmation();
      }
      lastClickTime = currentTime;
  }
  else if (abs(rotatedX) <= halfSize && abs(rotatedY) <= halfSize) {
    dragging = true;
    offsetX = dx;
    offsetY = dy;
  }
}

void drawTargetIndicators(Destination d) {
  // Draw lines and indicators to help guide the user
  stroke(255, 255, 0, 128);
  strokeWeight(1);
  
  // Draw X/Y guidance lines
  line(logoX, 0, logoX, height);
  line(0, logoY, width, logoY);
  line(d.x, 0, d.x, height);
  line(0, d.y, width, d.y);
}

void mouseDragged()
{
  if (rotating) {
    // Calculate new angle for rotation
    float currentAngle = atan2(mouseY - logoY, mouseX - logoX);
    float angleDiff = currentAngle - initialAngle;
    logoRotation += degrees(angleDiff);
    logoRotation = logoRotation % 360;
    if (logoRotation < 0) logoRotation += 360;
    initialAngle = currentAngle;
    
    // Calculate new size based on distance from center
    float currentDistance = dist(mouseX, mouseY, logoX, logoY);
    
    float baseHandleDistance = inchToPix(0.3f);
    
    // Maintain the ratio between handle distance and square size
    float calculatedHandleDistance = (currentDistance - baseHandleDistance) * 2;
    logoZ = calculatedHandleDistance;
  }
  else if (dragging) {
    logoX = mouseX - offsetX;
    logoY = mouseY - offsetY;
  }
}

void mouseReleased()
{
  dragging = false;
  resizing = false;
  rotating = false;
}

// New method to check if the position is accurate without submitting
boolean checkPositionAccuracy() {
  if (trialIndex >= trialCount) return false;
  
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY) < inchToPix(.05f); // Within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
  boolean closeZ = abs(d.z - logoZ) < inchToPix(.1f); // Within +-0.1"

  return closeDist && closeRotation && closeZ;
}

// Handle confirmation (double-click on center button)
void handleConfirmation() {
  if (userDone) return;
  
  if (!checkForSuccess()) {
    errorCount++; // Increment error count if incorrect
  }
  
  trialIndex++; // Move to the next trial
  if (trialIndex == trialCount) {
    userDone = true;
    finishTime = millis();
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
