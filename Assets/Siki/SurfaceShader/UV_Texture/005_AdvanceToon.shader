Shader "Custom/005_AdvanceToon"
{
    Properties
    {
    	_Color ("Color", Color) = (1, 1, 1, 1)
    	_MainTex ("Main Texture", 2D) = "white" { }
    	_RampThreshold("RampThreshold",float)=1
    	_RampSmooth("RampSmooth",float)=1
    	_SColor("Shadow Color",Color)=(0, 0, 0, 1)
    	_HColor("Hightlight Color",Color)=(1,1,1,1)
    	_Shininess("Shiniess",float)=1
    	_SpecSmooth("SpecSmooth",float)=1
    	_RimThreshold("Rim Threshold",float)=1
    	_RimSmooth("Rim Smooth",float)=1
    	_RimColor("Rim Color",Color)=(1,1,1,1)
    }

    SubShader
    {
    	Tags { "RenderType" = "Opaque" }
            
    	CGPROGRAM
            
    	#pragma surface surf Toon addshadow fullforwardshadows exclude_path:deferred exclude_path:prepass
    	#pragma target 3.0
            
    	fixed4 _Color;
    	sampler2D _MainTex;
    	float _RampThreshold;
        float _RampSmooth;
        fixed4 _SColor;
    	fixed4 _HColor;
    	float _Shininess;
    	float _SpecSmooth;
        float _RimThreshold;
    	float _RimSmooth;
    	fixed4 _RimColor;
    	
    	
    	struct Input
    	{
    		float2 uv_MainTex;
    		float3 viewDir;
    	};
    
    	inline fixed4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
    	{
    		half3 halfDir = normalize(lightDir + viewDir);
    		half3 normalDir = normalize(s.Normal);
    		float ndl = max(0, dot(normalDir, lightDir));
    		fixed3 ramp = smoothstep(_RampThreshold - _RampSmooth * 0.5, _RampThreshold + _RampSmooth * 0.5, ndl);
            ramp *= atten;
    		_SColor = lerp(_HColor, _SColor, _SColor.a);
    		float3 rampColor = lerp(_SColor.rgb, _HColor.rgb, ramp);
    		fixed3 lightColor = _LightColor0.rgb;
    		float ndh = max(0, dot(normalDir, halfDir));
    		float spec = pow(ndh, s.Specular * 128.0) * s.Gloss;
	        spec *= atten;
	        spec = smoothstep(0.5 - _SpecSmooth * 0.5, 0.5 + _SpecSmooth * 0.5, spec);
            fixed3 specular = _SpecColor.rgb * lightColor * spec;

    		float ndv = max(0, dot(normalDir, viewDir));
    		float rim = (1.0 - ndv) * ndl;
	        rim *= atten;
	        rim = smoothstep(_RimThreshold - _RimSmooth * 0.5, _RimThreshold + _RimSmooth * 0.5, rim);
    		fixed3 rimColor = _RimColor.rgb * lightColor * _RimColor.a * rim;
    		fixed4 color;
    		fixed3 diffuse = s.Albedo * lightColor * rampColor;
                
    		color.rgb = diffuse + specular+rimColor;
    		color.a = s.Alpha;
    		return color;
    	}
            
    	void surf(Input IN, inout SurfaceOutput o)
    	{
    		fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
    		o.Albedo = mainTex.rgb * _Color.rgb;
            o.Specular = _Shininess;
	        o.Gloss = mainTex.a;
    		o.Alpha = mainTex.a * _Color.a;
    	}
    
    	ENDCG
    }

    FallBack "Diffuse"
}
