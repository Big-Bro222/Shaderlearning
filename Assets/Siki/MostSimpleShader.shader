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

            //POSITION  SV_POSITION ��������Ϣ��������������
            float4 vert (float4 v:POSITION):SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }
            
            //�����render target��
            fixed4 frag () : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
