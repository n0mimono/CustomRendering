Shader "Wireframe/UnlitReproduct" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}

    [Header(Wireframe)]
    _Color ("Color", Color) = (1,1,1,1)
    _Width ("Width", Float) = 0.005

    [Header(World)]
    _HeightOffset ("Height Offest", Float) = 0
    _HeightPower ("Height Power", Float) = 0

    [Header(Rim)]
    _RimPower ("Rim Power", Float) = 1
    _RimAmplitude ("Rim Amplitude", Float) = 1
    _RimTint ("Rim Tint", Color) = (1,1,1,1)
  }

  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 100

    Pass {
      Cull Off
      Blend SrcAlpha OneMinusSrcAlpha
      ZWrite Off

      CGPROGRAM
      #pragma target 4.0
      #pragma vertex vert
      #pragma geometry geo
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float4 color : COLOR;
      };

      struct v2g {
        float4 vertex : POSITION;
        float4 color : TEXCOORD0;
      };

      struct g2f {
        float4 vertex : SV_POSITION;        
        float4 color  : TEXCOORD0;
        UNITY_FOG_COORDS(1)
      };

      float4 _Color;
      float _Width;
      
      v2g vert (appdata v) {
        v2g o;
        o.vertex = v.vertex;
        o.color = v.color;
        return o;
      }

      [maxvertexcount(21)]
      void geo(triangle v2g v[3], inout TriangleStream<g2f> TriStream) {

        for (int i = 0; i < 3; i++) {
          v2g vb = v[(i + 0) % 3];
          v2g v1 = v[(i + 1) % 3];
          v2g v2 = v[(i + 2) % 3];

          float3 dir = normalize((v1.vertex.xyz + v2.vertex.xyz) * 0.5 - vb.vertex.xyz);

          g2f o;
          o.color  = _Color * v[0].color;

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v1.vertex.xyz, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v2.vertex.xyz, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v2.vertex.xyz + dir * _Width, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);
          TriStream.RestartStrip();

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v1.vertex.xyz, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v1.vertex.xyz + dir * _Width, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);

          o.vertex = mul(UNITY_MATRIX_MVP, float4(v2.vertex.xyz + dir * _Width, 1));
          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);
          TriStream.RestartStrip();
        }

      }

      fixed4 frag (g2f i) : SV_Target {
        fixed4 col = i.color;
        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }

    Pass {
      Cull Back
      Blend SrcAlpha OneMinusSrcAlpha

      CGPROGRAM
      #pragma target 4.0
      #pragma vertex vert
      #pragma geometry geo
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float2 uv     : TEXCOORD0;
        float4 color  : COLOR;
        float3 normal : NORMAL;
      };

      struct v2f {
        float4 vertex : SV_POSITION;        
        float2 uv     : TEXCOORD0;
        float4 wpos   : TEXCOORD1;
        float4 color  : TEXCOORD2;
        float3 normal : TEXCOORD3;
        UNITY_FOG_COORDS(4)
      };

      sampler2D _MainTex; float4 _MainTex_ST;
      float _HeightOffset;
      float _HeightPower;
      float _RimPower;
      float _RimAmplitude;
      float4 _RimTint;

      v2f vert (appdata v) {
        v2f o;
        o.vertex = v.vertex;
        o.uv     = TRANSFORM_TEX(v.uv, _MainTex);
        o.wpos   = mul(unity_ObjectToWorld, v.vertex);
        o.color  = v.color;
        o.normal = v.normal;
        return o;
      }

      float halpha(float y) {
        return pow(saturate(y) + _HeightOffset, _HeightPower);
      }

      float3 twist(float3 p, float power){
        float s = sin(power * p.y);
        float c = cos(power * p.y);
        float3x3 m = float3x3(
            c, -s, 0,
            s, c,  0,
            0, 0,  1
         );
         return mul(m, p);
      }

      [maxvertexcount(21)]
      void geo(triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
        float3 normal = normalize(v[0].normal + v[1].normal + v[2].normal);
        float t = max(0,sin(_Time.y * 0.5));

        for (int i = 0; i < 3; i++) {
          v2f o = v[i];
          float origin = v[i].vertex.xyz;
          v[i].vertex.xyz += normal * t * (1 + 5 * v[i].vertex.y);
          v[i].vertex.xyz = twist(v[i].vertex.xyz, 5 * t);

          o.vertex = mul(UNITY_MATRIX_MVP, v[i].vertex);
          o.normal = UnityObjectToWorldNormal(v[i].normal);

          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);
        }
        TriStream.RestartStrip();
      }

      fixed4 frag (v2f i) : SV_Target {
        float3 normalDir = normalize(i.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
        float NNdotV = 1 - dot(normalDir, viewDir);
        float rim = pow(NNdotV, _RimPower) * _RimAmplitude;

        float alpha = halpha(i.wpos.y);

        float4 col = tex2D(_MainTex, i.uv) * i.color;
        col.rgb = col.rgb * _RimTint.a + rim * _RimTint.rgb;
        col.a *= alpha;

        //UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }

  }
}
