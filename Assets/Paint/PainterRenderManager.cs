﻿using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class PainterRenderManager : DecalObjectRenderManager {

  public static PainterRenderManager Instance { private set; get; }

  void Start() {
    Instance = this;
  }

  public override void Reconstruct(CommandBuffer buf) {
    var normalsID = Shader.PropertyToID("_NormalsCopy");
    buf.GetTemporaryRT(normalsID, -1, -1);
    buf.Blit(BuiltinRenderTextureType.GBuffer2, normalsID);
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

    buf.ReleaseTemporaryRT (normalsID);
  }

}
