Shader "Raymarch/World_Rain" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _HeightTex ("Height Map", 2D) = "white" {}

    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

     [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

    CGINCLUDE
      float4 _Size;
      sampler2D _HeightTex;

      float _PosNums;
      float4 _PosArray[32];

      #include "RaymarchModules.cginc"
      #include "noiseSimplex.cginc"

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);
        p.xz *= -1;

        //float height = -2 + tex2D(_HeightTex, p.xz * 0.05 + 0.5).r * 0.4 - 1;
        float height = -2;
        //float height = -4 + snoise(p * 0.2) * 2;

        float db = sdBox(p - float3(0,height,0), float3(10,2,10));
        float d1 = sdCylinder(p - float3(0,-2,0), float4(50,1,0,0));
        float d2 = sdCylinder(p - float3(35,0,45), float4(30,200,0,0));
        float d3 = sdCylinder(p - float3(-30,0,40), float4(20,200,0,0));

        db = opUni(opUni(opUni(db, d1, 6), d2, 2), d3, 2);

        int n = (int)_PosNums;
        for (int i = 0; i < n; i++) {
          //float d = sdSphere(p - _PosArray[i].xyz, float3(1,1,1)*1);
          //db = opUni(db, d, 10);
        }

        return db;
      }

      float2 uvFunc(float3 p) {
        float2 uv = uvFuncQuartz(p);
        uv.y *= -1;
        return uv;
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 0.01
      #define RAY_ITERATION 64 //64 // 128
      #include "RaymarchCore.cginc"
    ENDCG

		Pass {
      Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex vert_raymarch
			#pragma fragment frag_raymarch
     	ENDCG
		}

  }
}
