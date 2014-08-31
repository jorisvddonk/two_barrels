part of two_barrels;

class Player {
  /*
   * Player / camera

   */
  Vector2 position;
  Vector2 rotation;
  Vector2 movement;
  double zpos = 0.0;
  
  Player () {
    this.position = new Vector2(0.0,0.0);
    this.rotation = new Vector2(0.0,1.0);
    this.movement = new Vector2(0.0,0.0);
  }
  
  void move(double elapsed) {
    print("Movement is ${this.movement}");
    this.position = this.position.add(this.movement.clone().scale(elapsed));
    dampen(elapsed);
  }
  
  void dampen(double elapsed) {
    this.movement.scale(0.9); //todo use elapsed
  }
  
} 
