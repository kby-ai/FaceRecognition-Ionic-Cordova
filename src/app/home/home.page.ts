import { Component } from '@angular/core';
import { Platform, ToastController } from '@ionic/angular'; // <-- add ToastController
import { Camera, CameraOptions } from '@awesome-cordova-plugins/camera/ngx';

declare var cordova: any;



@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  user_list: any[] = [];

  constructor(
    private platform: Platform,
    private toastController: ToastController,
    private camera: Camera
  ) {
    this.platform.ready().then(() => {
      console.log('init home page');
      this.activateFaceSDK();
    });
  }
  

  activateFaceSDK() {
    if (!window.hasOwnProperty('cordova')) return;

    const license = this.platform.is('android') 
      ? "PIM1QqfoKi6AV4Hp2TgJrI6eakYfpniOoDM8zvGINYxR1gQkvcAk6ZCyNENyw9cRXLjDuj84nhHS6JZcMKzRovAkubKJv5Ep7qICNdcjGBURD06UuwK3h7KQ/PRG17M1Vx/2Wd91qP6bmqUJEhG5NMmYuSroYScXxPR/KhBxVOZDZwvaaAj/Ugwu+bKQd7ILK0Hb2jxI1Ee0RmsWelih+FwllpwQS7vLsZ+QYIA553yc+uS1HEAt/kfedY9xKHekSqnJNAyuJvJyZ1MB0wadAs0MW5sbklUEs+FIgPcO87N43Ky+WWeRMkBuwbne6bI8g4XNKkMbi1ldmXXBdai7nQ=="
      : "FIdSzEzVjrpi6HNdU8OL60Z474YljefDa0vMvnY+Sag0vzJRuR3Nl+aTF3mqFJ4Nybh996F5Z9nM6s3ShVECCp8bk1Q348MvxVjwp4R3ABGW8yc5CVSvBC8GJwpzHwClGra/j4rME56xHEZRcgP1J6o4Xfu+ovWD+ebHDpT1ZF/PzeKNLoPlr98qlkYlIoOPCrdgKvHa0HeZdfsK4wsMK0W4DYVRsL3EJmhcAyMdz7+XQCTmEKoZQ3A3/5YR4CkVyap6qT2PFthdjYeAZbaY1OPGfHXpOOgLADPaUd0ZeblU23rd/9T2jo86o3Osd2bLYTT6/Wks54XxX39WYaa2zw==";

    cordova.exec(
      (success: any) => console.log('FaceSDK activation success', success),
      (error: any) => console.error('FaceSDK activation error', error),
      'FacePlugin',
      'set_activation',
      [{ license }]
    );
  }

  async showTooltip(msg: string) {
    const toast = await this.toastController.create({
      message: msg,
      duration: 2000,
      position: 'top',
      color: 'success'
    });
    toast.present();
  }

  enrollPerson() {
    if (!window.hasOwnProperty('cordova')) return;

    cordova.exec(
      (success: any) => {
        console.log('Enroll success:', success);

        if (success.exists === "") {
          success.face_id = this.user_list.length + 1;
          this.user_list.push(success);
          this.updateData(this.user_list);
          this.showTooltip("New user registered: Face ID " + success.face_id);
        } else {
          this.showTooltip("User already exists: Face ID " + success.face_id);
        }
      },
      (error: any) => console.error('Enroll error:', error),
      'FacePlugin',
      'face_register',
      [{ cam_id: 0 }]
    );
  }

  identifyPerson() {
    if (!window.hasOwnProperty('cordova')) return;

    cordova.exec(
      (success: any) => {
        if (success?.face_id != null && success.face_id !== "" && success.face_id !== -1) {
          const resultText = `Face ID: ${success.face_id}        
          Liveness: ${success.liveness}
Boundary: left=${success.face_boundary.left}, top=${success.face_boundary.top}, right=${success.face_boundary.right}, bottom=${success.face_boundary.bottom}`;
          
          // Show tooltip immediately
          this.showTooltip(resultText);

          // Close camera after success
          cordova.exec(
            () => console.log('Camera closed successfully'),
            (error: any) => console.error('Error closing camera:', error),
            'FacePlugin',
            'close_camera',
            []
          );
        }
      },
      (error: any) => {
        // this.showTooltip('Error: ' + JSON.stringify(error));
      },
      'FacePlugin',
      'face_recognize',
      [{ cam_id: 0 }]
    );
  }

  updateData(user_list: any) {
    if (!window.hasOwnProperty('cordova')) return;

    cordova.exec(
      (success: any) => console.log('Update data success', success),
      (error: any) => console.error('Update data error', error),
      'FacePlugin',
      'update_data',
      [{ user_list }]
    );
  }

  enrollFromGallery() {
  
    // Prevent calling before Cordova is ready
    if (!window.hasOwnProperty('cordova')) {
      this.showTooltip("Cordova not ready");
      return;
    }
  
    const options: CameraOptions = {
      quality: 80,
      destinationType: this.camera.DestinationType.DATA_URL,
      sourceType: this.camera.PictureSourceType.PHOTOLIBRARY,
      encodingType: this.camera.EncodingType.JPEG,
      mediaType: this.camera.MediaType.PICTURE,
      correctOrientation: true,
    };
  
    this.camera.getPicture(options).then(
      (imageData: string) => {
        let base64Data = imageData;
        if (base64Data.startsWith("data:image")) {
          // iOS already includes prefix, so strip it
          base64Data = base64Data.substring(base64Data.indexOf(",") + 1);
        }
        const base64Image = "data:image/jpeg;base64," + base64Data;

        console.log("Selected image:", base64Image.substring(0, 50) + "...");
  
        // Send image to FacePlugin (uncomment if implemented)
        
        cordova.exec(
          (success: any) => {
            console.log('Enroll from gallery success:', success);
            success.face_id = this.user_list.length + 1;
            this.user_list.push(success);
            this.updateData(this.user_list);
            this.showTooltip("Enrolled from gallery: Face ID " + success.face_id);
          },
          (error: any) => {
            console.error('Enroll from gallery error:', error);
            this.showTooltip("Failed to enroll from gallery");
          },
          'FacePlugin',
          'face_register_from_image',
          [{ image: base64Image }]
        );
        
      },
      (err: any) => {
        console.error("Gallery error:", err);
        this.showTooltip("Image selection cancelled or failed");
      }
    );
  }
  
}
