using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public partial class DecalRenderer : MonoBehaviour {
  public Mesh mesh;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.BeforeLighting;

  public void OnWillRenderObject() {

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
      buf.name = "Deferred decals";
      buffers[current] = buf;
      current.AddCommandBuffer(CameraEvent.BeforeLighting, buf);
    }

    var normalsID = Shader.PropertyToID("_NormalsCopy");
    buf.GetTemporaryRT(normalsID, -1, -1);
    buf.Blit(BuiltinRenderTextureType.GBuffer2, normalsID);

    RenderTargetIdentifier[] mrt = {BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.GBuffer2};
    buf.SetRenderTarget (mrt, BuiltinRenderTextureType.CameraTarget);
    foreach (var decal in decals) {
      buf.DrawMesh(mesh, decal.transform.localToWorldMatrix, decal.mat);
    }

    buf.ReleaseTemporaryRT(normalsID);
  }

}

public partial class DecalRenderer {

  private void CleanUp() {
    foreach (var buf in buffers.Where(b => b.Key != null)) {
      buf.Key.RemoveCommandBuffer (TargetCameraEvent, buf.Value);
    }
  }

  void OnEnable() {
    CleanUp ();
  }

  void OnDisable() {
    CleanUp ();
  }

}

public partial class DecalRenderer {
  private static HashSet<Decal> decals = new HashSet<Decal>();

  public static void Add(Decal d) {
    Remove (d);
    decals.Add (d);
  }

  public static void Remove(Decal d) {
    decals.Remove (d);
  }

}
