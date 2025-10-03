package com.ttv.face.plugin;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.kbyai.facesdk.*;
import com.ttv.facerecog.*;
import android.widget.Toast;
import android.app.Activity;
import java.util.HashMap;
import java.util.Map;
import android.util.Base64;


public class FacePlugin extends CordovaPlugin {

    private boolean initialized;
    public static CallbackContext callbackContext;
    public static int closeCamera;

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }
    
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Context context = cordova.getActivity().getApplicationContext();

        if(this.initialized == false) {

            this.initialized = true;
        }

        if(action.equals("face_register")) {           
            JSONObject input = args.getJSONObject(0);
            int cam_id = input.getInt("cam_id");
            FacePlugin.closeCamera = 0;

            this.openNewActivity(context, callbackContext, 0, cam_id, 10000);
            return true;
        } else if(action.equals("face_recognize")) {
            JSONObject input = args.getJSONObject(0);
            int cam_id = input.getInt("cam_id");
            FacePlugin.closeCamera = 0;

            this.openNewActivity(context, callbackContext, 1, cam_id, 10001);
            return true;
        } else if(action.equals("update_data")) {

            JSONObject input = args.getJSONObject(0);
            JSONArray user_list = input.getJSONArray("user_list");
            
            for(int i = 0; i < user_list.length(); i ++) {
                JSONObject user =  user_list.getJSONObject(i);
                String face_id = user.getString("face_id");
                byte[] feat = Base64.decode(user.getString("data"), Base64.DEFAULT);
                CameraActivity.userLists.put(face_id,  feat);
            }
            
            return true;
        } else if(action.equals("clear_data")) {
            
            Log.e("TestEngine", "clear_data ");
            CameraActivity.userLists.clear(); 
            return true;
        } else if(action.equals("close_camera")) {
            Log.e("TestEngine", "close camera");
            FacePlugin.closeCamera = 1;
            return true;
        } else if(action.equals("set_activation")) {
            JSONObject input = args.getJSONObject(0);
            String license = input.getString("license");
            int ret = FaceSDK.setActivation(license);
            if(ret == 0) {
                FaceSDK.init(cordova.getActivity().getApplicationContext().getAssets());
            }
            
            Log.e("TestEngine", "set activation: " + ret + " license: " + license);

            String applicationId = cordova.getActivity().getApplicationContext().getPackageName();
            Log.e("TestEngine", "applicationId: " + applicationId);
        }
        return false;
    }

    private void openNewActivity(Context context, CallbackContext callbackContext, int mode, int cam_id, int rqquest_code) {

        FacePlugin.callbackContext = callbackContext;        

        Intent intent = new Intent(context, CameraActivity.class);
        intent.putExtra("mode", mode);
        intent.putExtra("cam_id", cam_id);

        cordova.setActivityResultCallback (this); 
        this.cordova.getActivity().startActivityForResult(intent, rqquest_code);
    }

    public void onActivityResult(int requestCode, int resultCode, Intent intent){
        if(requestCode == 10000) {
            if(resultCode == Activity.RESULT_OK) {
                String feature = intent.getStringExtra("data");
                String image = intent.getStringExtra("image");
                String existsID = intent.getStringExtra("exists");
                int featureLen = image.length();

                try {
                    JSONObject jo = new JSONObject();
                    jo.put("data", feature);
                    jo.put("image", image);     
                    jo.put("exists", existsID);
                    FacePlugin.callbackContext.success(jo); 
                } catch(Exception e) {}
                                
                if(existsID.length() == 0)
                    Toast.makeText(this.cordova.getActivity(), "register success!",  Toast.LENGTH_SHORT).show();
                else
                    Toast.makeText(this.cordova.getActivity(), "duplicated user!",  Toast.LENGTH_SHORT).show();                    
            } else {                
                FacePlugin.callbackContext.error("register canceled!");                
                Toast.makeText(this.cordova.getActivity(), "register cannceled",  Toast.LENGTH_SHORT).show();
            }

            cordova.setActivityResultCallback (null); 
        } else if(requestCode == 10001) {
            // if(resultCode == Activity.RESULT_OK) {
            //     // String faceID = intent.getStringExtra("face_id");
            //     // int mask = intent.getIntExtra("mask", 0);
            //     // int liveness = intent.getIntExtra("liveness", 0);

            //     // PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "WHAT");
            //     // pluginResult.setKeepCallback(true);
            //     // FacePlugin.callbackContext.sendPluginResult(pluginResult);

            //     // try {
            //     //     JSONObject jo = new JSONObject();
            //     //     jo.put("face_id", faceID);
            //     //     jo.put("mask", mask);     
            //     //     jo.put("liveness", liveness);                    
            //     //     this.callbackContext.success(jo); 
            //     // } catch(Exception e) {}
                
            //     // Toast.makeText(this.cordova.getActivity(), "recognize success!",  Toast.LENGTH_SHORT).show();
            // } else {                
            //     // FacePlugin.callbackContext.error("register canceled!");                
            //     Toast.makeText(this.cordova.getActivity(), "recognize cannceled",  Toast.LENGTH_SHORT).show();
            // }
            
            FacePlugin.callbackContext.error("recognize canceled!");
            cordova.setActivityResultCallback (null); 
        }
    }
}