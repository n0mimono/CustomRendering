Shader "Raymarch/Sample/Sample01" {
  Properties {
    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

     [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
    [Enum(Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 1
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass {
      Tags { "LightMode" = "Deferred" }
			CGPROGRAM
      #include "RaymarchModules.cginc"
      #include "RaymarchCore.cginc"
			#pragma vertex vert_raymarch
			#pragma fragment frag_raymarch
     	ENDCG
		}
	}
}
