using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class GBufferRenderManager : MonoBehaviour {

  private Dictionary<Renderer, Material[]> r2mats = new Dictionary<Renderer, Material[]>();

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.AfterGBuffer;

  private void CleanUp() {
    foreach (var buf in buffers.Where(b => b.Key != null)) {
      buf.Key.RemoveCommandBuffer (TargetCameraEvent, buf.Value);
    }
    buffers.Clear ();
  }

  void OnEnable() {
    foreach (Renderer rend in GetComponentsInChildren<Renderer>()) {
      r2mats [rend] = rend.sharedMaterials;
      rend.sharedMaterials = new Material[0];
    }

    CleanUp ();
  }

  void OnDisable() {
    CleanUp ();
  }

  void LateUpdate() {
    if (!gameObject.activeInHierarchy || !enabled) {
      CleanUp ();
      return;
    }

    Camera current = Camera.current;
    if (current == null) return;

    if (buffers.ContainsKey(current)) return;

    CommandBuffer buf = null;
    if (buffers.ContainsKey(current)) {
      buf = buffers[current];
      buf.Clear();
    } else {
      buf = new CommandBuffer();
      buf.name = GetType ().Name;
      buffers[current] = buf;
      current.AddCommandBuffer(TargetCameraEvent, buf);
    }
    Reconstruct (buf);
  }

  public void Reconstruct(CommandBuffer buf) {

    RenderTargetIdentifier[] mrt = {
      BuiltinRenderTextureType.GBuffer0, // albedo
      BuiltinRenderTextureType.GBuffer1, // specular
      BuiltinRenderTextureType.GBuffer2, // normal
      BuiltinRenderTextureType.GBuffer3, // emission
    };
    buf.SetRenderTarget (mrt, BuiltinRenderTextureType.CameraTarget);

    foreach (Renderer rend in GetComponentsInChildren<Renderer>()) {
      Material[] mats = r2mats [rend];
      for (int i = 0; i < mats.Length; i++) {
        buf.DrawRenderer (rend, mats [i], i);
      }
    }

  }

}
