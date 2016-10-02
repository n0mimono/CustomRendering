using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class MelterRenderManager : DecalObjectRenderManager {
  public int passCount;

  public override void Reconstruct(CommandBuffer buf) {
    
    Camera    camera = Camera.current;
    Matrix4x4 view   = camera.worldToCameraMatrix;
    Matrix4x4 proj   = GL.GetGPUProjectionMatrix (camera.projectionMatrix, false);
    Matrix4x4 vp     = proj * view;
    Matrix4x4 ivp    = vp.inverse;
    Shader.SetGlobalMatrix ("_InvViewProj", ivp);

    RenderTargetIdentifier[] mrt = {
      BuiltinRenderTextureType.GBuffer0, // albedo
      BuiltinRenderTextureType.GBuffer1, // specular
      BuiltinRenderTextureType.GBuffer2, // normal
      BuiltinRenderTextureType.GBuffer3  // emission
    };

    buf.SetRenderTarget (mrt, BuiltinRenderTextureType.CameraTarget);
    foreach (var obj in objects.Where(o => o.IsActive)) {
      for (int i = 0; i < passCount; i++) {
        buf.DrawMesh(obj);
      }
    }

  }

}
