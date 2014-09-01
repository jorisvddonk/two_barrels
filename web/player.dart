part of two_barrels;

class Player {
  /*
   * Player / camera

   */
  Vector2 position;
  Vector2 rotation;
  Vector2 movement;
  double zpos = -0.5;
  
  Player () {
    this.position = new Vector2(0.0,0.0);
    this.rotation = new Vector2(0.0,1.0);
    this.movement = new Vector2(0.0,0.0);
  }
  
  void move(double elapsed) {
    this.position = this.position.add(this.movement.clone().scale(elapsed));
    dampen(elapsed);
  }
  
  void dampen(double elapsed) {
    this.movement.scale(0.9); //todo use elapsed
  }
  
  void clipMotion(List<Segment> segments) {
    for (Segment segment in segments) {
      clipMotionSeg(segment);
    }
  }
  
  void clipMotionSeg(Segment segment) {
    num radius = 0.1;
        //double xp = pos.x;
        //double yp = pos.z;

        double xNudge = 0.0;
        double yNudge = 0.0;
        bool intersect = false;

        Vector2 segmentnorm = segment.getNormal2D();
        Vector2 segmenttang = segment.getTangent2D();
        double d = this.position.x*segmentnorm.x+this.position.y*segmentnorm.y - segment.getD();
        double mul = 1.0;
        if (d>=-radius && d<=radius) {
          if (d<0) {
            d=-d;
            mul = -1.0;
          }
          double sd = this.position.x*segmenttang.x+this.position.y*segmenttang.y - segment.getSD();
          if (sd>=0.0 && sd<=segment.getLength()) {
            // Hit the center of the seg
            double toPushOut = radius-d+0.001;
            xNudge=segmentnorm.x*toPushOut*mul;
            yNudge=segmentnorm.y*toPushOut*mul;
            intersect = true;
          }
        }

        if (intersect) {
          bool collideWall = false;
          if (segment.isImpassable()) {
            collideWall = true;
          }

          if (collideWall) {
            this.position.x += xNudge;
            this.position.y += yNudge;
          }
        }
  }
  
} 
