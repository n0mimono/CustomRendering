using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

[ExecuteInEditMode]
public class Book : MonoBehaviour {

	[Header("Book")]
	public List<Texture> textures;
	public Shader        shader;
	public Renderer      pageRenderer;

	[Header("Status")]
	public float curPageNumber;

	[System.Serializable]
	public class TargetPage {
		public Texture baseTex;
		public Texture nextTex;
		public Texture maskTex;
		public Texture frameTex;
		public float   pageAngle;

		public void SetTo(Material material) {
			material.SetFloat ("_Angle", pageAngle);
			material.SetTexture ("_MainTex", baseTex);
			material.SetTexture ("_BackTex", nextTex);
			material.SetTexture ("_MaskTex", maskTex);
			material.SetTexture ("_FrameTex", frameTex);
		}

	}
	public TargetPage curTarget;
	private Material   material;

	void Update () {
		if (!textures.Any ()) return;

		if (material == null) {
			InitMateril ();
		}

		SetCurTargetPage ();
		SetMaterialProperties ();
	}

	private void InitMateril() {
		material = new Material (shader);
		material.hideFlags = HideFlags.HideAndDontSave;

		pageRenderer.sharedMaterial = material;
	}

	private void SetCurTargetPage() {
		if (curTarget == null) curTarget = new TargetPage();
		int texNums = textures.Count;

		float floor = Mathf.Floor (curPageNumber);
		float frac = curPageNumber - floor;

		curTarget.pageAngle = frac;

		System.Func<int,int,int> mod = (
			(x, c) => {
				while (x < 0) x+= c;
				return x % c;
			}
		);
		curTarget.baseTex = textures [mod ((int)floor + 0, texNums)];
		curTarget.nextTex = textures [mod ((int)floor + 1, texNums)];
	}

	private void SetMaterialProperties() {
		curTarget.SetTo (material);
	}

}
