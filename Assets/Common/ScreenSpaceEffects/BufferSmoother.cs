using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class BufferSmoother : ScreenSpaceGBufferModifier {
  public BuiltinRenderTextureType type;

  public override void Reconstruct(CommandBuffer buf) {
    int id = Shader.PropertyToID("_Buffer");
    buf.GetTemporaryRT(id, -1, -1);
    buf.Blit(type, id);

    buf.Blit(id, type, mat);

    buf.ReleaseTemporaryRT (id);
  }

}
