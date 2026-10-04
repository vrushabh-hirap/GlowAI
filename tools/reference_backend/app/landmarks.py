# glowai_backend/app/landmarks.py
import os
import math
import cv2
import numpy as np
import mediapipe as mp

MODEL_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models", "face_landmarker.task"
)

class MediaPipeLandmarksWrapper:
    _instance = None

    def __init__(self):
        self.use_tasks_api = False
        self.landmarker = None
        self.face_mesh = None
        
        if os.path.exists(MODEL_PATH) and hasattr(mp, "tasks"):
            try:
                BaseOptions = mp.tasks.BaseOptions
                FaceLandmarker = mp.tasks.vision.FaceLandmarker
                FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
                VisionRunningMode = mp.tasks.vision.RunningMode

                options = FaceLandmarkerOptions(
                    base_options=BaseOptions(model_asset_path=MODEL_PATH),
                    running_mode=VisionRunningMode.IMAGE,
                    num_faces=5,  # Allow detecting multiple faces to report in quality checks
                )
                self.landmarker = FaceLandmarker.create_from_options(options)
                self.use_tasks_api = True
            except Exception as e:
                print(f"Warning: Tasks API initialization failed: {e}. Falling back to mp.solutions.face_mesh.")
        
        if not self.use_tasks_api:
            if hasattr(mp, "solutions") and hasattr(mp.solutions, "face_mesh"):
                self.face_mesh = mp.solutions.face_mesh.FaceMesh(
                    static_image_mode=True,
                    max_num_faces=5,
                    refine_landmarks=True,
                    min_detection_confidence=0.5,
                )
            else:
                raise RuntimeError("MediaPipe FaceMesh / FaceLandmarker is not available in current environment.")

    def process(self, rgb_image: np.ndarray):
        """
        Processes an RGB image (H, W, 3).
        Returns:
            face_count: int
            landmarks_list: List[List[Tuple[int, int]]] (pixel coordinates per face)
            poses_list: List[Tuple[float, float, float]] (yaw, pitch, roll in degrees per face)
        """
        h, w, _ = rgb_image.shape
        landmarks_list = []
        poses_list = []

        if self.use_tasks_api:
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_image)
            result = self.landmarker.detect(mp_image)
            face_landmarks_raw = result.face_landmarks
        else:
            results = self.face_mesh.process(rgb_image)
            face_landmarks_raw = results.multi_face_landmarks or []

        for face in face_landmarks_raw:
            pts = []
            if self.use_tasks_api:
                for lm in face:
                    pts.append((int(lm.x * w), int(lm.y * h)))
            else:
                for lm in face.landmark:
                    pts.append((int(lm.x * w), int(lm.y * h)))
            
            landmarks_list.append(pts)
            yaw, pitch, roll = self.estimate_pose(pts, w, h)
            poses_list.append((yaw, pitch, roll))

        return len(landmarks_list), landmarks_list, poses_list

    def estimate_pose(self, pts, w, h):
        """
        Estimates yaw, pitch, roll from landmark points using cv2.solvePnP.
        Key landmark indices:
        Nose tip: 1
        Chin: 152
        Left eye corner: 33
        Right eye corner: 263
        Left mouth corner: 61
        Right mouth corner: 291
        """
        if len(pts) < 468:
            return 0.0, 0.0, 0.0

        image_points = np.array([
            pts[1],     # Nose tip
            pts[152],   # Chin
            pts[33],    # Left eye left corner
            pts[263],   # Right eye right corner
            pts[61],    # Left mouth corner
            pts[291]    # Right mouth corner
        ], dtype="double")

        # 3D generic face model coordinates
        model_points = np.array([
            (0.0, 0.0, 0.0),             # Nose tip
            (0.0, -330.0, -65.0),        # Chin
            (-225.0, 170.0, -135.0),     # Left eye corner
            (225.0, 170.0, -135.0),      # Right eye corner
            (-150.0, -150.0, -125.0),    # Left mouth corner
            (150.0, -150.0, -125.0)      # Right mouth corner
        ])

        focal_length = w
        center = (w / 2, h / 2)
        camera_matrix = np.array([
            [focal_length, 0, center[0]],
            [0, focal_length, center[1]],
            [0, 0, 1]
        ], dtype="double")

        dist_coeffs = np.zeros((4, 1))
        success, rotation_vector, translation_vector = cv2.solvePnP(
            model_points, image_points, camera_matrix, dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE
        )

        if not success:
            return 0.0, 0.0, 0.0

        rmat, _ = cv2.Rodrigues(rotation_vector)
        proj_matrix = np.hstack((rmat, translation_vector))
        _, _, _, _, _, _, euler_angles = cv2.decomposeProjectionMatrix(proj_matrix)

        pitch = float(euler_angles[0][0])
        yaw = float(euler_angles[1][0])
        roll = float(euler_angles[2][0])

        return yaw, pitch, roll

_wrapper_instance = None

def get_landmarks_wrapper():
    global _wrapper_instance
    if _wrapper_instance is None:
        _wrapper_instance = MediaPipeLandmarksWrapper()
    return _wrapper_instance
