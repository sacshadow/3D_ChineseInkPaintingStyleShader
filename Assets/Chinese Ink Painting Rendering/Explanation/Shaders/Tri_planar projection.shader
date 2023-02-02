Shader "Explanation/Tri_planar projection"
{
    Properties
    {
        _TexTop ("Texture Top", 2D) = "white" {}
        _TexForward ("Texture Forward", 2D) = "white" {}
        _TexSide ("Texture Side", 2D) = "white" {}
        _TexDown ("Texture Down", 2D) = "white" {}
		
		_Size("Size{top x, forward y, side z, down w}", Vector) = (1,1,1,1)
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
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD2;
				float3 normal : TEXCOORD3;
            };

            sampler2D _TexTop;
            sampler2D _TexForward;
            sampler2D _TexSide;
            sampler2D _TexDown;
            fixed4 _Size;

            v2f vert (appdata v)
            {
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.worldPos = worldPos;
				o.normal = worldNormal;
				
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 top 		= tex2D(_TexTop, i.worldPos.xz * _Size.x);
				fixed4 forward 	= tex2D(_TexForward, i.worldPos.xy * _Size.y);
				fixed4 side 	= tex2D(_TexSide, i.worldPos.yz * _Size.z);
				fixed4 down 	= tex2D(_TexDown, i.worldPos.xz * _Size.w);
				
				fixed4 col = 1;
				col.rgb = top * clamp(i.normal.y,0,1) ;
				col.rgb = lerp(col.rgb, forward, abs(i.normal.z));
				col.rgb = lerp(col.rgb, side, abs(i.normal.x));
				col.rgb = lerp(col.rgb, down, clamp(-i.normal.y,0,1));
				
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
