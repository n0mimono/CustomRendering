using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class BufferSmoother : MonoBehaviour {
  public Material mat;
  public BuiltinRenderTextureType type;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.AfterGBuffer;

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

  public void Reconstruct(CommandBuffer buf) {
    int id = Shader.PropertyToID("_Buffer");
    buf.GetTemporaryRT(id, -1, -1);
    buf.Blit(type, id);

    buf.Blit(id, type, mat);

    buf.ReleaseTemporaryRT (id);
  }

}
