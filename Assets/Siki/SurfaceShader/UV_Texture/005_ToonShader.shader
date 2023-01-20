Shader "Custom/005_ToonShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 0.5
        _Specular ("Metallic", Range(0,1)) = 0.0
        _RimColor("Rim Color",Color)=(1,1,1,1)
        _RimPower("Rim Power",float)=1
        _Steps("Steps",Range(1,30))=2
        _ToonEffect("Toon Effect",Range(0,1))=1
        _Outline("Outline",Range(0,1))=1
        _OutlineColor("Outline Color",Color)=(1,1,1,1)
        _XRayColor("Oculusion Color",Color)=(1,1,1,1)
        _XRayPower("XRay Power",Range(0.0001,3))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
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
            Name "Ourline"
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            float _Outline;
            fixed4 _OutlineColor;
            struct v2f
            {
                float4 vertex:SV_POSITION;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                float3 normal=UnityObjectToWorldNormal(v.normal);
                float2 viewNormal=TransformViewToProjection(normal.xy);
                o.vertex.xy+=viewNormal*_Outline;
                return o;
                
            }

            float4 frag(v2f i):SV_Target
            {
                return _OutlineColor*i.vertex;
            }
            
            ENDCG
            
            }
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Toon fullforwardshadows nolightmap 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        half _Gloss;
        half _Specular;
        fixed4 _Color;
        fixed4 _RimColor;
        float _RimPower;
        float _Steps;
        float _ToonEffect;

        half4 LightingToon(SurfaceOutput s,half3 lightDir,half3 viewDir,half atten)
        {
            float difLight=dot(lightDir,s.Normal)*0.5+0.5;
            difLight=smoothstep(0,1,difLight);
            float toon=floor(difLight*_Steps)/_Steps;
            difLight=lerp(difLight,toon,_ToonEffect);
            fixed3 diffuse=_LightColor0*s.Albedo*difLight;
            return half4(diffuse,1);
        }
        
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Specular = _Specular;
            o.Gloss = _Gloss;
            o.Alpha = c.a;
            half rim=1.0-saturate(dot(normalize(IN.viewDir),o.Normal));
            o.Emission=_RimColor.rgb*pow(rim,_RimPower);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
