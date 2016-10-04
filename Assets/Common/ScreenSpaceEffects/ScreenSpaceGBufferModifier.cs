using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class ScreenSpaceGBufferModifier : MonoBehaviour {
  public Material mat;
  public BuiltinRenderTextureType input;
  public BuiltinRenderTextureType output;
  public CameraEvent TargetCameraEvent = CameraEvent.AfterGBuffer;
  public bool useIvp;
  public bool useDirectBlit;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();

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

  void Update() {
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

  public virtual void Reconstruct(CommandBuffer buf) {
    if (useIvp) {
      Camera    camera = Camera.current;
      Matrix4x4 view   = camera.worldToCameraMatrix;
      Matrix4x4 proj   = GL.GetGPUProjectionMatrix (camera.projectionMatrix, false);
      Matrix4x4 vp     = proj * view;
      Matrix4x4 ivp    = vp.inverse;

      mat.SetMatrix ("_InvViewProj", ivp);
    }

    if (useDirectBlit) {
      buf.Blit (input, output, mat);
    } else {
      int id = Shader.PropertyToID("_Buffer");
      buf.GetTemporaryRT(id, -1, -1);
      buf.Blit(input, id);
      buf.Blit(id, output, mat);

      buf.ReleaseTemporaryRT (id);
    }

  }

}
