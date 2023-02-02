Shader "Explanation/MatCap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_MatCap ("Mat Cap", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float2 matcapUV : TEXCOORD2;
            };

            sampler2D _MainTex;
			sampler2D _MatCap;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 map = cross(worldNormal, worldViewDir);
				map = mul((float3x3)UNITY_MATRIX_V, map);
				
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.matcapUV = map.xy * 0.5f + 0.5;
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 col = tex2D(_MatCap, i.matcapUV);
				
				
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
