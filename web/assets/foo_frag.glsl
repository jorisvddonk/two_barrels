    precision mediump float;

    varying vec2 vTextureCoord;
    varying vec4 vPosition;
    varying vec3 vNormal;
    varying vec3 vPPosition;
    varying vec3 vTangent;
    varying vec3 vVertexNormal;
    varying vec3 vVertexTangent;
    varying vec3 vVertexPosition;
    uniform sampler2D uSampler;
    uniform sampler2D uSamplerNormal;
    uniform sampler2D uSamplerGlow;
    uniform bool uUseNormalMap;
    uniform bool uUseGlowMap;

    void main(void) {
      vec4 fragmentColor;
      vec3 nmvec; 
      float lightVal;
      vec3 light3Val;
      vec3 lightDir;
      mat3 TBN;
      
      fragmentColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));

      lightDir = normalize(vec3(-0.25, -1.75, 0.5) - vVertexPosition.xyz); // light direction for each pixel
      
      nmvec = vNormal;
      TBN = mat3(vTangent, cross(vTangent, vNormal), vNormal); // matrix used to convert between world and tangent space

      if (uUseNormalMap) {
        vec3 texNormal = texture2D(uSamplerNormal, vec2(vTextureCoord.s, vTextureCoord.t)).rgb;
        texNormal = 2.0*texNormal-1.0;
        nmvec = texNormal; // don't multiply nmvec with TBN
      }

      vec3 glowColor; // glowcolor is always added, and is not modified by the relevant pixel's lighting value
      glowColor = vec3(0.0,0.0,0.0); 
      if (uUseGlowMap) {
        glowColor = texture2D(uSamplerGlow, vec2(vTextureCoord.s, vTextureCoord.t)).rgb;
      }

      lightDir = lightDir * TBN;

      nmvec = normalize(nmvec);
      lightDir = normalize(lightDir);
      
      lightVal = max(dot(nmvec, lightDir), 0.0);
      light3Val = vec3(1.0,1.0,1.0) * lightVal + vec3(0.0,0.0,0.0); // light*lightVal * ambient
      gl_FragColor = vec4(
        (fragmentColor.r*light3Val.r)+glowColor.r, 
        (fragmentColor.g*light3Val.g)+glowColor.g, 
        (fragmentColor.b*light3Val.b)+glowColor.b, 
        1.0);
    }