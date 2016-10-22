Shader "Raymarch/World_Quartz" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Mandel ("Mandel", Vector) = (1,1,0.5,1)

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
      float4 _Mandel;

      #define FRAC_ITERATION 6
      #include "RaymarchModules.cginc"

      float sdFunc_GroundBall(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);
        p = trRotate(p, M_PI / 4, float3(0,1,0));

        float d1 = sdBox(p + float3(0,10,0), float3(1,10,1));
        float d2 = sdSphere(p + float3(0,3,0), 2.5);

        float3 p3 = trRotate(p, M_PI / 4, float3(0,1,0));
        float d3 = sdBox(p3 + float3(0,25,0), float3(3.5,20,3.5));

        float3 p4 = trRepeat(p, (sin(_Time.x) * 0.5 + 3.5));
        float d4 = sdSphere(p4, (sin(2.2 * _Time.x) * 0.5 + 1.0));
        d2 += d4 * 0.2 * (sin(2.7 * _Time.x + M_PI / 2) + 1);

        return opUni(opUni(d1, d2, 4), d3, 2);
      }

      float sdFunc_Frac(float3 p, float bailout, float power, float l, float t) {
        float3 z = p;
        float dr = 1;
        float r = 0;
        for (int i = 0; i < FRAC_ITERATION; i++) {
          z = fBoxFold(z, l);

          r = length(z);
          if (r > bailout) break;

          float theta = acos(z.z/r);
          float phi = atan2(z.y, z.x);
          dr = pow(r, power-1)*power*dr + 1;

          float zr = pow(r, power);
          theta = theta * power;
          phi = phi * power;

          z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
          z += p;
        }
        return 0.5*log(r)*r/dr;
      }

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);
        float d1 = sdFunc_GroundBall(p);
        //return d1;

        p = trRotate(p, p.z * 0.1, float3(0,0,1));
        float3 p2 = trRepeat(p, _Mandel.w);
        p2 = trRotate(p2, p.z * 0.05, float3(0,0,1));
        float d2 = sdFunc_Frac(p2, _Mandel.x, _Mandel.y, _Mandel.z, _Mandel.w);
        //return d2;

        return opUni(d1, d2, 10);
      }

      float2 uvFunc(float3 p) {
        return uvFuncQuartz(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 3
      #define RAY_ITERATION 64 // 128
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
