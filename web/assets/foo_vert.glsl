attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec3 aVertexTangent;
attribute vec2 aTextureCoord;

varying vec4 vPosition;
varying vec3 vPPosition;
varying vec3 vNormal;
varying vec3 vTangent;
varying vec3 vVertexNormal;
varying vec3 vVertexTangent;
varying vec3 vVertexPosition;
varying vec2 vTextureCoord;

uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
uniform mat3 uIdentMatrix;

void main(void) {
  // copy values into shared vars
  vVertexNormal = aVertexNormal;
  vVertexPosition = aVertexPosition;
  vVertexTangent = aVertexTangent;

  // do other stuff
  vPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
  gl_Position = uPMatrix * vPosition;
  vTextureCoord = aTextureCoord;
  vNormal = uIdentMatrix * aVertexNormal;
  vTangent = uIdentMatrix * aVertexTangent;
  vPPosition = uIdentMatrix * aVertexPosition;
}