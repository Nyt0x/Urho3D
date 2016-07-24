// PBR materials example.
// This sample demonstrates:
//      - Loading a scene that showcases physically based materials & shaders
//
// To use with deferred rendering, a PBR deferred renderpath should be chosen:
// CoreData/RenderPaths/PBRDeferred.xml or CoreData/RenderPaths/PBRDeferredHWDepth.xml

#include "Scripts/Utilities/Sample.as"

void Start()
{
    // Execute the common startup for samples
    SampleStart();

    // Create the scene content
    CreateScene();

    // Create the UI content and subscribe to UI events
    CreateUI();

    // Setup the viewport for displaying the scene
    SetupViewport();

    // Subscribe to global events for camera movement
    SubscribeToEvents();
}

void CreateScene()
{
    scene_ = Scene();

    // Load scene content prepared in the editor (XML format). GetFile() returns an open file from the resource system
    // which scene.LoadXML() will read
    scene_.LoadXML(cache.GetFile("Scenes/PBRExample.xml"));

    // Create the camera (not included in the scene file)
    cameraNode = scene_.CreateChild("Camera");
    cameraNode.CreateComponent("Camera");

    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 4.0f, 0.0f);
}

void CreateUI()
{
    // Set up global UI style into the root UI element
    XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    ui.root.defaultStyle = style;

    // Create a Cursor UI element because we want to be able to hide and show it at will. When hidden, the mouse cursor will
    // control the camera, and when visible, it will interact with the UI
    Cursor@ cursor = Cursor();
    cursor.SetStyleAuto();
    ui.cursor = cursor;
    // Set starting position of the cursor at the rendering window center
    cursor.SetPosition(graphics.width / 2, graphics.height / 2);
}

void SetupViewport()
{
    renderer.hdrRendering = true;

    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;

    // Add post-processing effects appropriate with the example scene
    RenderPath@ effectRenderPath = viewport.renderPath.Clone();
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/BloomHDR.xml"));
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/FXAA2.xml"));
    effectRenderPath.Append(cache.GetResource("XMLFile", "PostProcess/GammaCorrection.xml"));

    viewport.renderPath = effectRenderPath;
}

void SubscribeToEvents()
{
    // Subscribe HandleUpdate() function for camera motion
    SubscribeToEvent("Update", "HandleUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);
}

void MoveCamera(float timeStep)
{
    // Right mouse button controls mouse cursor visibility: hide when pressed
    ui.cursor.visible = !input.mouseButtonDown[MOUSEB_RIGHT];

    // Do not move if the UI has a focused element
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    const float MOVE_SPEED = 10.0f;
    // Mouse sensitivity as degrees per pixel
    const float MOUSE_SENSITIVITY = 0.1f;

    // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
    // Only move the camera when the cursor is hidden
    if (!ui.cursor.visible)
    {
        IntVector2 mouseMove = input.mouseMove;
        yaw += MOUSE_SENSITIVITY * mouseMove.x;
        pitch += MOUSE_SENSITIVITY * mouseMove.y;
        pitch = Clamp(pitch, -90.0f, 90.0f);

        // Construct new orientation for the camera scene node from yaw and pitch. Roll is fixed to zero
        cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
    }

    // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
    if (input.keyDown[KEY_W])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_S])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_A])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_D])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";
