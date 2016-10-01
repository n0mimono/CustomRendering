using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class MelterRenderManager : DecalObjectRenderManager {

  public override void Reconstruct(CommandBuffer buf) {

    RenderTargetIdentifier[] mrt = {
      BuiltinRenderTextureType.GBuffer0, // albedo
      BuiltinRenderTextureType.GBuffer1, // specular
      BuiltinRenderTextureType.GBuffer2, // normal
      BuiltinRenderTextureType.GBuffer3  // emission
    };

    buf.SetRenderTarget (mrt, BuiltinRenderTextureType.CameraTarget);
    foreach (var obj in objects.Where(o => o.IsActive)) {
      buf.DrawMesh(obj);
    }

  }

}
