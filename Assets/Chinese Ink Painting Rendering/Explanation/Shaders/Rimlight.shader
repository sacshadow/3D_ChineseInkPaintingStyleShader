Shader "Explanation/Rimlight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (0,1,1,1)
		_RimRate ("Rim Rate", Range(0,5)) = 1
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
				float rim : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _RimColor;
			float _RimRate;

            v2f vert (appdata v)
            {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				float rim = clamp(1 - saturate(dot(worldViewDir, worldNormal)),0,1);
				rim = clamp(pow(rim, _RimRate),0,1);
				
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.rim = rim;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				
				col.rgb = lerp(col.rgb, _RimColor.rgb, i.rim);
				
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
				return col;
            }
            ENDCG
        }
    }
}
