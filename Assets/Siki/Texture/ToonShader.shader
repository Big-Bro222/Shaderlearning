Shader "Unlit/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DiffuseColor("Diffuse",Color)=(1,1,1,1)
        _Outline("Outline Width",Range(0,1))=1
        _OutlineColor("Outline Color",Color)=(0,0,0,1)
        _Steps("Steps",Range(1,30)) = 1
		_ToonEffect("ToonEffect", Range(0,1)) = 0.5
        _RampColor("Ramp Texture",2D)="white"{}
        _RimColor("Rim Light Color",Color)=(1,1,1,1)
        _RimPower("Rim Strength", Range(0.0001,3))=1
        _XRayColor("Oculusion Color",Color)=(1,1,1,1)
        _XRayPower("XRay Power",Range(0.0001,3))=1
    }
    SubShader
    {
        Tags {"Queue"= "Geometry+1000" "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            Name "XRay"
            Tags{ "ForceNoShadowCasting" = "true" }
			Blend SrcAlpha One
            ZTest Greater
            ZWrite Off
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldPos:TEXCOORD2;
            };
            
            fixed4 _XRayColor;
            float _XRayPower;
            
            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,o.vertex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float rim= 1 - dot(i.worldNormal,viewDir);
                fixed3 xrayColor=_XRayColor*pow(rim,1/_XRayPower);
                return float4( xrayColor,1);
            }
            ENDCG
        }
        Pass
        {
            Name "Outline"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                
            };
            
            float _Outline;
            fixed4 _OutlineColor;
            float _Steps;
            float _ToolEffect;
            

            v2f vert (appdata_base v)
            {
                v2f o;
                //物体法线外扩
                //v.vertex.xyz+=_Outline*v.normal;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                
                //视角空间法线外拓
				//float4 pos = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, v.vertex));
				//float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
				//pos = pos + float4(normal,0) * _Outline;
				//o.vertex =  mul(UNITY_MATRIX_P, pos);

				//裁剪空间法线外拓
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
				float2 viewNormal = TransformViewToProjection(normal.xy);
				o.vertex.xy += viewNormal * _Outline;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _RampTex;
            float4 _DiffuseColor;
            float _Steps;
            float _ToonEffect;
            fixed4 _RimColor;
            float _RimPower;
            
            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,o.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed3 worldLightDir=UnityWorldSpaceLightDir(i.worldPos);

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                
                float difLight=dot(worldLightDir,i.worldNormal)*0.5+0.5;

                //渐进纹理采样
                //fixed4 rampColor=tex2D(_RampTex,fixed2(difLight,difLight));
                //fixed3 diffuse=_LightColor0.rgb*albedo*_DiffuseColor.rgb*rampColor;
                
                difLight = smoothstep(0,1,difLight);
                float toon=floor(difLight*_Steps)/_Steps;
                difLight=lerp(difLight,toon,_ToonEffect);
                fixed3 diffuse=_LightColor0.rgb*albedo*_DiffuseColor.rgb*difLight;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                float rim= 1 - dot(i.worldNormal,viewDir);
                fixed3 rimColor=_RimColor*pow(rim,1/_RimPower);
                
                
                return float4( ambient + diffuse + rimColor,1);
            }
            ENDCG
        }
        
        
    }
}
