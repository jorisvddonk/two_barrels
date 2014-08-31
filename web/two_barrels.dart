library two_barrels;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import 'dart:math' as math;

part 'segment.dart';
part 'player.dart';


/**
 * based on:
 * http://learningwebgl.com/blog/?p=571
 *
 * NOTE: To run this example you have to open in on a webserver (url starting with http:// NOT file:///)!
 */
class Lesson07 {

  CanvasElement _canvas;
  webgl.RenderingContext _gl;
  webgl.Program _shaderProgram;
  int _viewportWidth, _viewportHeight;

  webgl.Texture _texture;

  webgl.Buffer _cubeVertexTextureCoordBuffer;
  webgl.Buffer _cubeVertexPositionBuffer;
  webgl.Buffer _cubeVertexIndexBuffer;
  webgl.Buffer _cubeVertexNormalBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;
  Queue<Matrix4> _mvMatrixStack;

  int _aVertexPosition;
  int _aTextureCoord;
  int _aVertexNormal;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;
  webgl.UniformLocation _uNMatrix;
  webgl.UniformLocation _uSampler;
  webgl.UniformLocation _uUseLighting;
  webgl.UniformLocation _uLightingDirection;
  webgl.UniformLocation _uAmbientColor;
  webgl.UniformLocation _uDirectionalColor;
  
  Player player;  
  List<Segment> segments;

  int _filter = 0;
  double _lastTime = 0.0;

  List<bool> _currentlyPressedKeys;

  var _requestAnimationFrame;


  Lesson07(CanvasElement canvas) {
    window.onResize.listen((e){
      print("Resized window");
      canvas.setAttribute("width",  "${e.currentTarget.innerWidth}px");
          canvas.setAttribute("height",  "${e.currentTarget.innerHeight}px");
      _viewportWidth = e.currentTarget.innerWidth;
      _viewportHeight = e.currentTarget.innerHeight;
    });
    // weird, but without specifying size this array throws exception on []
    _currentlyPressedKeys = new List<bool>(128);
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");

    _mvMatrix = new Matrix4.identity();
    _pMatrix = new Matrix4.identity();

    initGame();
    _initShaders();
    _initBuffers();
    _initTexture();
    

    /*if (window.dynamic['requestAnimationFrame']) {
      _requestAnimationFrame = window.requestAnimationFrame;
    } else if (window.dynamic['requestAnimationFrame']) {
      _requestAnimationFrame = window.requestAnimationFrame;
    } else if (window.dynamic['mozRequestAnimationFrame']) {
      _requestAnimationFrame = window.mozRequestAnimationFrame;
    }*/
    //_requestAnimationFrame = window.requestAnimationFrame;

    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(webgl.RenderingContext.DEPTH_TEST);

    document.onKeyDown.listen(this._handleKeyDown);
    document.onKeyUp.listen(this._handleKeyUp);

  }

  void initGame() {
    player = new Player();    
  }

  void _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec3 aVertexNormal;
    attribute vec2 aTextureCoord;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    uniform mat3 uNMatrix;
  
    uniform vec3 uAmbientColor;
  
    uniform vec3 uLightingDirection;
    uniform vec3 uDirectionalColor;
  
    uniform bool uUseLighting;
  
    varying vec2 vTextureCoord;
    varying vec3 vLightWeighting;
  
    void main(void) {
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      vTextureCoord = aTextureCoord;
  
      if (!uUseLighting) {
        vLightWeighting = vec3(1.0, 1.0, 1.0);
      } else {
        vec3 transformedNormal = uNMatrix * aVertexNormal;
        float directionalLightWeighting = max(dot(transformedNormal, uLightingDirection), 0.0);
        vLightWeighting = uAmbientColor + uDirectionalColor * directionalLightWeighting;
      }
    }""";

    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;
    
    varying vec2 vTextureCoord;
    varying vec3 vLightWeighting;
    
    uniform sampler2D uSampler;
    
    void main(void) {
       vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
       gl_FragColor = vec4(textureColor.rgb * vLightWeighting, textureColor.a);
    }
    """;

    // vertex shader compilation
    webgl.Shader vs = _gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
    _gl.shaderSource(vs, vsSource);
    _gl.compileShader(vs);

    // fragment shader compilation
    webgl.Shader fs = _gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
    _gl.shaderSource(fs, fsSource);
    _gl.compileShader(fs);

    // attach shaders to a webgl. program
    _shaderProgram = _gl.createProgram();
    _gl.attachShader(_shaderProgram, vs);
    _gl.attachShader(_shaderProgram, fs);
    _gl.linkProgram(_shaderProgram);
    _gl.useProgram(_shaderProgram);

