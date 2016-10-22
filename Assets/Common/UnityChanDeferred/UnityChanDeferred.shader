Shader "UnityChan/UnityChanDeffered" {
  Properties {
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)
    _Tint ("Tint", Color) = (1,1,1,1)
    _Ambient ("Ambient", Range(0,1)) = 0
  }
  SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass {
      Tags { "LightMode" = "Deferred" }
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #include "UnityCG.cginc"

      sampler2D _MainTex; float4 _MainTex_ST;
      sampler2D _BumpTex; float4 _BumpTex_ST;
      float4    _SpecularGloss;
      float4    _Emission;

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

        o.pos       = mul(UNITY_MATRIX_MVP, v.vertex);
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
        float4   diffuse = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));

        float3x3 tanTrans    = float3x3(i.tangent, i.bitangent, i.normal);
        float3   normalLocal = UnpackNormal(tex2D(_BumpTex, TRANSFORM_TEX(i.uv, _BumpTex)));
        float3   normalWorld = normalize(mul(normalLocal, tanTrans));

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
