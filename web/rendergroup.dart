part of two_barrels;

class RenderGroup {
  /*
   * Renders a group of renderables using the same texture
   * 
   * 
   */
  webgl.Texture texture;
  webgl.Texture texture_normal;
  webgl.Texture texture_glow;
  int texture_width = null;
  int texture_height = null;
  List<Renderable> renderables;
  webgl.Buffer cubeVertexTextureCoordBuffer;
  webgl.Buffer cubeVertexPositionBuffer;
  webgl.Buffer cubeVertexIndexBuffer;
  webgl.Buffer cubeVertexNormalBuffer;
  webgl.Buffer cubeVertexTangentBuffer;
  List<double> vertices, textureCoords, vertexNormals, vertexTangents, colors;
  List<int> cubeVertexIndices;
  bool inited = false;
  
  RenderGroup () {
    this.renderables = new List<Segment>();
  }
  
  void initBuffers(webgl.RenderingContext gl) {
    // vertex positions
    cubeVertexPositionBuffer = gl.createBuffer();
    vertices = renderables.fold([], (prev, seg) {
      prev.addAll(seg.getVertexPositions());
      return prev;
    });

    // texture coordinates
    cubeVertexTextureCoordBuffer = gl.createBuffer();
    textureCoords = renderables.fold([], (prev, seg) {
      prev.addAll(seg.getTextureCoords(texture_width.toDouble()/512.0, texture_height.toDouble()/512.0));
      return prev;
    });

    // geometry vertex indices
    cubeVertexIndexBuffer = gl.createBuffer();
    cubeVertexIndices = renderables.fold([], (prev, seg) {
      prev.addAll(seg.getVertexIndices((prev.length/6).toInt()*4));
      return prev;
    });

    // normal vectors
    cubeVertexNormalBuffer = gl.createBuffer();
    vertexNormals = renderables.fold([], (prev, seg) {
      prev.addAll(seg.getNormals());
      return prev;
    });
    
    // tangent vectors
    cubeVertexTangentBuffer = gl.createBuffer();
    vertexTangents = renderables.fold([], (prev, seg) {
      prev.addAll(seg.getTangents());
      return prev;
    });

    inited = true;
  }
  
  void render(webgl.RenderingContext gl, int _aVertexPosition, int _aTextureCoord, int _aVertexNormal, int _aVertexTangent, webgl.Program _shaderProgram, webgl.UniformLocation _uUseNormalMap, webgl.UniformLocation _uUseGlowMap) {
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
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexTangentBuffer);
    gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertexTangents), webgl.RenderingContext.STATIC_DRAW); //TODO: cache
    
    // vertices
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexPositionBuffer);
    gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    // texture coordinates
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexTextureCoordBuffer);
    gl.vertexAttribPointer(_aTextureCoord, 2, webgl.RenderingContext.FLOAT, false, 0, 0);

    // normal vectors
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexNormalBuffer);
    gl.vertexAttribPointer(_aVertexNormal, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    
    // tangent vectors
    gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, cubeVertexTangentBuffer);
    gl.vertexAttribPointer(_aVertexTangent, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    
    gl.activeTexture(webgl.RenderingContext.TEXTURE0);
    gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture);
    gl.uniform1i(gl.getUniformLocation(_shaderProgram, "uSampler"), 0);

    if (texture_normal != null) {
      gl.activeTexture(webgl.RenderingContext.TEXTURE1);
      gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture_normal);
      gl.uniform1i(gl.getUniformLocation(_shaderProgram, "uSamplerNormal"), 1);
      gl.uniform1i(_uUseNormalMap, 1);
    } else {
      gl.uniform1i(_uUseNormalMap, 0);
    }
    
    if (texture_glow != null) {
      gl.activeTexture(webgl.RenderingContext.TEXTURE2);
      gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture_glow);
      gl.uniform1i(gl.getUniformLocation(_shaderProgram, "uSamplerGlow"), 2);
      gl.uniform1i(_uUseGlowMap, 1);
    } else {
      gl.uniform1i(_uUseGlowMap, 0);
    }


    gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, cubeVertexIndexBuffer);
    gl.drawElements(webgl.RenderingContext.TRIANGLES, renderables.length*6, webgl.RenderingContext.UNSIGNED_SHORT, 0);
  }
} 
