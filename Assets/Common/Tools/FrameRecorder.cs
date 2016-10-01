using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
public class FrameRecorder : MonoBehaviour {

  private const int    FrameRate = 30;
  private const string SaveDir = "ScreenShots";
  private const string Prefix  = "frame_";

  private int   width  = 1920;
  private int   height = 1080;
  private float wait   = 0.5f;

  private RenderTexture rt;
  private Texture2D     tex;
  private Camera        cam;

  IEnumerator Start() {
    Time.captureFramerate = FrameRate;
    System.IO.Directory.CreateDirectory(SaveDir);
    yield return null;

    cam  = GetComponent<Camera> ();
    rt   = new RenderTexture (width, height, 24);
    tex  = new Texture2D (width, height, TextureFormat.RGB24, false);
    yield return new WaitForSeconds (wait);

    Debug.Log ("Start Record");
    for (int t = 0;; t++) {
      yield return new WaitForEndOfFrame ();

      Capture (t);
    }
  }

  private void Capture(int count) {
    RenderTexture target = cam.targetTexture;

    cam.targetTexture = rt;
    cam.Render ();
    RenderTexture.active = rt;
    tex.ReadPixels (new Rect (0, 0, width, height), 0, 0);
    tex.Apply ();

    cam.targetTexture = target;
    RenderTexture.active = null;

    byte[] bytes = tex.EncodeToJPG();

    string fileName = string.Format("{0}{1:D04}.jpg", Prefix, count);
    var path = System.IO.Path.Combine(SaveDir, fileName);

    System.IO.File.WriteAllBytes(path, bytes);
  }

}
