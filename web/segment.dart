part of two_barrels;

class Segment extends Renderable {
  /*
   * Wall segment consisting of two 2d vectors forming a wall segment
   * 
   * 
   */
  Vector2 v1;
  Vector2 v2;
  static const double low = 0.0;
  static const double high = 1.0;
  
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
  
  List<double> getTextureCoords([double texWidth=1.0, double texHeight=1.0]) {
    double l = this.getLength();
    double h = math.sqrt((high-low)*(high-low));
    return [0.0*(1/texWidth), 0.0*(1/texHeight), 
            l*(1/texWidth), 0.0*(1/texHeight), 
            l*(1/texWidth), h*(1/texHeight), 
            0.0*(1/texWidth), h*(1/texHeight)];
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
  Vector2 getTangent2D() {
    return (v2-v1).normalize();
  }
  Vector2 getNormal2D() {
    Vector2 tangent = getTangent2D();
    return new Vector2(tangent.y, -tangent.x);
  }
  double getD() {
    //dist from origin
    Vector2 normal = getNormal2D();
    return (v1.x*normal.x) + (v1.y*normal.y);    
  }
  double getSD() {
    //dist to line from origin
    Vector2 tangent = getTangent2D();
    return (v1.x*tangent.x) + (v1.y*tangent.y);    
  }
  double getLength() {
    return math.sqrt(((v2.x-v1.x)*(v2.x-v1.x))+((v2.y-v1.y)*(v2.y-v1.y)));
  }
  
  bool isImpassable() {
    return true;
  }
  
  List<double> getNormals() {
    Vector3 normal = getV23D_low().sub(getV13D_low()).cross(getV23D_high().sub(getV13D_low())).normalize();
    return [normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z];
  }
  
  List<double> getTangents() {
    Vector3 tangent = getV23D_low().sub(getV13D_low()).normalize();    
    return [tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z];
  }
} 
