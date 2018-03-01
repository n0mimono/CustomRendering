// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Raymarch/Texture_Bulb" {
  Properties {
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (1,1,1,1)
    _Emission ("Emission", Color) = (1,1,1,1)
    _Tint ("Tint", Color) = (1,1,1,1)
    _Ambient ("Ambient", Range(0,1)) = 0

    _Mandel ("Mandel", Vector) = (0.5, 10, 9, 0.5)

  }
  SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    CGINCLUDE
      float4 _Mandel;

      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        p = trRepeat(p, _Mandel.y);
        p.z = _Mandel.x;
        return sdFractalMandelbulb(p, 10, _Mandel.z);
      }

      float4 normalFunc(float4 buf, float3 p, float d, float i) {
        float3 n = buf.xyz * 2 - 1;
        float3 m = float3(0,0,1);
        n = normalize(lerp(m, n, _Mandel.w));
        return float4(n * 0.5 + 0.5, 1);
      }

      #define DIST_FUNC distFunc
      #define NORMAL_FUNC normalFunc
      #include "RaymarchCore.cginc"
    ENDCG

    Pass {
      Tags { "LightMode" = "Deferred" }
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #include "UnityCG.cginc"
      #include "UnityStandardUtils.cginc"

      float4    _Tint;
      float     _Ambient;

      struct v2f {
        float4 pos       : SV_POSITION;
        float2 uv        : TEXCOORD0;
        float3 normal    : TEXCOORD1;
        float3 tangent   : TEXCOORD2;
        float3 bitangent : TEXCOORD3;
      };
      
      v2f vert(appdata_full v) {
        v2f o;

        o.pos       = UnityObjectToClipPos(v.vertex);
        o.uv        = v.texcoord;
        o.normal    = UnityObjectToWorldNormal(v.normal);
        o.tangent   = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0)).xyz);
        o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);

        return o;
      }
      
      void frag (v2f i,
        out float4 outAlbedo   : SV_Target0,
        out float4 outSpecular : SV_Target1,
        out float4 outNormal   : SV_Target2,
        out float4 outEmission : SV_Target3
      ) {
        texture_out tex = texture_raymarch(float4(i.uv, 0, 1));

        float4   diffuse = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));

        float3x3 tanTrans    = float3x3(i.tangent, i.bitangent, i.normal);
        float3   normalLocal1 = UnpackNormal(tex2D(_BumpTex, TRANSFORM_TEX(i.uv, _BumpTex)));
        float3   normalLocal2 = tex.normal * 2 - 1;
        float3   normalLocal  = BlendNormals(normalLocal1, normalLocal2);
        float3   normalWorld  = normalize(mul(normalLocal, tanTrans));

        outAlbedo   = diffuse * _Tint;
        outSpecular = _SpecularGloss;
        outNormal   = float4(normalWorld * 0.5 + 0.5, 1);
        outEmission = _Emission - diffuse * _Ambient;
      }
      ENDCG
    }
  }
  Fallback "Diffuse"
}
