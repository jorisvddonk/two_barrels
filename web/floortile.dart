part of two_barrels;

class FloorTile extends Renderable {
  /*
   * Wall segment consisting of two 2d vectors forming a wall segment
   * 
   * 
   */
  Vector2 v1;
  Vector2 v2;
  Vector2 v3;
  Vector2 v4;
  static const double low = 0.0;
  
  FloorTile (Vector2 v1, Vector2 v2, Vector2 v3, Vector2 v4) {
    this.v1 = v1;
    this.v2 = v2;
    this.v3 = v3;
    this.v4 = v4;
  }
  
  List<double> getVertexPositions() {
    /*
     * Vertex layout:
     * v1, v2, v3, v4. all @ low.
     * 
     * 
     *   v4   <---  v3
     *               ^
     *               |
     *               |
     *   v1  --->    v2
     */
    return [v1.x, v1.y, low, v2.x, v2.y, low, v3.x, v3.y, low, v4.x, v4.y, low];
  }
  List<int> getVertexIndices(num offset) {
    return [offset+0, offset+1, offset+2, offset+0, offset+2, offset+3];
  }
  
  List<double> getTextureCoords([double texWidth=1.0, double texHeight=1.0]) {
    return [0.0*(1/texWidth), 0.0*(1/texHeight), 
            (v2-v1).x*(1/texWidth), (v2-v1).y*(1/texHeight), 
            (v3-v1).x*(1/texWidth), (v3-v1).y*(1/texHeight), 
            (v4-v1).x*(1/texWidth), (v4-v1).y*(1/texHeight)];
  }
  
  Vector3 getV13D() {
    return new Vector3(v1.x,v1.y,low);
  }
  Vector3 getV23D() {
    return new Vector3(v2.x,v2.y,low);
  }
  Vector3 getV33D() {
    return new Vector3(v3.x,v3.y,low);
  }
  Vector3 getV43D() {
    return new Vector3(v4.x,v4.y,low);
  }
  
  
  Vector2 getTangent2D() {
    return (v3-v1).normalize();
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
  
  List<double> getNormals() {
    Vector3 normal = new Vector3(0.0,0.0,1.0);
    return [normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z, normal.x,normal.y,normal.z];
  }
  List<double> getTangents() {
    Vector3 tangent = new Vector3(1.0,0.0,0.0);
    return [tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z, tangent.x,tangent.y,tangent.z];
  }
} 
