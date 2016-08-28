// http://docs.unity3d.com/ja/current/Manual/GraphicsCommandBuffers.html

using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

[ExecuteInEditMode]
public class BlurRefraction : MonoBehaviour {
  public Material mat;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();
  private static readonly CameraEvent TargetCameraEvent = CameraEvent.AfterSkybox;

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

  public void OnWillRenderObject() {
    
    // clean up if object is inactive.
    if (!gameObject.activeInHierarchy || !enabled) {
      CleanUp ();
      return;
    }

    // noop if we don't have any cameras.
    Camera current = Camera.current;
    if (current == null) return;

    // noop if we have applied command to current camera.
    if (buffers.ContainsKey(current)) return;

    // create and apply command to current camera.
    CommandBuffer buf = CreateBuffer ();
    current.AddCommandBuffer (TargetCameraEvent, buf);
    buffers [current] = buf;
  }

  private CommandBuffer CreateBuffer() {
    CommandBuffer buf = new CommandBuffer ();
    buf.name = GetType ().Name;

    // crate and copy scrren texture
    int screenCopyId = Shader.PropertyToID("_ScreenCopyTexture");
    buf.GetTemporaryRT(screenCopyId, -1, -1, 0, FilterMode.Bilinear);
    buf.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyId);

    // create tmp textures
    int blurId1 = Shader.PropertyToID ("_Temp1");
    int blurId2 = Shader.PropertyToID ("_Temp2");
    buf.GetTemporaryRT(blurId1, -2, -2, 0, FilterMode.Bilinear);
    buf.GetTemporaryRT(blurId2, -2, -2, 0, FilterMode.Bilinear);

    // copy screen to tmp
    buf.Blit (screenCopyId, blurId1);
    buf.ReleaseTemporaryRT (screenCopyId);

    // blur effect
    buf.SetGlobalVector("offsets", new Vector4(2.0f/Screen.width, 0, 0, 0));
    buf.Blit(blurId1, blurId2, mat);
    buf.SetGlobalVector("offsets", new Vector4(0, 2.0f/Screen.height, 0, 0));
    buf.Blit(blurId2, blurId1, mat);
    buf.SetGlobalVector("offsets", new Vector4(4.0f/Screen.width, 0, 0, 0));
    buf.Blit(blurId1, blurId2, mat);
    buf.SetGlobalVector("offsets", new Vector4(0, 4.0f/Screen.height, 0, 0));
    buf.Blit(blurId2, blurId1, mat);

    // set blur tex to shader
    buf.SetGlobalTexture ("_GrabBlurTexture", blurId1);

    return buf;
  }


}
