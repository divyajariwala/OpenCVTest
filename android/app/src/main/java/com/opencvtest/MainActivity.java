package com.opencvtest;

import com.facebook.react.ReactActivity;

import android.util.Log;
import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import android.os.StrictMode;

public class MainActivity extends ReactActivity {

	/**
	* Returns the name of the main component registered from JavaScript. This is used to schedule
	* rendering of the component.
	*/
	@Override
	protected String getMainComponentName() {
		return "opencvtest";
	}

    private static final String TAG = "MainActivity";
    private BaseLoaderCallback _baseLoaderCallback = new BaseLoaderCallback(this) {
        @Override
        public void onManagerConnected(int status) {
            switch (status){
                case LoaderCallbackInterface.SUCCESS:
                    Log.i(TAG, "OpenCV loaded successfully");
                    System.loadLibrary ("native-lib");
                    break;
                default:
                    super.onManagerConnected(status);
                    break;
            }
        }
    };

    @Override // RNSKOpenCVManager
    protected  void onResume () {
        super.onResume ();
        Log.i (TAG, "resume");
        if (!OpenCVLoader.initDebug ()) {
            Log.d (TAG, "Internal OpenCV library not found!");
            OpenCVLoader.initAsync (OpenCVLoader.OPENCV_VERSION_3_2_0, this, _baseLoaderCallback);
        }
        else {
            Log.d (TAG, "OpenCV library found inside package.");
            _baseLoaderCallback.onManagerConnected (LoaderCallbackInterface.SUCCESS);
        }
    }

}
