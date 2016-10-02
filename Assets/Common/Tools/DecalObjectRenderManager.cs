using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class DecalObjectRenderManager : MonoBehaviour {
  
  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.BeforeLighting;

  protected HashSet<DecalObject> objects = new HashSet<DecalObject>();

  public void Add(DecalObject obj) {
    Remove (obj);
    objects.Add (obj);
  }

  public void Remove(DecalObject obj) {
    objects.Remove (obj);
  }

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
