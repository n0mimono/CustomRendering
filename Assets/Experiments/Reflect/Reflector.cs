using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class Reflector : DecalObject {

  public override DecalObjectRenderManager GetRenderManager() {
    return ReflectorRenderManager.Instance;
  }

}
