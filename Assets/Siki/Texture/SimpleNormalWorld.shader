Shader "Custom/Siki/SimpleNormalWorld"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",float)=5
        _MainTex("MainTex",2D)="white"
        _BumpMap("Normal Map",2D)="bump"
        _BumpScale("Bump Scale",float)=1
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
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            struct v2f{
                float4 vertex:SV_POSITION;
                float4 uv:TEXCOORD0;
                float4 TtoW0:TEXCOORD1;
                float4 TtoW1:TEXCOORD2;
                float4 TtoW2:TEXCOORD3;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex=UnityObjectToClipPos(v.vertex);
                //o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw= TRANSFORM_TEX(v.texcoord,_BumpMap);


                float3 worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal=UnityObjectToWorldNormal(v.normal);
                float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldbinormal=cross(worldNormal,worldTangent)*v.tangent.w;

                //按列摆放得到切线转世界空间的变换矩阵
                o.TtoW0=float4(worldTangent.x,worldbinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1=float4(worldTangent.y,worldbinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2=float4(worldTangent.z,worldbinormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos=float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                fixed3 worldViewDir=normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(worldPos));
                

                fixed4 packed_normal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal=UnpackNormal(packed_normal);
                tangentNormal.xy*=_BumpScale;

                fixed3 worldNormal=normalize(float3(dot(i.TtoW0.xyz,tangentNormal),dot(i.TtoW1.xyz,tangentNormal),dot(i.TtoW0.xyz,tangentNormal)));
                
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 albedo = tex2D(_MainTex,i.uv.xy);
                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*albedo.rgb*(dot(worldLightDir,worldNormal)*0.5+0.5);;
                //fixed3 reflectDir=normalize(reflect(-worldLight,worldNormal));
                fixed3 halfDir=normalize(worldLightDir+worldViewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                fixed3 color=diffuse+ambient+specular;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
