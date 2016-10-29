using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class BookWorldManager : MonoBehaviour {
  [Header("Component")]
  public Camera   mainCamera;
  public Book     book;

  [Header("Book")]
  public Texture  separator;
  public string[] sceneNames;
  public int      texSize;

  private Scene[] scenes;
  private int curScene = -1;
  private RenderTexture rt;

  IEnumerator Start() {
    mainCamera.enabled = false;
    rt = new RenderTexture((int)(mainCamera.aspect * texSize), texSize, 24);

    book.textures = new List<Texture> ();

    scenes = new Scene[sceneNames.Length];
    for (int i = 0; i < sceneNames.Length; i++) {
      yield return SceneManager.LoadSceneAsync (sceneNames[i], LoadSceneMode.Additive);
      scenes [i] = SceneManager.GetSceneByName (sceneNames[i]);

      Camera sceneCamera = GameObject
        .FindObjectsOfType<Camera> ()
        .FirstOrDefault (c => c != mainCamera);
      sceneCamera.targetTexture = rt;

      book.textures.Add (separator);
      book.textures.Add (rt);

      SetActiveScene (i, false);
      yield return null;
    }

    mainCamera.enabled = true;

    while (true) {
      CheckActiveScene ();
      yield return null;
    }
  }

  void CheckActiveScene() {
    int nextScene = Mathf.FloorToInt (book.curPageNumber / 2f);

    if (curScene != nextScene) {
      SetActiveScene (curScene, false);
      SetActiveScene (nextScene, true);
    }
    curScene = nextScene;
  }

  private void SetActiveScene(int index, bool isActive) {
    index = (index + scenes.Length) % scenes.Length;

    foreach (GameObject go in scenes [index].GetRootGameObjects ()) {
      go.SetActive (isActive);
    }
    if (isActive) {
      SceneManager.SetActiveScene (scenes [index]);
    }

  }

}
