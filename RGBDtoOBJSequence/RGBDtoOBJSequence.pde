/****
 * 
 * RGBD Toolkit - PointcloudToOBJ
 * Ivaylo Getov
 * August 4, 2013
 * 
 * Allows you to use RGBD Toolkit to capture a scene and then bring the SAME depth info
 * into processing. This is useful for when two projects need to have identical takes/performances.
 * 
 * This sketch builds off of the previous sketch (https://github.com/ivaylopg/RGBDToolkit-to-Processing) that 
 * generated a PVector coordinate for each point in the pointcloud. This sketch outputs an OBJ file for each frame of the pointcloud
 * 
 * Make sure you have a good amount of memory allocated for Processing in the preferences if you will
 * be using very long image sequences. If you find that it keeps running out of memory, try pausing 
 * playback while you're moving the camera around, and then start it again when you find a good angle.
 * 
 * Feel free to improve the code and make changes. Let me know if you have any questions:
 * contact@ivaylogetov.com
 * 
 * 
 ****/
 
import nervoussystem.obj.*;

PImage depthImg;
color pix;

float aY = 0;
float aX = 0;
int xMov = 0;
int yMov = 0;
float factor = 490;//200
float stored = 0;
float zNearCutoff = 0.5;
float zFarCutoff = 1.75;//3

int skip = 4;
int hW = 640;
int kH = 480;

ArrayList<String> filesList = new ArrayList();
int frameCounter = 800;
int startFrame = 0;
boolean folderChosen = false;
boolean playing = false;
boolean info = false;
boolean help = false;
boolean recording = false;

SmallShape ss;


void setup() {
  //size(1920,1080,P3D);                //Un-comment one of these to change sketch size
  size(1280,720,P3D);
  
  ss = new SmallShape();
  
  startFrame = frameCounter;

}

void draw() {
  background(0);
  stroke(255);
  //lights();
  
  stored = factor;
  
  if (recording) {
    beginRecord("nervoussystem.obj.OBJExport", "frames/frame_" + frameCounter + ".obj");
  }
  
  zFarCutoff = constrain(zFarCutoff,zNearCutoff,10);
  
  
  if (!folderChosen) {
    noStroke();
    fill(255,255,255,64);
    rectMode(CENTER);
    rect(width/2,(height/3)+65, 400, 180);
    fill(255,0,0);
    text("Press 'o' to select the directory of .png depth images to use. \n\nPress 'h' anytime to toggle a list of controls.\n\nPress 'i' at anytime to see the current parameters\n\nPress 'q' while playing to create an .obj sequence\nor while paused to create a single .obj file\n\nYou must have the Nervous System OBJExporter Library\nby Jesse Louis-Rosenberg",(width/2)-180,height/3);
    rectMode(CORNER);
    fill(255);
  }
  if (info) {
    fill(255,0,0);
    text("YRotation: " + nf(degrees(aY),3,3) + "°" + "\nXRotation: " + nf(degrees(aX),3,3) + "°" + "\nX-shift: " + xMov + "\nY-shift: " + yMov + "\nZ Far Cutoff(m): " + zFarCutoff+ "\nScaleFactor: " + factor + "\nResolution(skip): " + skip,10,16);
    fill(255);
  }
  if (help) {
    fill(255,0,0);
    text("o: open new folder   |   up/down arrows: x-axis rotation   |   left/right arrows: y-axis rotation   |   w/s: forward/back   |   a/d: left/right   |   \ne/c: up/down   |   </>: z cutoff   |   SPACE: play/pause   |   i: toggle info   |   h: toggle help   |   numbers 1 - 9: adjust resolution   |   r: reset view   |   q: create .obj   |",10,height-50);
    fill(255);
  }
  
  
  fill(255);
  stroke(255);
  if (!recording){
    translate(width/2,height/2,300);
  }
  translate(xMov,yMov);
  rotateY(aY);
  rotateX(aX);
  
  if (folderChosen) {
    
    String path = filesList.get(frameCounter);
    //println(path);
    
    depthImg = loadImage(path);
    depthImg.loadPixels();
    //image(depthImg,0,0);  
  
    for (int i=0; i < kH; i+=skip) {
      for (int j=0; j < hW; j+=skip) {
        pix = depthImg.pixels[j+(i*hW)];
        
        int green = pix >> 8 & 0xFF;
        //float green = green(pix);
        
        int red = pix >> 16 & 0xFF;
        //float red = red(pix);
       
        int millisDepth = red << 8 | green;
        float millisDepthFloat = (float)(millisDepth);
        
        if (millisDepthFloat/1000 <= zFarCutoff && millisDepthFloat/1000 >= zNearCutoff) {
          
          PVector v = depthToWorld(j,i,millisDepthFloat);                                          // Once you have this PVector, you can kind of do whatever in this section //
                                                                                                   //                                                                         //
          pushMatrix();                                                                            // For example, here we'll create a 3D box at each point and output the    //
                                                                                                   // whole cloud as an .obj file.                                            //
          if (recording) {
            factor=1;
            v.y = -1*v.y;    //I needed this to fix the orientatation in Blender. You might need different parameters here based on your 3D software
          } else {
            factor = stored;
          }
          
          translate(v.x*factor,v.y*factor,factor-v.z*factor);
          stroke(255);
          if (!recording) {
            ss.display(0);
          } else {
            ss.display(1);
          }
          
          popMatrix();                                                                             
        }
        
      }
    }
    
    if (recording && playing) {
      endRecord();
      //println(frameCounter + "/" + filesList.size());
      float progress = map(frameCounter, startFrame, filesList.size(), 0, width);
      rectMode(CORNER);
      noStroke();
      fill(255);
      rect(0,height-20,progress,20);
      fill(255,0,0);
      text(frameCounter + "/" + filesList.size(),5,height-25);
      fill(255);
      text("(Press Space-Bar to stop recording and pause playback)",100,height-25);
    
      
      //recording = false;
    }
    
    if (recording && !playing) {
      endRecord();
      recording = false;
    }
    
    if (playing) {
      if (frameCounter < filesList.size()-1) {
        frameCounter++;
      } else {
        if (recording) {
          noLoop();
        } else {
          frameCounter = 0;
        }
      }
    }
  }
  
  factor = stored;
  
}




