part of two_barrels;

class RenderGroup {
  /*
   * Renders a group of segments using the same texture
   * 
   * 
   */
  webgl.Texture texture;
  List<Segment> segments;
  webgl.Buffer cubeVertexTextureCoordBuffer;
  webgl.Buffer cubeVertexPositionBuffer;
  webgl.Buffer cubeVertexIndexBuffer;
  webgl.Buffer cubeVertexNormalBuffer;
  List<double> vertices, textureCoords, vertexNormals, colors;
  List<int> cubeVertexIndices;
  bool inited = false;
  String texture_src;
  
  RenderGroup (webgl.Texture texture, String texture_src) {
    this.texture = texture;
    this.segments = new List<Segment>();
    this.texture_src = texture_src;
  }
  
  void initBuffers(webgl.RenderingContext gl) {
    // vertex positions
    cubeVertexPositionBuffer = gl.createBuffer();
    vertices = segments.fold([], (prev, seg) {
      prev.addAll(seg.getVertexPositions());
      return prev;
    });

    // texture coordinates
    cubeVertexTextureCoordBuffer = gl.createBuffer();
    textureCoords = segments.fold([], (prev, seg) {
      prev.addAll(seg.getTextureCoords());
      return prev;
    });

    // geometry vertex indices
    cubeVertexIndexBuffer = gl.createBuffer();
    cubeVertexIndices = segments.fold([], (prev, seg) {
      prev.addAll(seg.getVertexIndices((prev.length/6).toInt()*4));
      return prev;
    });


    cubeVertexNormalBuffer = gl.createBuffer();
    vertexNormals = segments.fold([], (prev, seg) {
      prev.addAll(seg.getNormals());
      return prev;
    });

    inited = true;
  }
  
  void render(webgl.RenderingContext gl, int _aVertexPosition, int _aTextureCoord, int _aVertexNormal) {
    if (!inited) {
      return;
    }
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexPositionBuffer);
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW); //TODO: cache
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexTextureCoordBuffer);
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(textureCoords), webgl.RenderingContext.STATIC_DRAW); //TODO: cache
    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
    gl.bufferData(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(cubeVertexIndices), webgl.RenderingContext.STATIC_DRAW); //TODO: cache
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexNormalBuffer);
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertexNormals), webgl.RenderingContext.STATIC_DRAW); //TODO: cache
    
    // vertices
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    // texture
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexTextureCoordBuffer);
    gl.vertexAttribPointer(_aTextureCoord, 2, webgl.RenderingContext.FLOAT, false, 0, 0);

    // light
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexNormalBuffer);
    gl.vertexAttribPointer(_aVertexNormal, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    gl.activeTexture(webgl.RenderingContext.TEXTURE0);
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture);


    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
    //setMatrixUniforms();
    gl.drawElements(webgl.RenderingContext.TRIANGLES, segments.length*6, webgl.RenderingContext.UNSIGNED_SHORT, 0);

    if (false) {
      // draw lighting
      /*
      gl.uniform1i(_uUseLighting, 1); // must be int, not bool
      gl.uniform3f(_uAmbientColor, 5 / 100, 5 / 100, 5 / 100);
      Vector3 lightingDirection = new Vector3(10 / 100, 10 / 100, 10 / 100);
      Vector3 adjustedLD = lightingDirection.normalize();
      //adjustedLD.scale(-1.0);
      gl.uniform3fv(_uLightingDirection, adjustedLD.storage);
      
      gl.uniform3f(_uDirectionalColor, 255 / 100, 200 / 100, 20 / 100);
      */
    }
  }
} 
