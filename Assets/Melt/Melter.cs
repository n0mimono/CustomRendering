using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class Melter : DecalObject {
  
  public override DecalObjectRenderManager GetRenderManager() {
    return GameObject.FindObjectOfType<MelterRenderManager>();
  }

}