PVector depthToWorld(int x, int y, float depthMillis) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  
  double depth = 0;
  
  
  depth = depthMillis/1000;
  
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}


void keyPressed() {
    if (key == 'a') {
      xMov += 10;
    }
    else if (key == 'd') {
      xMov -= 10;
    }
    else if (key == 'w') {
      factor+=10;
    }
    else if (key == 's') {
      factor-=10;
    }
    else if (key == 'e') {
      yMov += 10;
    }
    else if (key == 'c') {
      yMov -= 10;
    }
    else if (key == ',') {
       zFarCutoff -= 0.25;
    }
    else if (key == '.') {
      zFarCutoff += 0.25;
    }
    else if (key == 'i') {
       info = !info;
    }
    else if (key == 'h') {
      help = !help;
    }
    else if (key == 'o') {
      if (!folderChosen) {
        selectFolder("Select a folder to process:", "folderSelected");
      } else {
        replaceFolder();        
      }
    }
    else if (key == ' ') {
      playing = !playing;
    }
    else if (key == 'r') {
      resetView();
    }
   
    else if (key == '1') {
      skip = 1;
    }
    else if (key == '2') {
      skip = 2;
    }
    else if (key == '3') {
      skip = 3;
    }
    else if (key == '4') {
      skip = 4;
    }
    else if (key == '5') {
      skip = 5;
    }
    else if (key == '6') {
      skip = 6;
    }
    else if (key == '7') {
      skip = 7;
    }
    else if (key == '8') {
      skip = 8;
    }
    else if (key == '9') {
      skip = 10;
    }
    else if (key == 'q') {
      if(!recording) {
        startFrame = frameCounter;
        recording = true;
      }
    }
    
    else if (key == CODED) {
      if (keyCode == UP) {
        aX -= 0.015f;
      } 
      else if (keyCode == DOWN) {
        aX += 0.015f;
      }
      else if (keyCode == LEFT) {
        aY += 0.015f;
      }
      else if (keyCode == RIGHT) {
        aY -= 0.015f;
    }
  }
  
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String folderPath = selection.getAbsolutePath()+"/"; 
    //println(folderPath);
    File [] files = selection.listFiles();
    String filenames[]=new String[files.length];
    for(int i=0; i<files.length; i++) {
      filenames[i]=files[i].getAbsolutePath();
      if (filenames[i].toLowerCase().endsWith(".png")) {
        //println(filenames[i].replace(folderPath,""));
        filesList.add(filenames[i]);
      } else {
        //println("NOT A FILE");
      }
    }
    folderChosen = true;
    playing = true;
  }
}


void replaceFolder(){
  folderChosen = false;
  playing = false;
  filesList.clear();
  frameCounter = 0;
  selectFolder("Select a folder to process:", "folderSelected");
}

void resetView() {
  aY = 0;
  aX = 0;
  xMov = 0;
  yMov = 0;
  factor = 200;
  zFarCutoff = 3;
}

void stop() {
  super.stop();
}
