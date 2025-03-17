import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window, set later
int trialCount = 10; //WILL BE MODIFIED FOR THE BAKEOFF
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 1.0f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done
boolean isRotating = false;
float rotationStartAngle = 0;

final int screenPPI = 72; //what is the DPI of the screen you are using

//These variables are for my design
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;

// Variables for the interaction
float prevMouseX = 0;
float prevMouseY = 0;
boolean isDragging = false;
int lastClickTime = 0;
int doubleClickThreshold = 300; // milliseconds for double click detection

private class Destination {
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

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone) {
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
  popMatrix();

  //===========DRAW INSTRUCTIONS=================
  fill(255);
  text("Trial " + (trialIndex+1) + " of " + trialCount, width/2, inchToPix(.8f));
  
  // Instructions for user
  textAlign(LEFT);
  text("Drag to move the blue square", 10, height - inchToPix(1.5f));
  text("Drag CORNER of blue square to rotate", 10, height - inchToPix(1.2f));
  text("Double-click on LEFT of target to enlarge", 10, height - inchToPix(0.9f));
  text("Double-click on RIGHT of target to shrink", 10, height - inchToPix(0.6f));
  text("Double-click on TARGET to submit", 10, height - inchToPix(0.3f));
  textAlign(CENTER);
  
  // Draw the target indicator
  if (trialIndex < trialCount) {
    Destination d = destinations.get(trialIndex);
    drawTargetIndicators(d);
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

void mousePressed() {
  if (startTime == 0) { //start time on the instant of the first user click
    startTime = millis();
    println("time started!");
  }
  
  // Check for double click
  int currentTime = millis();
  if (currentTime - lastClickTime < doubleClickThreshold) {
    // It's a double click!
    handleDoubleClick();
  } else {
    // It's a single click/drag start
    prevMouseX = mouseX;
    prevMouseY = mouseY;
    isDragging = true;
  }
  
  lastClickTime = currentTime;
}

void mouseDragged() {
  if (isDragging) {
    if (isRotating) {
      // Handle rotation
      float currentAngle = atan2(mouseY - logoY, mouseX - logoX);
      float angleDiff = degrees(currentAngle - rotationStartAngle);
      
      // Adjust rotation based on the angle difference
      logoRotation += angleDiff;
      
      // Update the rotation start angle for the next frame
      rotationStartAngle = currentAngle;
    } else {
      // Handle movement (unchanged)
      logoX += mouseX - prevMouseX;
      logoY += mouseY - prevMouseY;
      
      // Check if we should start rotating
      // If the user drags while holding Alt/Option key or is near the edge of the square
      float distToLogo = dist(mouseX, mouseY, logoX, logoY);
      if (keyPressed && keyCode == ALT || (distToLogo > logoZ/2 - inchToPix(0.1f) && distToLogo < logoZ/2 + inchToPix(0.2f))) {
        isRotating = true;
        rotationStartAngle = atan2(mouseY - logoY, mouseX - logoX);
      }
    }
    
    prevMouseX = mouseX;
    prevMouseY = mouseY;
  }
}

void mouseReleased() {
  isDragging = false;
  isRotating = false;
  
  // Normalize the logo rotation to keep it within 0-360 degrees
  logoRotation = logoRotation % 360;
  if (logoRotation < 0) logoRotation += 360;
}

void handleDoubleClick() {
  // Check if double click is on the target (current destination)
  Destination currentDest = destinations.get(trialIndex);
  float distToTarget = dist(mouseX, mouseY, currentDest.x, currentDest.y);
  
  // Check if the click is within the target square
  if (distToTarget < currentDest.z/2) {
    // Submit if clicked within the target square
    if (userDone == false && !checkForSuccess())
      errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex == trialCount && userDone == false) {
      userDone = true;
      finishTime = millis();
    }
    return;
  }
  
  // Check if it's on the left side of the destination square (outside the square)
  if (mouseX < currentDest.x - currentDest.z/2) {
    // Double click on left of destination square - enlarge
    logoZ = constrain(logoZ + inchToPix(0.05f), 0.01, inchToPix(4f));
    return;
  }
  
  // Check if it's on the right side of the destination square (outside the square)
  if (mouseX > currentDest.x + currentDest.z/2) {
    // Double click on right of destination square - shrink
    logoZ = constrain(logoZ - inchToPix(0.05f), 0.01, inchToPix(4f));
    return;
  }
}


//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess() {
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY) < inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
  boolean closeZ = abs(d.z - logoZ) < inchToPix(.1f); //has to be within +-0.1"  

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logoRotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2) {
  double diff = abs(a1-a2);
  diff %= 90;
  if (diff > 45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch) {
  return inch*screenPPI;
}
