var exec = require('cordova/exec');

function face_register(cam_id, result) {
    exec(result, function(err){}, "FacePlugin", "face_register", [{cam_id:cam_id}]);
};


function face_recognize(cam_id, result) {
    exec(result, function(err){}, "FacePlugin", "face_recognize", [{cam_id:cam_id}]);
};

function update_data(user_list) {
    exec(function(res){
    }, function(err){}, "FacePlugin", "update_data", [{user_list: user_list}]);
};

function face_register_from_image(image) {
    exec(function(res){
    }, function(err){}, "FacePlugin", "face_register_from_image", [{image: image}]);
};

function close_camera() {
    exec(function(res){
    }, function(err){}, "FacePlugin", "close_camera", []);    
};

function clear_data() {
    exec(function(res){
    }, function(err){}, "FacePlugin", "clear_data", []);    
};

module.exports = {
    face_register: face_register,
    face_recognize:face_recognize,
    update_data:update_data,
    face_register_from_image:face_register_from_image,
    close_camera: close_camera,
    clear_data: clear_data
};