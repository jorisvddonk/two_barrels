library two_barrels;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'dart:collection';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import 'dart:math' as math;

part 'renderable.dart';
part 'segment.dart';
part 'floortile.dart';
part 'player.dart';
part 'rendergroup.dart';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=571
 * https://github.com/martinsik/dart-webgl-tutorials
 */
class Lesson07 {

  CanvasElement _canvas;
  webgl.RenderingContext _gl;
  webgl.Program _shaderProgram;
  int _viewportWidth, _viewportHeight;

  HashMap<webgl.Texture, RenderGroup> rendergroups;
  HashMap<String, webgl.Texture> textures;



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

  int _filter = 0;
  double _lastTime = 0.0;

  List<bool> _currentlyPressedKeys;

  var _requestAnimationFrame;

  
  void resize(CanvasElement canvas, num width, num height) {
    canvas.setAttribute("width",  "${width}px");
    canvas.setAttribute("height",  "${height}px");
    _viewportWidth = width;
    _viewportHeight = height;
  }

  Lesson07(CanvasElement canvas) {
    window.onResize.listen((e){
      resize(canvas, e.currentTarget.innerWidth, e.currentTarget.innerHeight);
    });
    // weird, but without specifying size this array throws exception on []
    _currentlyPressedKeys = new List<bool>(128);
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");

    _mvMatrix = new Matrix4.identity();
    _pMatrix = new Matrix4.identity();
    textures = new HashMap<String, webgl.Texture>();
    rendergroups = new HashMap<webgl.Texture, RenderGroup>();

    initGame();
    _initShaders();
    _initTexture("./assets/trak5/floor2a.png");
    _initTexture("./assets/trak5/tile2a.png");
   _initBuffers();

    
    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(webgl.RenderingContext.DEPTH_TEST);

    document.onKeyDown.listen(this._handleKeyDown);
    document.onKeyUp.listen(this._handleKeyUp);
    
    resize(canvas, window.innerWidth, window.innerHeight);

  }

  void initGame() {
    player = new Player();    
  }

  void _initShaders() {
    // vertex shader
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec3 aVertexNormal;
    attribute vec2 aTextureCoord;

    varying vec4 vPosition;
    varying vec3 vNormal;
    varying vec3 vVertexNormal;
    varying vec3 vVertexPosition;
    varying vec2 vTextureCoord;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    uniform mat3 uNMatrix;
    
    void main(void) {
      // copy values into shared vars
      vVertexNormal = aVertexNormal;
      vVertexPosition = aVertexPosition;

      // do other stuff
      vPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
      gl_Position = uPMatrix * vPosition;
      vTextureCoord = aTextureCoord;
      vNormal = uNMatrix * aVertexNormal;
    }
    """;

    // fragment shader
    String fsSource = """
    precision mediump float;

    varying vec2 vTextureCoord;
    varying vec4 vPosition;
    varying vec3 vNormal;
    varying vec3 vVertexNormal;
    uniform sampler2D uSampler;
    
    void main(void) { 
      vec4 fragmentColor;
      fragmentColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
      gl_FragColor = vec4(abs(vNormal.x)*1.0, abs(vNormal.y)*1.0, abs(vNormal.z)*1.0, 1.0);
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
    List<Segment> wsegments;
    List<FloorTile> ftiles;
    wsegments = new List<Segment>();
    ftiles = new List<FloorTile>();
    
    wsegments.add(new Segment(new Vector2(-1.0,-1.0), new Vector2(-1.0, 1.0)));
    wsegments.add(new Segment(new Vector2(-1.0, 1.0), new Vector2( 2.0, 1.0)));
    wsegments.add(new Segment(new Vector2( 2.0, 1.0), new Vector2( 2.0,-1.0)));
    
    ftiles.add(new FloorTile(new Vector2(-1.0,-1.0), new Vector2(-1.0, 1.0), new Vector2(2.0,1.0), new Vector2(2.0,-1.0)));
    
    
    rendergroups[textures["./assets/trak5/tile2a.png"]].renderables = wsegments;
    rendergroups[textures["./assets/trak5/floor2a.png"]].renderables = ftiles;
    
    
    rendergroups.forEach((texture, rendergroup){
      rendergroup.initBuffers(_gl);
    });
  }

  void _initTexture(String src) {
    webgl.Texture textur = _gl.createTexture();
    textures[src] = textur;
    ImageElement image = new Element.tag('img');
    image.onLoad.listen((e) {
      _handleLoadedTexture(textur, image);
    });
    image.src = src;
    rendergroups.putIfAbsent(textur, (){
      RenderGroup rg = new RenderGroup(textur, src);
      return rg;
    });
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

    Matrix3 normalMatrix = _mvMatrix.getRotation();
    // flip Y and Z, as the player moves around on the X/Y plane and Z is 'upwards'
    // TODO: perhaps figure out if this is really what should be done (e.g. if this kind of hackery is common). :P
    Vector3 r2 = normalMatrix.row2;
    Vector3 r1 = normalMatrix.row1;
    normalMatrix.row2 = r1;
    normalMatrix.row1 = r2;
    
    _gl.uniformMatrix3fv(_uNMatrix, false, normalMatrix.storage);
  }

  bool render(double time) {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(webgl.RenderingContext.COLOR_BUFFER_BIT | webgl.RenderingContext.DEPTH_BUFFER_BIT);

    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.01, 100.0);

    // setup modelviewmatrix
    _mvMatrix = new Matrix4.identity();
    _mvMatrix.rotate(new Vector3(1.0, 0.0, 0.0), radians(-90.0));    
    _mvMatrix.rotate(new Vector3(0.0, 0.0, 1.0), math.atan2(player.rotation.x, player.rotation.y));
    _mvMatrix.translate(new Vector3(-player.position.x, -player.position.y, player.zpos));

    _setMatrixUniforms();
    rendergroups.forEach((texture, rendergroup){
      rendergroup.render(_gl, _aVertexPosition, _aTextureCoord, _aVertexNormal);
    });
    
    // move
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
      rendergroups.forEach((texture, rendergroup){
        if (rendergroup.renderables is List<Segment>) {
          player.clipMotion(rendergroup.renderables);
        }
      });
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
