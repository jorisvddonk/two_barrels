    precision mediump float;

    varying vec2 vTextureCoord;
    varying vec4 vPosition;
    varying vec3 vNormal;
    varying vec3 vVertexNormal;
    varying vec3 vVertexPosition;
    uniform sampler2D uSampler;
    uniform sampler2D uSamplerNormal;
    uniform bool uUseNormalMap;
    
    void main(void) {
      vec4 fragmentColor;
      vec4 nmvec; 
      
      fragmentColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));

      vec3 lightDir;
      lightDir = normalize(vec3(-0.25, -1.75, 0.5) - vVertexPosition.xyz); // light direction for each pixel

      
      float lightVal;
      
      if (uUseNormalMap) {
        //TODO: use the fucking normal map
        //normalmap data: texture2D(uSamplerNormal, vec2(vTextureCoord.s, vTextureCoord.t))
      }
      lightVal = max(dot(normalize(vNormal), lightDir), 0.0);
      vec3 light3Val = vec3(1.0,0.8,0.8) * lightVal + vec3(0.0,0.0,0.3); // light*lightVal * ambient

      gl_FragColor = vec4(fragmentColor.r*light3Val.r, fragmentColor.g*light3Val.g, fragmentColor.b*light3Val.b, 1.0);
      //gl_FragColor = vec4(light3Val.r, light3Val.g, light3Val.b, 1.0); // debugging view
    }