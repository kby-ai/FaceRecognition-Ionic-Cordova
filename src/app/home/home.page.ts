import { Component } from '@angular/core';
import { Platform } from '@ionic/angular';

declare var cordova: any;

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  user_list: any[] = [];

  constructor(private platform: Platform) {
    this.platform.ready().then(() => {
      console.log('init home page');

      if(this.platform.is('android')) {
        if (window.hasOwnProperty('cordova')) {
          console.log('call cordova api');
          cordova.exec(
            (success: any) => {
              console.log('Success:', success);
            },
            (error: any) => {
              console.error('Error:', error);
            },
            'FacePlugin',  // The Java/Kotlin class name
            'set_activation',    // The method name defined in Kotlin
            [{"license": "jEJQsb6lo5IzEE4M5P2ZzVeSpt/FSANo8Kh0DMnDxg9dzCmBaaPXfmd/y6OGwRnMbqoyjz3bhUBW" +
"q1AJyxCWIdekFDPD7nQqrjA1n2DPLaGSOYRLbHnFI4hpgCvN8WuI/X4OX4ZkHGljX8BopbSd+2OD" +
"NNg8/5Df2n79YquKbnpI9yNXssLlmjSrsnJpOe3iRUv0Gh0QiyRyEMpyIE5iP81hwPF8Q2M436Ga" +
"lOY/EQ1s+URregYomX365VGTtDuvhO2JqK3Xy8qGUGcQ3gtkXM+l67q0QlzsfuX1yGUA5h4KLju1" +
"xYoTJhQD6cgO2f7xqiydqUrmLzUbphrknYZbWw=="}]  // Arguments to pass to the native method
          );
        } else {
          console.warn('Cordova not available');
        }
      } else if(this.platform.is('ios')) {
        if (window.hasOwnProperty('cordova')) {
          console.log('call cordova api');
          cordova.exec(
            (success: any) => {
              console.log('Success:', success);
            },
            (error: any) => {
              console.error('Error:', error);
            },
            'FacePlugin',  // The Java/Kotlin class name
            'set_activation',    // The method name defined in Kotlin
            [{"license": "CRICij8qW6uHIVPwnEHJ8NcKLKWYxddTxJLpDl/0fRktsVlOTRdY8g7z7bzmek+lPplauMKNK26n" +
            "NFfJ1tz211WDbcQ03RPb7NCG/yOUbkJ5/sd+KqXpanQg5oqqfITmc87pv+e+fxRCpZBZZ0teUW93" +
            "EXW15m1LDikOA6YdaLGrwdsdBlUpsY96ZiObgmmHhNNkYQLpJ65yQCeVBMZTj8iQg7RRqnqwZ6xZ" +
            "OnHWxFHiZXtWnj/SGIWy7PzKctDAXI8R9Np4fdBFjFyPCp1JJTcx2XsVfK3vj/iEI6dRCFDS+ueC" +
            "eDtWGKRYH7Pcxaz8Pp1j5MAbKggVNWqk4AR/8Q=="}]  // Arguments to pass to the native method
          );
        } else {
          console.warn('Cordova not available');
        }  
      }
    });
  }

  updateData(user_list: any) {
    console.log('Update Data');
    if (window.hasOwnProperty('cordova')) {
      console.log('call cordova api');
      cordova.exec(
        (success: any) => {
          console.log('Success:', success);
        },
        (error: any) => {
          console.error('Error:', error);
        },
        'FacePlugin',  // The Java/Kotlin class name
        'update_data',    // The method name defined in Kotlin
        [{"user_list": user_list}]  // Arguments to pass to the native method
      );
    } else {
      console.warn('Cordova not available');
    }
  }

  enrollPerson() {
    console.log('Enroll button clicked');
    if (window.hasOwnProperty('cordova')) {
      console.log('call cordova api');
      cordova.exec(
        (success: any) => {
          console.log('Success:', success);

          if(success['exists'] == "") {
            success['face_id'] = this.user_list.length + 1;
            this.user_list.push(success);
    
            // FacePlugin.update_data(user_list);
            this.updateData(this.user_list);
            
            console.log("registered user");
        } else {
            console.log("xxxx dup");
        }
        },
        (error: any) => {
          console.error('Error:', error);
        },
        'FacePlugin',  // The Java/Kotlin class name
        'face_register',    // The method name defined in Kotlin
        [{"cam_id": 0}]  // Arguments to pass to the native method
      );
    } else {
      console.warn('Cordova not available');
    }
  }

  identifyPerson() {
    console.log('Identify button clicked');
    if (window.hasOwnProperty('cordova')) {
      console.log('call cordova api');
      cordova.exec(
        (success: any) => {
          console.log('Success:', success);
          console.log("xxx000000 " + success['face_id'] + " " + success['liveness'] + " " + success['face_boundary']['left'] + " " + 
            success['face_boundary']['top'] + " " + success['face_boundary']['right'] + " " + success['face_boundary']['bottom']);

        },
        (error: any) => {
          console.error('Error:', error);
        },
        'FacePlugin',  // The Java/Kotlin class name
        'face_recognize',    // The method name defined in Kotlin
        [{"cam_id": 0}]  // Arguments to pass to the native method
      );
    } else {
      console.warn('Cordova not available');
    }
  }
}