    /**
     * Check if shaders were compiled properly. This is probably the most painful part
     * since there's no way to "debug" shader compilation
     */
    if (!_gl.getShaderParameter(vs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(vs));
    }

    if (!_gl.getShaderParameter(fs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(fs));
    }

    if (!_gl.getProgramParameter(_shaderProgram, webgl.RenderingContext.LINK_STATUS)) {
      print(_gl.getProgramInfoLog(_shaderProgram));
    }

    _aVertexPosition = _gl.getAttribLocation(_shaderProgram, "aVertexPosition");
    _gl.enableVertexAttribArray(_aVertexPosition);

    _aTextureCoord = _gl.getAttribLocation(_shaderProgram, "aTextureCoord");
    _gl.enableVertexAttribArray(_aTextureCoord);

    _aVertexNormal = _gl.getAttribLocation(_shaderProgram, "aVertexNormal");
    _gl.enableVertexAttribArray(_aVertexNormal);

    _uPMatrix = _gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = _gl.getUniformLocation(_shaderProgram, "uMVMatrix");
    _uNMatrix = _gl.getUniformLocation(_shaderProgram, "uNMatrix");
    _uSampler = _gl.getUniformLocation(_shaderProgram, "uSampler");
    _uUseLighting = _gl.getUniformLocation(_shaderProgram, "uUseLighting");
    _uAmbientColor = _gl.getUniformLocation(_shaderProgram, "uAmbientColor");
    _uLightingDirection = _gl.getUniformLocation(_shaderProgram, "uLightingDirection");
    _uDirectionalColor = _gl.getUniformLocation(_shaderProgram, "uDirectionalColor");
  }

  void _initBuffers() {
    segments = new List<Segment>();
    segments.add(new Segment(new Vector2(-1.0,-1.0), new Vector2(-1.0, 1.0)));
    segments.add(new Segment(new Vector2(-1.0, 1.0), new Vector2( 1.0, 1.0)));
    segments.add(new Segment(new Vector2( 1.0, 1.0), new Vector2( 1.0,-1.0)));
    
    
    
    
    // variables to store verticies, tecture coordinates and colors
    List<double> vertices, textureCoords, vertexNormals, colors;


    // vertex positions
    _cubeVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    vertices = segments.fold([], (prev, seg) {
      prev.addAll(seg.getVertexPositions());
      return prev;
    });
    _gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    // texture coordinates
    _cubeVertexTextureCoordBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    textureCoords = segments.fold([], (prev, seg) {
      prev.addAll(seg.getTextureCoords());
      return prev;
    });
    _gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(textureCoords), webgl.RenderingContext.STATIC_DRAW);

    // geometry vertex indices
    _cubeVertexIndexBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    List<int> _cubeVertexIndices = segments.fold([], (prev, seg) {
      prev.addAll(seg.getVertexIndices((prev.length/6).toInt()*4));
      return prev;
    });
    _gl.bufferData(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_cubeVertexIndices), webgl.RenderingContext.STATIC_DRAW);


    _cubeVertexNormalBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexNormalBuffer);
    vertexNormals = segments.fold([], (prev, seg) {
      prev.addAll(seg.getNormals());
      return prev;
    });
    _gl.bufferData(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertexNormals), webgl.RenderingContext.STATIC_DRAW);

  }

  void _initTexture() {
    _texture = _gl.createTexture();
    ImageElement image = new Element.tag('img');
    image.onLoad.listen((e) {
      _handleLoadedTexture(_texture, image);
    });
    image.src = "./crate.gif";
  }

  void _handleLoadedTexture(webgl.Texture texture, ImageElement img) {
    _gl.pixelStorei(webgl.RenderingContext.UNPACK_FLIP_Y_WEBGL, 1); // second argument must be an int (no boolean)

    _gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, texture);
    _gl.texImage2D(webgl.RenderingContext.TEXTURE_2D, 0, webgl.RenderingContext.RGBA, webgl.RenderingContext.RGBA, webgl.RenderingContext.UNSIGNED_BYTE, img);
    _gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MAG_FILTER, webgl.RenderingContext.LINEAR);
    _gl.texParameteri(webgl.RenderingContext.TEXTURE_2D, webgl.RenderingContext.TEXTURE_MIN_FILTER, webgl.RenderingContext.LINEAR_MIPMAP_NEAREST);
    _gl.generateMipmap(webgl.RenderingContext.TEXTURE_2D);

    _gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, null);
  }

  void _setMatrixUniforms() {
    _gl.uniformMatrix4fv(_uPMatrix, false, _pMatrix.storage);
    _gl.uniformMatrix4fv(_uMVMatrix, false, _mvMatrix.storage);

    //Matrix3 normalMatrix = _mvMatrix.toInverseMat3();
    Matrix3 normalMatrix = _mvMatrix.getRotation();
    normalMatrix.transpose();
    _gl.uniformMatrix3fv(_uNMatrix, false, normalMatrix.storage);
  }

  bool render(double time) {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(webgl.RenderingContext.COLOR_BUFFER_BIT | webgl.RenderingContext.DEPTH_BUFFER_BIT);

    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.01, 100.0);

    // draw triangle
    _mvMatrix = new Matrix4.identity();

    _mvMatrix.rotate(new Vector3(1.0, 0.0, 0.0), radians(-90.0));
    
    _mvMatrix.rotate(new Vector3(0.0, 0.0, 1.0), math.atan2(player.rotation.x, player.rotation.y));
    //_mvMatrix.rotate(new Vector3(0.0, 1.0, 1.0), _degToRad(player.rotation.y));
    _mvMatrix.translate(new Vector3(-player.position.x, -player.position.y, player.zpos));

    // verticies
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, 3, webgl.RenderingContext.FLOAT, false, 0, 0);

    // texture
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexTextureCoordBuffer);
    _gl.vertexAttribPointer(_aTextureCoord, 2, webgl.RenderingContext.FLOAT, false, 0, 0);

    // light
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _cubeVertexNormalBuffer);
    _gl.vertexAttribPointer(_aVertexNormal, 3, webgl.RenderingContext.FLOAT, false, 0, 0);


    _gl.activeTexture(webgl.RenderingContext.TEXTURE0);
    _gl.bindTexture(webgl.RenderingContext.TEXTURE_2D, _texture);
    //_gl.uniform1i(_uSamplerUniform, 0);

    if (false) {
      // draw lighting
      _gl.uniform1i(_uUseLighting, 1); // must be int, not bool
      _gl.uniform3f(_uAmbientColor, 5 / 100, 5 / 100, 5 / 100);
      Vector3 lightingDirection = new Vector3(10 / 100, 10 / 100, 10 / 100);
      Vector3 adjustedLD = lightingDirection.normalize();
      //adjustedLD.scale(-1.0);
      _gl.uniform3fv(_uLightingDirection, adjustedLD.storage);
      
      _gl.uniform3f(_uDirectionalColor, 255 / 100, 200 / 100, 20 / 100);
    }

    _gl.bindBuffer(webgl.RenderingContext.ELEMENT_ARRAY_BUFFER, _cubeVertexIndexBuffer);
    _setMatrixUniforms();
    _gl.drawElements(webgl.RenderingContext.TRIANGLES, segments.length*6, webgl.RenderingContext.UNSIGNED_SHORT, 0);

    // rotate
    _animate(time);
    _handleKeys();

    // keep drawing
    window.requestAnimationFrame(this.render);
  }

  void _handleKeyDown(KeyboardEvent event) {
    _currentlyPressedKeys[event.keyCode] = true;
  }

  void _handleKeyUp(KeyboardEvent event) {
    _currentlyPressedKeys[event.keyCode] = false;
  }

  void _animate(double timeNow) {
    if (_lastTime != 0) {
      double elapsed = timeNow - _lastTime;

      player.move(elapsed);
      player.clipMotion(segments);
    }
    _lastTime = timeNow;
  }
  
  bool pressed(num keycode) {
    return (_currentlyPressedKeys.elementAt(keycode) != null && _currentlyPressedKeys.elementAt(keycode));
  }

  void _handleKeys() {
    if (pressed(87)) { //w
      player.movement.add(player.rotation.clone().scale(0.0001));
    }
    if (pressed(83)) { //s
      player.movement.add(player.rotation.clone().scale(-0.0001));
    }
    if (pressed(65)) { //a
      Matrix2 a = new Matrix2.rotation(radians(90.0));      
      player.movement.add(a.transform(player.rotation.clone()).scale(0.0001));
    }
    if (pressed(68)) { //d
      Matrix2 a = new Matrix2.rotation(radians(90.0));      
      player.movement.add(a.transform(player.rotation.clone()).scale(-0.0001));
    }
    if (pressed(81)) { //q
      // doesn't work
      Matrix2 a = new Matrix2.rotation(radians(1.0));
      player.rotation = a.transform(player.rotation.clone()); 
    }
    if (pressed(69)) { //e
      // doesn't work
      Matrix2 a = new Matrix2.rotation(radians(-1.0));
      player.rotation = a.transform(player.rotation.clone());
    }
    if (pressed(32)) { //space
    }
  }

  double _degToRad(double degrees) {
    return degrees * math.PI / 180;
  }

  void start() {
    DateTime d;
    _lastTime = (new DateTime.now()).millisecondsSinceEpoch * 1.0;
    window.requestAnimationFrame(this.render);
  }
}

void main() {
  Lesson07 lesson = new Lesson07(document.querySelector('#game'));
  lesson.start();
}
