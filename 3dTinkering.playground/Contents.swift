import Cocoa
import SceneKit
import PlaygroundSupport

// Create a SceneKit view
let sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))

// Create a new scene
let scene = SCNScene()

// Set the scene to the view
sceneView.scene = scene

// Allow user to manipulate camera
sceneView.allowsCameraControl = true

// Show statistics such as fps and timing information
sceneView.showsStatistics = true

// Configure the view
sceneView.backgroundColor = NSColor.black

// Create and add a camera to the scene
let cameraNode = SCNNode()
cameraNode.camera = SCNCamera()
cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
scene.rootNode.addChildNode(cameraNode)

// Create a torus geometry
let torus = SCNTorus(ringRadius: 3, pipeRadius: 1)
let material = SCNMaterial()
material.diffuse.contents = NSColor.blue
torus.materials = [material]
let torusNode = SCNNode(geometry: torus)
scene.rootNode.addChildNode(torusNode)

// Create and add an ambient light to the scene
let ambientLightNode = SCNNode()
ambientLightNode.light = SCNLight()
ambientLightNode.light?.type = .ambient
ambientLightNode.light?.color = NSColor.darkGray
scene.rootNode.addChildNode(ambientLightNode)

// Create and add an omnidirectional light to the scene
let omniLightNode = SCNNode()
omniLightNode.light = SCNLight()
omniLightNode.light?.type = .omni
omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
scene.rootNode.addChildNode(omniLightNode)

// Create a rotation animation
let rotation = CABasicAnimation(keyPath: "rotation")
rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, CGFloat.pi * 2))
rotation.duration = 5 // Duration in seconds
rotation.repeatCount = .infinity // Repeat forever
torusNode.addAnimation(rotation, forKey: "rotation")

func generateRandomColor() -> NSColor {
    return NSColor(
        calibratedHue: CGFloat(arc4random() % 256) / 256.0,
        saturation: 1.0,
        brightness: 1.0,
        alpha: 1.0)
}

func humanReadableColor(_ color: NSColor) -> String {
    switch color {
    case NSColor.red: return "Red"
    case NSColor.green: return "Green"
    case NSColor.blue: return "Blue"
    case NSColor.yellow: return "Yellow"
    case NSColor.orange: return "Orange"
    case NSColor.purple: return "Purple"
    case NSColor.cyan: return "Cyan"
    case NSColor.magenta: return "Magenta"
    case NSColor.brown: return "Brown"
    default: return "Color"
    }
}

func createRandomSphere() {
    // Generate a random color
    let color = generateRandomColor()
    
    // Create a sphere geometry
    let sphere = SCNSphere(radius: 0.5)
    
    // Create a material with the random color
    let material = SCNMaterial()
    material.diffuse.contents = color
    sphere.materials = [material]
    
    // Create a node with the sphere geometry
    let sphereNode = SCNNode(geometry: sphere)
    
    // Set the initial position of the sphere
    let randomX = Float(arc4random() % 10) - 5.0
    sphereNode.position = SCNVector3(x: randomX, y: 10, z: 0)
    
    // Add text label
    let text = SCNText(string: humanReadableColor(color), extrusionDepth: 1)
    text.font = NSFont.systemFont(ofSize: 1)
    text.firstMaterial?.diffuse.contents = NSColor.white
    
    let textNode = SCNNode(geometry: text)
    textNode.scale = SCNVector3(0.1, 0.1, 0.1)
    textNode.position = SCNVector3(x: -0.5, y: -0.5, z: 0)
    sphereNode.addChildNode(textNode)
    
    // Add the sphere node to the scene
    scene.rootNode.addChildNode(sphereNode)
    
    // Create a fall animation
    let fall = CABasicAnimation(keyPath: "position.y")
    fall.fromValue = sphereNode.position.y
    fall.toValue = -10
    fall.duration = 5
    fall.isRemovedOnCompletion = false
    fall.fillMode = .forwards
    
    // Add the animation to the sphere node
    sphereNode.addAnimation(fall, forKey: "fall")
}

// Add a Timer to generate spheres every second
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    createRandomSphere()
}

// Set the live view
PlaygroundPage.current.liveView = sceneView
