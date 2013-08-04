class SmallShape {
  PShape s;
  PShape ss;
  float size = 1/400;
  
  SmallShape() {
    // First create the shape
    ss = createShape(BOX,1,1,1);
    ss.setFill(color(255));
    ss.setStroke(false);
    
    s = createShape(BOX,size,size,size);
    s.setFill(color(255));
    s.setStroke(false);
  }
  
  void display(int size) {
    if (size==0) {
      shape(ss);
    } else {
      shape(s);
    }
  }
}
