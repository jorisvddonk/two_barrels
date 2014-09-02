part of two_barrels;

abstract class Renderable {
  /*
   * Anything that can be rendered
   * 
   * 
   */

  List<double> getVertexPositions();
  List<int> getVertexIndices(num offset);  
  List<double> getTextureCoords();
  List<double> getNormals();
  
  Vector2 getNormal2D();
  
  double getD();

  
} 
