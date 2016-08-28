using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class PaintRenderManager : MonoBehaviour {

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.BeforeLighting;

  private HashSet<Painter> paints = new HashSet<Painter>();

  public static PaintRenderManager Instance { private set; get; } 

  void Awake() {
    Instance = this;
  }

  public void Add(Painter p) {
    Remove (p);
    paints.Add (p);
  }

  public void Remove(Painter p) {
    paints.Remove (p);
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
      buf.name = "Painter";
      buffers[current] = buf;
      current.AddCommandBuffer(TargetCameraEvent, buf);
    }
    Reconstruct (buf);

  }

  public void Reconstruct(CommandBuffer buf) {
    var normalsID = Shader.PropertyToID("_NormalsCopy");
    buf.GetTemporaryRT(normalsID, -1, -1);
    buf.Blit(BuiltinRenderTextureType.GBuffer2, normalsID);

    RenderTargetIdentifier[] mrt = {
      BuiltinRenderTextureType.GBuffer0, // albedo
      BuiltinRenderTextureType.GBuffer1, // specular
      BuiltinRenderTextureType.GBuffer2  // normal
    };
    buf.SetRenderTarget (mrt, BuiltinRenderTextureType.CameraTarget);
    foreach (var paint in paints.Where(p => p.IsActive)) {
      buf.DrawMesh(paint);
    }

    buf.ReleaseTemporaryRT (normalsID);
  }

}
