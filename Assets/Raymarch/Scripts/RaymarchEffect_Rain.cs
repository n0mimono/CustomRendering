using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class RaymarchEffect_Rain : MonoBehaviour {
  public List<Transform> transforms;

  private Renderer rend;
  private MaterialPropertyBlock prop;

  void Start() {
    rend = GetComponent<Renderer> ();
    prop = new MaterialPropertyBlock ();
  }

  void Update() {

    Vector4[] posArray = transforms
      .Select (t => t.position)
      .Select (p => new Vector4 (p.x, p.y, p.z, 1f))
      .ToArray ();

    prop.SetFloat ("_PosNums", posArray.Length);
    prop.SetVectorArray ("_PosArray", posArray);
    rend.SetPropertyBlock (prop);
  }

}
