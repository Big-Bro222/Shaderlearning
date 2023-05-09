using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

[ExecuteInEditMode]
public class Post : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI effectName;
    [SerializeField] private List<Material> postEffectMaterials;
    private int _effectIndex = 0;
    private Material _effectMaterial;

    private void Awake()
    {
        InvokeRepeating("SwitchEffect",0,2);
    }

    private void SwitchEffect()
    {
        _effectMaterial = postEffectMaterials[_effectIndex];
        effectName.text = _effectMaterial.name;
        _effectIndex=_effectIndex<postEffectMaterials.Count-1?_effectIndex+1:0;
    }
    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (_effectMaterial != null)
            Graphics.Blit(src, dst, _effectMaterial);
    }
}