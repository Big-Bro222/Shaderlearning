Shader "Custom/SikiWater"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _WaterShallowColor("Shallow Color", Color)=(1,1,1,1)
        _WaterDeepColor("Deep Color", Color)=(0,0,0,1)
        _TransAmount("TransAmount",Range(0,100))=0.5
        _DepthRange("Depth Range",float)=1
        _NormalTex("Normal Texture",2D)="bump"{}
        _WaterSpeed("Water Speed",float)=5
        _Refract("Refract",float)=0.5

        _Specular("Specular",float)=5
        _Gloss("Gloss",float)=5
        _SpecularColor("Specular Color", Color)=(1,1,1,1)
        _WaveTex("Wave Tex",2D)="white"{}
        _NoiseTex("Noise Tex",2D)="white"{}
        _WaveSpeed("WaveSpeed",float) = 1
        _WaveRange("WaveRange",float) = 0.5
        _WaveRangeA("WaveRangeA",float) = 1
        _WaveDelta("Wave Delta",float) = 1
        
        _Distortion("Distortion",float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" "Queue"="Transparent"
        }
        LOD 200
        GrabPass
        {
            "_GrabPassTexture"
        }


        Zwrite off
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterLight vertex:vert alpha noshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D_float _CameraDepthTexture;
        sampler2D _NormalTex;
        sampler2D _WaveTex;
        sampler2D _NoiseTex;
        sampler2D _GrabPassTexture;
        float4 _GrabPassTexture_TexelSize;

        struct Input
        {
            float2 uv_MainTex;
            float4 proj;
            float2 uv_NormalTex;
            float2 uv_WaveTex;
            float2 uv_NoiseTex;
        };

        fixed4 _Color;

        fixed4 _WaterShallowColor;
        fixed4 _WaterDeepColor;
        half _TransAmount;
        half _DepthRange;
        half _WaterSpeed;
        half _Refract;
        float _WaveSpeed;
        float _WaveRange;
        float _WaveRangeA;
        float _WaveDelta;
        float _Distortion;

        half _Specular;
        half _Gloss;
        fixed4 _SpecularColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        fixed4 LightingWaterLight(SurfaceOutput s,fixed3 viewDir,fixed3 lightDir,fixed atten)
        {
            half3 halfDir = normalize(viewDir + lightDir);
            float diffuseFactor = max(0, dot(normalize(lightDir), s.Normal));
            float nh = max(0, dot(halfDir, s.Normal));
            float spec = pow(nh, s.Specular * 128) * s.Gloss;
            fixed4 c;
            c.rgb = (s.Albedo * _LightColor0.rgb * diffuseFactor + spec * _SpecularColor * _LightColor0) * atten;
            c.a = s.Alpha + spec * _SpecularColor.a;
            return c;
        }


        void vert(inout appdata_full v, out Input i)
        {
            UNITY_INITIALIZE_OUTPUT(Input, i);
            i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
            COMPUTE_EYEDEPTH(i.proj.z);
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            //SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(IN.proj));
            half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, IN.proj).r);
            half deltaDepth = depth - IN.proj.z;
            // Albedo comes from a texture tinted by color
            fixed4 c = lerp(_WaterShallowColor, _WaterDeepColor, min(_DepthRange, deltaDepth) / _DepthRange);
            
            o.Albedo = c.rgb;

            //normal
            float4 bumpOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_WaterSpeed * _Time.x, 0));
            float4 bumpOffset2 = tex2D(
                _NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + float2(_WaterSpeed * _Time.x, 0));
            float4 offsetColor = (bumpOffset1 + bumpOffset2) / 2;
            float2 offset = UnpackNormal(offsetColor).xy * _Refract;
            float4 bumpColor1 = tex2D(_NormalTex, IN.uv_NormalTex + offset + float2(_WaterSpeed * _Time.x, 0));
            float4 bumpColor2 = tex2D(
                _NormalTex,
                float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + offset + float2(_WaterSpeed * _Time.x, 0));
            float3 normal = UnpackNormal((bumpColor1 + bumpColor2) / 2).xyz;
            o.Normal = normal;


            //wave
			half waveB = 1 - min(_WaveRangeA, deltaDepth) / _WaveRangeA;
			fixed4 noiserColor = tex2D(_NoiseTex, IN.uv_NoiseTex);
			fixed4 waveColor = tex2D(_WaveTex, float2(waveB + _WaveRange * sin(_Time.x * _WaveSpeed + noiserColor.r), 1) + offset);
			waveColor.rgb *= (1 - (sin(_Time.x * _WaveSpeed + noiserColor.r) + 1) / 2) * noiserColor.r;
			fixed4 waveColor2 = tex2D(_WaveTex, float2(waveB + _WaveRange * sin(_Time.x * _WaveSpeed + _WaveDelta + noiserColor.r), 1) + offset);
			waveColor2.rgb *= (1 - (sin(_Time.x * _WaveSpeed + _WaveDelta + noiserColor.r) + 1) / 2) * noiserColor.r;


            //GrabPass
            float2 grabPassOffset=normal.xy*_Distortion*_GrabPassTexture_TexelSize.xy;
            IN.proj.xy=grabPassOffset*IN.proj.z+IN.proj.xy;
            fixed3 refrCol=tex2D(_GrabPassTexture,IN.proj.xy/IN.proj.w).rgb;

            o.Albedo = (c + (waveColor.rgb + waveColor2.rgb) * waveB)*refrCol;
            // Metallic and smoothness come from slider variables
            o.Alpha = min(_TransAmount, deltaDepth) / _TransAmount;
            o.Gloss = _Gloss;
            o.Specular = _Specular;
        }
        ENDCG
    }
    FallBack "Diffuse"
}