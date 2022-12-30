Shader "Unlit/MostSimpleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            #include "UnityCG.cginc"

            //POSITION  SV_POSITION 是语义信息，定义输入和输出
            float4 vert (float4 v:POSITION):SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }
            
            //输出到render target上
            fixed4 frag () : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
