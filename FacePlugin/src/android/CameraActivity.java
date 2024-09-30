package com.ttv.facerecog;

import static androidx.camera.core.ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST;

import android.annotation.SuppressLint;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.media.Image;
import android.os.Bundle;
import android.util.Range;
import android.util.Size;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.util.Log;
import java.nio.ByteBuffer;
import java.util.List;
import com.kbyai.facesdk.*;
import android.os.Message;
import android.view.View;
import android.view.ViewGroup;
import android.util.Size;
import android.graphics.Color;
import android.graphics.Matrix;
import java.io.FileOutputStream;
import java.io.ByteArrayOutputStream;
import android.util.Base64;
import java.util.HashMap;
import java.util.Map;
import android.widget.Button;


import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraControl;
import androidx.camera.core.CameraInfo;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.FocusMeteringAction;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.MeteringPoint;
import androidx.camera.core.MeteringPointFactory;
import androidx.camera.core.Preview;
import androidx.camera.core.SurfaceOrientedMeteringPointFactory;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import android.os.Handler;
import com.ttv.face.plugin.FacePlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


public class CameraActivity extends AppCompatActivity {

    private static final String TAG = CameraActivity.class.getSimpleName();
    private final PermissionsDelegate permissionsDelegate = new PermissionsDelegate(this);
    private boolean hasPermission;

    private final int MSG_UPDATE_FACE = 0;
    private final int MSG_CLEAR_FACE = 1;

    private final float THRESHOLD_REGISTER = 75.0f;
    private final float THRESHOLD_VERIFY = 75.0f;
    private final float THRESHOLD_LIVENESS = 0.8f;
    
    /**
     * Blocking camera operations are performed using this executor
     */
    private ExecutorService m_cameraExecutorService;
    private PreviewView     m_viewFinder;
    private FaceRectView    m_rectanglesView;
    private FaceRectTransformer m_faceRectTransformer;
    private ImageView       m_switchCamera;
    private Button          m_registerBtn;

    private int m_lensFacing = CameraSelector.LENS_FACING_FRONT;

    private Preview       m_preview        = null;
    private ImageAnalysis m_imageAnalyzer  = null;
    private Camera        m_camera         = null;
    private CameraSelector        m_cameraSelector = null;

    private ProcessCameraProvider m_cameraProvider = null;
    private MainMessageHandler mMainHandler = null;

    private Context m_context;
    private int m_mode;
    private int m_register;
    private int m_seekFrame;

    class MainMessageHandler extends Handler {

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);

