Shader "Custom/006_SurfaceFlow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _Normal("Normal texture",2D)="Bump"{}
        _Mask("Mask",2D)="white"{}
        _Specular("Specular",2D)="white"{}
        _Fire("Fire",2D)="white"{}
        _FireIntensity("Fire Intensity",Range(0,2))=1
        _FireSpeed("Fire Speed",Vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        LOD 200
        Cull Off
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Smoothness;
        fixed4 _Color;
        sampler2D _Normal;
        sampler2D _Mask;
        sampler2D _Specular;
        sampler2D _Fire;
        float _FireIntensity;
        float2 _FireSpeed;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Normal=UnpackNormal(tex2D(_Normal,IN.uv_MainTex));
            float2 uv =IN.uv_MainTex+_Time.x*_FireSpeed;
            o.Emission=((tex2D(_Mask,IN.uv_MainTex)*tex2D(_Fire,uv))*(_FireIntensity*(_SinTime.w+3))).rgb;
            o.Smoothness = _Smoothness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
