part of two_barrels;

abstract class Renderable {
  /*
   * Anything that can be rendered
   * 
   * 
   */

  List<double> getVertexPositions();
  List<int> getVertexIndices(num offset);  
  List<double> getTextureCoords([double texWidth=1.0, double texHeight=1.0]);
  List<double> getNormals();
  
  Vector2 getNormal2D();
  
  double getD();

  
} 
