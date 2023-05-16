Shader "Toon/ToonShaderSurfaceBigBro"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Outline("Outline Width",Range(0,1))=1
        _OutlineColor("Outline Color",Color)=(0,0,0,1)
        _Steps("Steps",Range(1,30)) = 1
        _ToonEffect("ToonEffect", Range(0,1)) = 0.5
        _DiffuseColor("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular Color",Color)=(1,1,1,1)
        _SpecularScale("Specular Scale",Range(0.0001,3))=1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 200
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

            v2f vert(appdata_base v)
            {
                v2f o;
                //裁剪空间法线外拓
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                float2 viewNormal = TransformViewToProjection(normal.xy);
                o.vertex.xy += viewNormal * _Outline;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        CGPROGRAM
        #pragma surface surf Toon addshadow

        float4 _DiffuseColor;
        fixed4 _Color;
        float _Steps;
        float _ToonEffect;
        float _SpecularScale;
        fixed4 _Specular;

        half4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
        {

            float3 shakeOffset = float3(0, 0, 0);
            shakeOffset.x = sin(_Time.z * 15);
            shakeOffset.y = sin(_Time.z * 13 + 5);
            shakeOffset.z = sin(_Time.z * 12 + 7);

            #ifdef POINT
            lightDir += shakeOffset * 0.1f;
            #endif
            
            //Diffuse light steps
            float difLight = dot(lightDir, s.Normal) * 0.5 + 0.5;
            difLight = smoothstep(0, 1, difLight);
            float toon = floor(difLight * _Steps) / _Steps;
            difLight = lerp(difLight, toon, _ToonEffect);
            fixed3 diff = _LightColor0.rgb * _DiffuseColor.rgb * difLight;

            fixed3 halfDir = normalize(lightDir + viewDir);
            float spec = dot(s.Normal, halfDir);
            fixed w = fwidth(spec) * 2.0;
            fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(
                0.0001, _SpecularScale);

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Color;

            // //custom shadow
            // #ifdef USING_DIRECTIONAL_LIGHT
            // float attenuationChange = fwidth(atten) * 0.5;
            // float shadow = smoothstep(0.5 - attenuationChange, 0.5 + attenuationChange, atten);
            // #else
            // float attenuationChange = fwidth(atten);
            // float shadow = smoothstep(0, attenuationChange, atten);
            // #endif
            
            half4 c;
            c.rgb = (ambient + diff + specular) * atten * s.Albedo;
            c.a = s.Alpha;
            return c;
        }

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;

        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
        }
        ENDCG
    }
    FallBack "Diffuse"
}