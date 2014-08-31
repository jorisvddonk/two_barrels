part of two_barrels;

class Segment {
  /*
   * Wall segment consisting of two 2d vectors forming a wall segment
   * 
   * 
   */
  Vector2 v1;
  Vector2 v2;
  static const double low = 0.0;
  static const double high = 5.0;
  
  Segment (Vector2 v1, Vector2 v2) {
    this.v1 = v1;
    this.v2 = v2;
  }
  
  List<double> getVertexPositions() {
    /*
     * Vertex layout:
     * v1 with height 0, v2 with height 0, v2 with height height, v1 with height height
     * 
     * 
     * v1/high <--- v2/high
     *                   ^
     *                   |
     *                   |
     *   v1/low  --->    v2/low
     */
    return [v1.x, v1.y, low, v2.x, v2.y, low, v2.x, v2.y, high, v1.x, v1.y, high];
  }
  List<int> getVertexIndices(num offset) {
    return [offset+0, offset+1, offset+2, offset+0, offset+2, offset+3];
  }
  
  List<double> getTextureCoords() {
    return [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0]; //TODO implement properly
  }
  
  Vector3 getV13D_low() {
    return new Vector3(v1.x,v1.y,low);
  }
  Vector3 getV13D_high() {
    return new Vector3(v1.x,v1.y,high);
  }
  Vector3 getV23D_low() {
    return new Vector3(v2.x,v2.y,low);
  }
  Vector3 getV23D_high() {
    return new Vector3(v2.x,v2.y,high);
  }
  
  List<double> getNormals() {
    Vector3 normal = getV23D_low().sub(getV13D_low()).cross(getV23D_high().sub(getV13D_low())).normalize();
    return [normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z];
  }
} 