            switch (msg.what) {
                case MSG_UPDATE_FACE: {
                    // List<FaceResult> faceResults = (List<FaceResult>)msg.obj;
                    // if(m_faceRectTransformer == null)
                    // {
                    //     int displayOrientation = 0;
                    //     Size frameSize = new Size(720, 1280);
                    //     ViewGroup.LayoutParams layoutParams = adjustPreviewViewSize(m_viewFinder, m_rectanglesView);

                    //             m_faceRectTransformer = new FaceRectTransformer(
                    //             frameSize.getWidth(), frameSize.getHeight(),
                    //             m_viewFinder.getLayoutParams().width, m_viewFinder.getLayoutParams().height,
                    //             displayOrientation, m_lensFacing == CameraSelector.LENS_FACING_FRONT ? 0 : 1, false,
                    //             true,
                    //             false);
                    // }

                    // List<FaceRectView.DrawInfo> drawInfoList = new ArrayList<>();
                    // for(int i = 0; i < faceResults.size(); i ++) {
                    //     Rect rect = m_faceRectTransformer.adjustRect(new Rect(faceResults.get(i).left, faceResults.get(i).top, faceResults.get(i).right, faceResults.get(i).bottom));

                    //     FaceRectView.DrawInfo drawInfo;
                    //     if(faceResults.get(i).livenessScore > 0.5)
                    //         drawInfo = new FaceRectView.DrawInfo(rect, 0, 0, 1, Color.GREEN, "", faceResults.get(i).livenessScore, 0, 0, 0, -1);
                    //     else if(faceResults.get(i).livenessScore < 0)
                    //         drawInfo = new FaceRectView.DrawInfo(rect, 0, 0, -1, Color.YELLOW, "", faceResults.get(i).livenessScore, 0, 0, 0, -1);
                    //     else
                    //         drawInfo = new FaceRectView.DrawInfo(rect, 0, 0, 0, Color.RED, "", faceResults.get(i).livenessScore, 0, 0, 0, -1);
                    //     drawInfo.setMaskInfo(faceResults.get(i).mask);
                    //     drawInfoList.add(drawInfo);
                    // }

                    // m_rectanglesView.clearFaceInfo();
                    // m_rectanglesView.addFaceInfo(drawInfoList);

                    break;
                }
                case MSG_CLEAR_FACE: {
                    m_rectanglesView.clearFaceInfo();

                    break;
                }
            }
        }
    }

    private ViewGroup.LayoutParams adjustPreviewViewSize(View previewView, FaceRectView faceRectView) {
        ViewGroup.LayoutParams layoutParams = previewView.getLayoutParams();
        int measuredWidth = previewView.getMeasuredWidth();
        int measuredHeight = previewView.getMeasuredHeight();

        layoutParams.width = measuredWidth;
        layoutParams.height = measuredHeight;
        previewView.setLayoutParams(layoutParams);

        layoutParams = faceRectView.getLayoutParams();
        layoutParams.width = measuredWidth;
        layoutParams.height = measuredHeight;
        faceRectView.setLayoutParams(layoutParams);        
        return layoutParams;
    }

    private int getAppResource(String name, String type) {
        return getApplication().getResources().getIdentifier(name, type, getApplication().getPackageName());
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(getAppResource("activity_camera", "layout"));

        m_viewFinder = findViewById(getAppResource("view_finder", "id"));//findViewById(R.id.view_finder);
        m_rectanglesView = (FaceRectView)findViewById(getAppResource("rectanglesView", "id"));//findViewById(R.id.view_finder); 
        m_registerBtn = (Button)findViewById(getAppResource("register", "id"));
        m_switchCamera = (ImageView)findViewById(getAppResource("switchCamera", "id"));

        mMainHandler = new MainMessageHandler();        
        // Initialize our background executor
        m_cameraExecutorService = Executors.newFixedThreadPool(1);
        
        m_context = this;
        m_mode = getIntent().getIntExtra("mode", 0);
        int cam_id = getIntent().getIntExtra("cam_id", 0);
        if(cam_id == 0) {
            m_lensFacing = CameraSelector.LENS_FACING_FRONT;
        } else {
            m_lensFacing = CameraSelector.LENS_FACING_BACK;
        }

        hasPermission = permissionsDelegate.hasPermissions();
        if(hasPermission) {
            m_viewFinder.post(() ->
            {
                setUpCamera();
            });    
        } else {
            permissionsDelegate.requestPermissions();
        }        

        m_registerBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.e("TestEngine", "register clicked");
                m_register = 1;
            }
        });

        m_switchCamera.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.e("TestEngine", "switch clicked");
                if(m_lensFacing == CameraSelector.LENS_FACING_BACK)
                    m_lensFacing = CameraSelector.LENS_FACING_FRONT;
                else
                    m_lensFacing = CameraSelector.LENS_FACING_BACK;

                bindCameraUseCases();
            }
        });

        if(m_mode == 0) {
            m_registerBtn.setVisibility(View.VISIBLE);
            m_switchCamera.setVisibility(View.VISIBLE);
        } else {
            m_registerBtn.setVisibility(View.INVISIBLE);
            m_switchCamera.setVisibility(View.INVISIBLE);
        }
    }

    /**
     * Initialize CameraX, and prepare to bind the camera use cases
     */
    private void setUpCamera()
    {
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture = ProcessCameraProvider.getInstance(CameraActivity.this);
        cameraProviderFuture.addListener(() -> {

            // CameraProvider
            try {
                m_cameraProvider = cameraProviderFuture.get();
            } catch (ExecutionException e) {
            } catch (InterruptedException e) {
            }

            // Build and bind the camera use cases
            bindCameraUseCases();

            @SuppressLint("RestrictedApi") Size size = m_imageAnalyzer.getAttachedSurfaceResolution();
            @SuppressLint("RestrictedApi") Size previewSize = m_preview.getAttachedSurfaceResolution();

        }, ContextCompat.getMainExecutor(CameraActivity.this));
    }

    /**
     * Declare and bind preview, capture and analysis use cases
     */
    @SuppressLint({"RestrictedApi", "UnsafeExperimentalUsageError"})
    private void bindCameraUseCases()
    {
        m_faceRectTransformer = null;

        int rotation = m_viewFinder.getDisplay().getRotation();
        m_cameraSelector = new CameraSelector.Builder().requireLensFacing(m_lensFacing).build();

        if(m_preview != null) {
            m_preview.setSurfaceProvider(null);
        }

        m_preview = new Preview.Builder()
                .setTargetResolution(new Size(720, 1280))
                .setTargetRotation(rotation)
                .build();

        m_imageAnalyzer = new ImageAnalysis.Builder()
                .setBackpressureStrategy(STRATEGY_KEEP_ONLY_LATEST)
                .setTargetResolution(new Size(720, 1280))
                // Set initial target rotation, we will have to call this again if rotation changes
                // during the lifecycle of this use case
                .setTargetRotation(rotation)
                .build();

        m_imageAnalyzer.setAnalyzer(m_cameraExecutorService, new FaceAnalyzer());

        // Must unbind the use-cases before rebinding them
        m_cameraProvider.unbindAll();

        try {
            // A variable number of use-cases can be passed here -
            // camera provides access to CameraControl & CameraInfo
            m_camera = m_cameraProvider.bindToLifecycle(
                    this, m_cameraSelector, m_preview, m_imageAnalyzer);

            // Attach the viewfinder's surface provider to preview use case
            m_preview.setSurfaceProvider(m_viewFinder.getSurfaceProvider());            

            m_seekFrame = 1;
            sendMessage(MSG_CLEAR_FACE, null);
        } catch (Exception exc) {
        }
    }

    class FaceAnalyzer implements ImageAnalysis.Analyzer
    {
        @SuppressLint("UnsafeExperimentalUsageError")
        @Override
        public void analyze(@NonNull ImageProxy imageProxy)
        {
            analyzeImage(imageProxy);
        }
    }

    void sendMessage(int id, Object obj) {
        Message message = new Message();
        message.what = id;
        message.obj =obj;
        mMainHandler.sendMessage(message);
    }

    @SuppressLint("UnsafeExperimentalUsageError")
    private void analyzeImage(ImageProxy imageProxy)
    {
        try
        {
            if(FacePlugin.closeCamera == 1) {
                finish();
                return;
            }

            Image image = imageProxy.getImage();

            Image.Plane[] planes = image.getPlanes();
            ByteBuffer yBuffer = planes[0].getBuffer();
            ByteBuffer uBuffer = planes[1].getBuffer();
            ByteBuffer vBuffer = planes[2].getBuffer();
        
            int ySize = yBuffer.remaining();
            int uSize = uBuffer.remaining();
            int vSize = vBuffer.remaining();
        
            byte[] nv21 = new byte[ySize + uSize + vSize];
            yBuffer.get(nv21, 0, ySize);
            vBuffer.get(nv21, ySize, vSize);
            uBuffer.get(nv21, ySize + vSize, uSize);            

            int  rotationDegrees = 360 - imageProxy.getImageInfo().getRotationDegrees();
            // Bitmap bitmap = FaceEngine.getInstance().yuvToBitmap(nv21, image.getWidth(), image.getHeight(), image.getWidth(), image.getHeight(), rotationDegrees, true);            
            // List<FaceResult> faceResults = FaceEngine.getInstance().detectFaceFromBitmap(bitmap, 1);            

            // if(faceResults.size() == 1) {

            //     FaceEngine.getInstance().extractFeatureFromBitmap(bitmap, faceResults);
            //     if(m_mode == 0) {

            //         if(m_register == 1 && faceResults.get(0).feature != null && faceResults.get(0).mask != 1) {
            //             m_register = 0;

            //             Rect cropRect = getBestRect(bitmap.getWidth(), bitmap.getHeight(), 
            //                 new Rect(faceResults.get(0).left, faceResults.get(0).top, faceResults.get(0).right, faceResults.get(0).bottom)); 
                    
            //             Bitmap cropBitmap  = crop(bitmap, cropRect.left, cropRect.top, cropRect.right - cropRect.left, cropRect.bottom - cropRect.top, 120, 120);

            //             ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();  
            //             cropBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
            //             byte[] byteArray = byteArrayOutputStream .toByteArray();
            //             String encodedImage = Base64.encodeToString(byteArray, Base64.DEFAULT);
            //             String encodedFeatrure = Base64.encodeToString(floatsToBytes(faceResults.get(0).feature), Base64.DEFAULT);

            //             String maxScoreID = "";
            //             float maxScore = 0;
            //             String existsID = "";
            //             for(Map.Entry<String,float[]> entry: FaceEngine.userLists.entrySet()) {                   
    
            //                 float score = FaceEngine.getInstance().compareFeature(entry.getValue(), faceResults.get(0).feature);
            //                 if(maxScore < score) {
            //                     maxScore = score; 
            //                     maxScoreID = entry.getKey();
            //                 }                           
            //             }

            //             if(maxScore > THRESHOLD_REGISTER) {
            //                 existsID = maxScoreID;
            //             }

            //             Intent returnIntent = new Intent();
            //             returnIntent.putExtra("data", encodedFeatrure);
            //             returnIntent.putExtra("image", encodedImage);                        
            //             returnIntent.putExtra("exists", existsID);                        
            //             setResult(RESULT_OK,returnIntent);
            //             finish();                        
            //         }
            //     } else if(m_mode == 1) {
                    
            //         String maxScoreID = "";
            //         float maxScore = 0;
            //         for(Map.Entry<String,float[]> entry: FaceEngine.userLists.entrySet()) {                   

            //             float score = FaceEngine.getInstance().compareFeature(entry.getValue(), faceResults.get(0).feature);
            //             if(maxScore < score) {
            //                 maxScore = score; 
            //                 maxScoreID = entry.getKey();
            //             }                           
            //         }

            //         String faceID = "";
            //         if(maxScore > THRESHOLD_VERIFY) {
            //             faceID = maxScoreID;
            //         }
                    
            //         int mask = faceResults.get(0).mask == 1 ? 1 : 0;
            //         int liveness = faceResults.get(0).livenessScore > THRESHOLD_LIVENESS ? 1 : 0;
    
   
            //         try {
            //             JSONObject face_boundary = new JSONObject();
            //             face_boundary.put("left", faceResults.get(0).left);
            //             face_boundary.put("top", faceResults.get(0).top);
            //             face_boundary.put("right", faceResults.get(0).right);
            //             face_boundary.put("bottom", faceResults.get(0).bottom);

            //             JSONObject jo = new JSONObject();
            //             jo.put("face_id", faceID);
            //             jo.put("mask", mask);     
            //             jo.put("liveness", liveness);
            //             jo.put("face_count", faceResults.size());
            //             jo.put("face_boundary", face_boundary);
                        
            //             PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, jo);                        
            //             pluginResult.setKeepCallback(true);
            //             FacePlugin.callbackContext.sendPluginResult(pluginResult);
            //         } catch(Exception e) {}
            //     }
            // } else if(faceResults.size() > 1) {
            //     if(m_mode == 1) {
            //         try {
            //             JSONObject face_boundary = new JSONObject();
            //             face_boundary.put("left", faceResults.get(0).left);
            //             face_boundary.put("top", faceResults.get(0).top);
            //             face_boundary.put("right", faceResults.get(0).right);
            //             face_boundary.put("bottom", faceResults.get(0).bottom);
    
            //             JSONObject jo = new JSONObject();
            //             jo.put("face_id", "");
            //             jo.put("mask", 0);     
            //             jo.put("liveness", 0);
            //             jo.put("face_count", faceResults.size());
            //             jo.put("face_boundary", face_boundary);
                        
            //             PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, jo);                        
            //             pluginResult.setKeepCallback(true);
            //             FacePlugin.callbackContext.sendPluginResult(pluginResult);
            //         } catch(Exception e) {}    
            //     }                
            // } else {
            //     if(m_mode == 1) {                    
            //         try {
            //             JSONObject face_boundary = new JSONObject();
            //             face_boundary.put("left", -1);
            //             face_boundary.put("top", -1);
            //             face_boundary.put("right", -1);
            //             face_boundary.put("bottom", -1);
    
            //             JSONObject jo = new JSONObject();
            //             jo.put("face_id", "");
            //             jo.put("mask", 0);     
            //             jo.put("liveness", 0);
            //             jo.put("face_count", 0);
            //             jo.put("face_boundary", face_boundary);
                        
            //             PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, jo);                        
            //             pluginResult.setKeepCallback(true);
            //             FacePlugin.callbackContext.sendPluginResult(pluginResult);
            //         } catch(Exception e) {}    
            //     }
            // }
            
            if(m_seekFrame == 1) {
                m_seekFrame = 2;
            } else {
                // sendMessage(MSG_UPDATE_FACE, faceResults);
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        finally
        {
            imageProxy.close();
        }
    }


    @Override
    protected void onResume() {
        super.onResume();

        if(permissionsDelegate.hasPermissions() && hasPermission == false) {
            hasPermission = true;

            m_viewFinder.post(() ->
            {
                setUpCamera();
            });  
        } else {
            permissionsDelegate.requestPermissions();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }    

    private static Rect getBestRect(int width, int height, Rect srcRect) {
        if (srcRect == null) {
            return null;
        }
        Rect rect = new Rect(srcRect);

        int maxOverFlow = Math.max(-rect.left, Math.max(-rect.top, Math.max(rect.right - width, rect.bottom - height)));
        if (maxOverFlow >= 0) {
            rect.inset(maxOverFlow, maxOverFlow);
            return rect;
        }

        int padding = rect.height() / 2;

        if (!(rect.left - padding > 0 && rect.right + padding < width && rect.top - padding > 0 && rect.bottom + padding < height)) {
            padding = Math.min(Math.min(Math.min(rect.left, width - rect.right), height - rect.bottom), rect.top);
        }
        rect.inset(-padding, -padding);
        return rect;
    }

    public static Bitmap crop(final Bitmap src, final int srcX, int srcY, int srcCroppedW, int srcCroppedH, int newWidth, int newHeight) {
        final int srcWidth = src.getWidth();
        final int srcHeight = src.getHeight();
        float scaleWidth = ((float) newWidth) / srcCroppedW;
        float scaleHeight = ((float) newHeight) / srcCroppedH;
        
// exit early if no resize/crop needed
        final Matrix m = new Matrix();

        m.setScale(1.0f, 1.0f);
        m.postScale(scaleWidth, scaleHeight);        
        final Bitmap cropped = Bitmap.createBitmap(src, srcX, srcY, srcCroppedW, srcCroppedH, m,
                true /* filter */);
        return cropped;
    }

    public static byte[] floatsToBytes(float[] floats) {
        byte bytes[] = new byte[Float.BYTES * floats.length];
        ByteBuffer.wrap(bytes).asFloatBuffer().put(floats);
        return bytes;
    }
    
    public static float[] bytesToFloats(byte[] bytes) {
        if (bytes.length % Float.BYTES != 0)
            throw new RuntimeException("Illegal length");
        float floats[] = new float[bytes.length / Float.BYTES];
        ByteBuffer.wrap(bytes).asFloatBuffer().get(floats);
        return floats;
    }
}
