// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Wireframe/Unlit" {
  Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _Width ("Width", Float) = 0.005
  }
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    Cull Off
    Blend SrcAlpha OneMinusSrcAlpha
    ZWrite Off
    LOD 100

    Pass {
      CGPROGRAM
      #pragma target 4.0
      #pragma vertex vert
      #pragma geometry geo
      #pragma fragment frag
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
      };

      struct v2g {
        float4 vertex : POSITION;
      };

      struct g2f {
        float4 vertex : SV_POSITION;        
        float4 color  : TEXCOORD0;
      };

      float4 _Color;
      float _Width;
      
      v2g vert (appdata v) {
        v2g o;
        o.vertex = v.vertex;
        return o;
      }

      [maxvertexcount(21)]
      void geo(triangle v2g v[3], inout TriangleStream<g2f> TriStream) {
        for (int i = 0; i < 3; i++) {
          g2f o;
          o.vertex = UnityObjectToClipPos(v[i].vertex);
          o.color  = float4(1,0,0,0.0);
          TriStream.Append(o);
        }
        TriStream.RestartStrip();

        for (int i = 0; i < 3; i++) {
          v2g vb = v[(i + 0) % 3];
          v2g v1 = v[(i + 1) % 3];
          v2g v2 = v[(i + 2) % 3];

          float3 dir = normalize((v1.vertex.xyz + v2.vertex.xyz) * 0.5 - vb.vertex.xyz);

          g2f o;
          o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz, 1));
          o.color  = _Color;
          TriStream.Append(o);

          o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz, 1));
          o.color  = _Color;
          TriStream.Append(o);

          o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz + dir * _Width, 1));
          o.color  = _Color;
          TriStream.Append(o);
          TriStream.RestartStrip();

          o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz, 1));
          o.color  = _Color;
          TriStream.Append(o);

          o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz + dir * _Width, 1));
          o.color  = _Color;
          TriStream.Append(o);

          o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz + dir * _Width, 1));
          o.color  = _Color;
          TriStream.Append(o);
          TriStream.RestartStrip();
        }

      }

      fixed4 frag (g2f i) : SV_Target {
        fixed4 col = i.color;
        return col;
      }
      ENDCG
    }
  }
}
