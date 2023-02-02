using System;
using System.Collections;
using System.Collections.Generic;
//using System.Linq;

using UnityEditor;
using UnityEngine;
//using UnityEngine.UI;
//using Uhity.Entities;

using URD = UnityEngine.Random;

namespace SDTK.Editor {
	public static class SDTKEditorFunction {
		
		[MenuItem("SDTK/Common/Capture Screen Shot")]
		public static void CaptureScreenShot() {
			var lastPath = EditorPrefs.GetString("SDTK_CaptureScreenShot", Application.dataPath);
			var path = EditorUtility.SaveFilePanel("Screen Shot", lastPath, "New Screen Shot", "png");
			EditorPrefs.SetString("SDTK_CaptureScreenShot", path);
			ScreenCapture.CaptureScreenshot(path);
			AssetDatabase.Refresh();
		}
		
		[MenuItem("SDTK/Common/Capture Screen Shot Double Size")]
		public static void CaptureScreenShotDoubleSize() {
			var lastPath = EditorPrefs.GetString("SDTK_CaptureScreenShot", Application.dataPath);
			var path = EditorUtility.SaveFilePanel("Screen Shot", lastPath, "New Screen Shot", "png");
			EditorPrefs.SetString("SDTK_CaptureScreenShot", path);
			ScreenCapture.CaptureScreenshot(path, 2);
			AssetDatabase.Refresh();
		}
		
	}
}
