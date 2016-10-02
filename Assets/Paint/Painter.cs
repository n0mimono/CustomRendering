using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class Painter : DecalObject {

  public override DecalObjectRenderManager GetRenderManager() {
    return PainterRenderManager.Instance;
  }

}
