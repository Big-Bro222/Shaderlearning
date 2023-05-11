using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MultiLitsContainer : MonoBehaviour
{
    [SerializeField] private Transform[] pointLits;

    private Light[] _pointLightList;

    private MultiLitsTag[] _lightTagList;
    // Start is called before the first frame update
    void Awake()
    {
        _pointLightList = new Light[pointLits.Length];
        _lightTagList = new MultiLitsTag[pointLits.Length];
        for (int i = 0; i < pointLits.Length; i++)
        {
            _pointLightList[i] = pointLits[i].GetComponent<Light>();
            _lightTagList[i]=pointLits[i].GetComponent<MultiLitsTag>();
        }
    }

    // Update is called once per frame
    void Update()
    {
        Vector4[] litPosList = new Vector4[10];
        Vector4[] litColList = new Vector4[10];

        for (int i = 0; i < pointLits.Length; i++)
        {
            litPosList[i] = new Vector4(pointLits[i].position.x,pointLits[i].position.y,pointLits[i].position.z,_lightTagList[i].shakeStrength);
            litColList[i] = new Vector4(_pointLightList[i].color.r,_pointLightList[i].color.g,_pointLightList[i].color.b,_pointLightList[i].range);
        }
        Shader.SetGlobalFloat("_LitCount",pointLits.Length);
        Shader.SetGlobalVectorArray("_LitPosList",litPosList);
        Shader.SetGlobalVectorArray("_LitColList",litColList);
    }
}

