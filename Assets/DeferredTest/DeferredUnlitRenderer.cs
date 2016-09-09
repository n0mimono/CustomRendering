using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter))]
public class DeferredUnlitRenderer : MonoBehaviour {
  public Material mat;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.BeforeGBuffer;

  private void CleanUp() {
    foreach (var buf in buffers.Where(b => b.Key != null)) {
      buf.Key.RemoveCommandBuffer (TargetCameraEvent, buf.Value);
    }
    buffers.Clear ();
  }

  void OnEnable() {
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

    if (mat == null) return;

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

    buf.DrawMesh (
      GetComponent<MeshFilter> ().sharedMesh,
      transform.localToWorldMatrix,
      mat
    );

  }

}
