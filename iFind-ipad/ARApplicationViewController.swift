//
//  ARApplicationViewController.swift
//  iFind-ipad
//
//  Created by 赵一达 on 2018/5/12.
//  Copyright © 2018年 赵一达. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import SpriteKit
import ARKit
import CoreData
import PageMenu



class ARApplicationViewController: UIViewController,ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var ToolView: ToolView!
    @IBOutlet weak var hintMessage: UIImageView!
    
    var planes = [UUID:Plane]()
    var brushes = [PencilBrush()]
    var undoer = UndoManager()
    var pointAbove = CGPoint()
    var pointBelow = CGPoint(){
        didSet{
            scaleCounting()
        }
    }
    
    var modelToPlace:String = ""{
        didSet{
            if modelToPlace != "" {
                readyToPlace()
            }
        }
    }
    var hint = "hint2"{
        didSet{
            if hint == "hint" {
                changeHint()
            }
        }
    }
    
    var modelInScene:[String] = []{
        didSet{
            if (ToolView.controller as? ModelTableViewController)?.mediaArray != nil{
                (ToolView.controller as? ModelTableViewController)?.mediaArray = modelInScene
            }
            if (ToolView.controller as? ModelTableViewController)?.mediaTableView != nil{
                (ToolView.controller as? ModelTableViewController)?.mediaTableView.reloadData()
            }
           
        }
    }
    var currentSelectedModel:SCNNode = SCNNode(){
        didSet{
            (ToolView.pageMenu?.moveToPage(1))
            let name = currentSelectedModel.parent?.name
            if name != nil {
                
                let index = Int(name!)
                let indexPath = IndexPath(row: index!, section: 0)
                let tableView = (ToolView.controller as! ModelTableViewController).mediaTableView
                tableView?.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
     

        // Do any additional setup after loading the view, typically from a nib.
//        sceneView = ARSCNView(frame: self.view.frame)
    
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.isUserInteractionEnabled = true
        sceneView.showsStatistics = true
        // 启动用户交互
        sceneView.isUserInteractionEnabled = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        setUpLight()
        
        (ToolView.controller2 as! ModelTableViewController).fatherVC = self
        (ToolView.controller as! ModelTableViewController).fatherVC = self
        setGesture()
        setUI()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal

        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
    }

    func setUI(){
        
    }
    func changeHint(){
        if hintMessage.image == #imageLiteral(resourceName: "hint") {
          hintMessage.image = #imageLiteral(resourceName: "hint2")
        }else if hintMessage.image == #imageLiteral(resourceName: "hint2"){
            hintMessage.image = #imageLiteral(resourceName: "hint")
        }
        
    }
    func setGesture(){
        let tapRecognizerOne = UITapGestureRecognizer(target: self, action: #selector(ARApplicationViewController.tapped(tapRecognizer:)))
        sceneView.addGestureRecognizer(tapRecognizerOne)
    }
    func scaleCounting(){
        let standPoint = sceneView.hitTest(pointBelow, types: ARHitTestResult.ResultType.existingPlane).first?.worldTransform.position()
        let topPoint = sceneView.hitTest(pointAbove, types: ARHitTestResult.ResultType.existingPlane).first?.worldTransform.position()
        let cameraPoint = sceneView.session.currentFrame?.camera.transform.position()
        if standPoint != nil && topPoint != nil && cameraPoint != nil{
            print(standPoint)
            print(topPoint)
            print(cameraPoint)
            
            let a2 = standPoint?.minus(vector: cameraPoint!).module2()
            let b2 = topPoint?.minus(vector: cameraPoint!).module2()
            let c2 = topPoint?.minus(vector: standPoint!).module2()
            let ab2 = 2*sqrtf(a2!)*sqrtf(b2!)
            let cosc = (a2! + b2! - c2!) / (ab2)
            let angle1 = acos(cosc)
            
            let cgrund = SCNVector3.init((cameraPoint?.x)!, (standPoint?.y)!, (cameraPoint?.z)!)
            
            let a2_ = cgrund.minus(vector: cameraPoint!).module2()
            let b2_ = standPoint?.minus(vector: cameraPoint!).module2()
            let c2_ = standPoint?.minus(vector: cgrund).module2()
            let ab2_ = 2*sqrtf(a2_)*sqrtf(b2_!)
            let cosc_ = (a2_ + b2_! - c2_!) / (ab2_)
            let angle2 = acos(cosc_)
            let angleSum = angle1/2 + angle2
            
            print(angleSum)
            
            let scaleT = 2 * sqrtf(a2!) * sin(angle1/2)
//            let scaleB = cos(angleSum)
            let scaleB = Float(1.0)
            
            let scaleNeedDivideH = scaleT/scaleB
            
            placeModel(modelName: modelToPlace, position: standPoint!, scale: scaleNeedDivideH, angle:angleSum)
        }
       
        
        
    }
    func placeModel(modelName:String, position:SCNVector3, scale:Float, angle:Float){
        
        modelInScene.append(modelName)
        
        if let assetScene = SCNScene(named:modelName) {
            
            
            let node = assetScene.rootNode
            var TranScale = Float()
//            if angle <= Float.pi/6 {
//                TranScale = scale / node.boundingBox.max.x
//            }else{
//
//                TranScale = scale / node.boundingBox.max.y
//            }
            let scaleB = sqrtf(node.boundingBox.max.y * node.boundingBox.max.y + node.boundingBox.max.x * node.boundingBox.max.x) * cos(angle - atan(node.boundingBox.max.y / node.boundingBox.max.x))
            
            TranScale = scale / scaleB
            
            let action = SCNAction.scale(to: CGFloat(TranScale), duration: 0.5)
            
            node.transform = SCNMatrix4MakeScale(TranScale/10, TranScale/10, TranScale/10)
            
            node.runAction(action)
            node.position = position
            node.name = String(modelInScene.count - 1)
            sceneView.scene.rootNode.addChildNode(assetScene.rootNode)
            
            print("placed")
            
//            let ambientLightNode = SCNNode()
//            ambientLightNode.light = SCNLight()
//            ambientLightNode.light!.type = .ambient
//            ambientLightNode.light!.color = UIColor.darkGray
//            sceneView.scene.rootNode.addChildNode(ambientLightNode)
            
        }
        
        forbidPlace()
    }
    func readyToPlace(){
        changeHint()
        if sceneView.subviews.count == 0  {
            addLassoPad()
        }
        
    }
    func forbidPlace(){
        
        sceneView.subviews[0].removeFromSuperview()
        modelToPlace = ""
        changeHint()
    }
    func addLassoPad(){
        let lassoPad = LassoPadView()
        lassoPad.setColor(color: UIColor(displayP3Red: 89/255, green: 73/255, blue: 255/255, alpha: 1))
        lassoPad.frame = sceneView.frame
        lassoPad.brush = self.brushes[0]
        lassoPad.strokeWidth = 20
        lassoPad.backgroundColor = UIColor(displayP3Red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
        lassoPad.alpha = 0.5
        lassoPad.undoer = self.undoer
        lassoPad.isUserInteractionEnabled = true
        lassoPad.fatherCV = self
        sceneView.addSubview(lassoPad)
    }
    @objc func tapped(tapRecognizer:UITapGestureRecognizer){
        
        
        if tapRecognizer.state == UIGestureRecognizerState.ended{
            let sceneView = self.sceneView
            let hits = sceneView?.hitTest(tapRecognizer.location(in: tapRecognizer.view), options: nil) as! [SCNHitTestResult]

            if !hits.isEmpty{
                for hit in hits {
                    currentSelectedModel = (hit.node)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let estimate = self.sceneView.session.currentFrame?.lightEstimate
    
    }
    func setUpLight(){

        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
    }
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = Plane(withAnchor: anchor)
        planes[anchor.identifier] = plane
        hint = "hint2"
        node.addChildNode(plane)
        self.sceneView.debugOptions = []
    }
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        
        
        plane.update(anchor: anchor as! ARPlaneAnchor)
    }
    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        planes.removeValue(forKey: anchor.identifier)
    }
    
}
class ARView: ARSCNView {
    
}
class ToolView:UIView {
    var isFold = false
    func switchFoldState(){}
    var pageMenu:CAPSPageMenu?
    var controller:UIViewController?
    var controller2:UIViewController?
    override func awakeFromNib() {
      initTool()
    }
    func initTool(){
        layoutIfNeeded()
        setPageMenu()
        setUI()
    }
    func setPageMenu(){
        var controllerArray = [UIViewController]()
        controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "modelTableViewController")
        controller?.title = "已放置模型"
        (controller as! ModelTableViewController).mediaArray = []
        
        controller2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "modelTableViewController")
        
        controller2?.title = "我的收藏"
        
        controllerArray.append(controller2!)
        controllerArray.append(controller!)
        
        let parameters: [CAPSPageMenuOption] = [
            .useMenuLikeSegmentedControl(false),
            .menuItemSeparatorPercentageHeight(0.1),
            .scrollMenuBackgroundColor(UIColor.white),
            .menuItemSeparatorWidth (0),
            .selectionIndicatorColor(UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)),
            .selectedMenuItemLabelColor(UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)),
            .unselectedMenuItemLabelColor (UIColor(hue: 0, saturation: 0, brightness: 0.67, alpha: 1)),
            .menuHeight(60),
            .selectionIndicatorHeight(4),
            .menuItemFont(UIFont.boldSystemFont(ofSize: 20)),
            .menuItemWidthBasedOnTitleTextWidth(true),
            .menuItemWidth(100),
            .centerMenuItems(false)
        ]
        
        
        
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRect(origin: CGPoint(x: 0, y: 0), size: self.frame.size), pageMenuOptions: parameters)
        
        self.addSubview(pageMenu!.view)
        
    }
    func setUI(){
        self.layer.shadowOpacity = 0.16
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 6
    }
}

class MediaTableCell: UITableViewCell {
    var mediaAddress = ""
    var label = UILabel()
    var mediaView = UIView()
    
    
    override func awakeFromNib() {
        setVisual()
    }
    
    
    func addSCNView(withName:String){
        mediaAddress = withName
        let sceneView = SCNView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.frame.size.height, height: self.frame.size.height)))
        sceneView.backgroundColor = UIColor(displayP3Red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        let scene = SCNScene(named: withName)!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        
        
        // retrieve the SCNView
        
        // set the scene to the view
        sceneView.scene = scene
//        if let assetScene = SCNScene(named:withName) {
//            sceneView.scene?.rootNode.addChildNode(assetScene.rootNode)
//        }
        self.addSubview(sceneView)
    }
    func addImgView(){
        
    }
    func setVisual(){
        self.layer.cornerRadius = 10
    }
}

class ModelTableViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var fatherVC = ARApplicationViewController()
    
    var mediaArray = ["m1056.dae","m106.dae","m1056.dae","Menchi.dae"]
    
    @IBOutlet weak var mediaTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mediaTableView.delegate = self
        mediaTableView.dataSource = self
        //        mediaCollectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: "mediaCollectionCell")
        readRecord()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUI(){}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell = UICollectionViewCell()
        //        let sceneView = SCNView.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: cell.frame.size))
        //        print(indexPath.row)
        //        print(mediaArray[indexPath.row])
        //
        //        if let assetScene = SCNScene(named: "art.scnassets/" + mediaArray[indexPath.row]) {
        //            sceneView.scene?.rootNode.addChildNode(assetScene.rootNode)
        //        }
        //        cell.addSubview(sceneView)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaTableCell", for: indexPath) as! MediaTableCell
        
        cell.addSCNView(withName:addedPath(mediaArray[indexPath.item]))
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        print(indexPath.section)
        print(indexPath.item)
        fatherVC.modelToPlace = addedPath(mediaArray[indexPath.item])
    }
    func readRecord(){
        //从coredata取出收藏列表
        // 1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Favor")
        
        // 3
        do {
            let results = try managedContext.fetch(fetchRequest)
            let things = results as! [NSManagedObject]
            var array = [String]()
            for thing in things {
                array.append(thing.value(forKey: "modelName") as! String)
            }
            mediaArray = array
            mediaTableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
}

class LassoPadView: UIImageView {
    fileprivate var drawingState: DrawingState!
    var strokeColor:UIColor = UIColor.black
    
    var strokeWidth:CGFloat = 5
    var brush:BaseBrush?
    var undoer:UndoManager?
    var realImage:UIImage?
    var isBoardBeenDrawedOnce:Bool = false
    var cleanImage:UIImage?
    var pointBelow = CGPoint()
    var pointAbove = CGPoint()
    var fatherCV = ARApplicationViewController()
    var pointArray = [CGPoint]()
    
    convenience init() {
        self.init(frame:CGRect.zero)
        self.cleanImage = self.image
        
    }
    
    func deliverPoint(){
        fatherCV.pointBelow = self.pointBelow
        fatherCV.pointAbove = self.pointAbove
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        undoer?.beginUndoGrouping()
        
        if let brush = self.brush {
            
            brush.lastPoint = nil
            brush.beginPoint = touches.first?.location(in: self)
            pointArray.append(brush.beginPoint)
            brush.endPoint = brush.beginPoint
            self.drawingState = .began
            self.drawingImage()
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let brush = self.brush {
            
            brush.endPoint = touches.first?.location(in: self)
            pointArray.append(brush.endPoint)
            self.drawingState = .moved
            self.drawingImage()
            
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.drawingState = .ended
        self.drawingImage()
        undoer?.endUndoGrouping()
        isBoardBeenDrawedOnce = true
        findBelowAbovePoint()
    }
    func findBelowAbovePoint(){
        var pAbove = pointArray[0]
        var pBelow = pointArray[0]
        for each in pointArray {
            if each.y < pAbove.y {
                pAbove = each
            }
            if each.y > pBelow.y {
                pBelow = each
            }
        }
        fatherCV.pointAbove = pAbove
        fatherCV.pointBelow = pBelow
        print(pAbove)
        print(pBelow)
        
    }
    func drawingImage() {
        
        if let brush = self.brush {
            // 0.
            let undoImage = self.realImage
            // 1.
            UIGraphicsBeginImageContext(self.bounds.size)
            // 2.
            let context = UIGraphicsGetCurrentContext()
            UIColor.clear.setFill()
            UIRectFill(self.bounds)
            context?.setLineCap(.round)
            context?.setLineWidth(self.strokeWidth)
            context?.setStrokeColor(self.strokeColor.cgColor)
            // 3.
            if let realImage = self.realImage {
                realImage.draw(in: self.bounds)
            }
            // 4.
            brush.strokeWidth = self.strokeWidth
            brush.drawInContext(context!);
            context?.strokePath()
            // 5.
            let previewImage = UIGraphicsGetImageFromCurrentImageContext()
            if self.drawingState == .ended || brush.supportedDrawing() {
                self.realImage = previewImage
            }
            UIGraphicsEndImageContext()
            // 6.
            self.image = previewImage;
            brush.lastPoint = brush.endPoint
            if isBoardBeenDrawedOnce == true{
                
                undoer?.registerUndo(withTarget: self, handler: {targetSelf in
                    targetSelf.undoImage(undoImage!, yImage: previewImage!)
                })
            }
            
        }
    }
    override var canBecomeFirstResponder : Bool {
        return true
    }
    func undoableDrawing(){
        //        self.undoer?.prepareWithInvocationTarget(self).drawingImage()
        //        self.undoer?.setActionName("Draw")
        self.drawingImage()
    }
    func undoImage(_ xImage:UIImage,yImage:UIImage){
        
        self.image = xImage
        self.realImage = xImage
        undoer?.registerUndo(withTarget: self, handler: {targetSelf in
            targetSelf.redoImage(yImage)
        })
    }
    func redoImage(_ xImage:UIImage){
        self.image = xImage
        self.realImage = xImage
        
    }
    func setColor(color:UIColor){
        self.strokeColor = color
    }
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}

func addedPath(_ forString:String) -> String{
    if forString.hasPrefix("art.scnassets/") {
        return forString
    } else {
        return "art.scnassets/" + forString
    }
    
}
extension SCNVector3 {
    func minus(vector:SCNVector3) -> SCNVector3 {
        return SCNVector3(x: self.x - vector.x, y: self.y - vector.y, z: self.z - vector.z)
    }
    func times(vector:SCNVector3) -> Float {
        let sumX = self.x * vector.x
        let sumY = self.y * vector.y
        let sumZ = self.z * vector.z
        return sumX + sumY + sumZ
    }
    func module() -> Float{
        let sumX = self.x * self.x
        let sumY = self.y * self.y
        let sumZ = self.z * self.z
        let sum = sumX + sumY + sumZ
        let module = sqrtf(sum)
        return module
    }
    func module2() -> Float{
        let sumX = self.x * self.x
        let sumY = self.y * self.y
        let sumZ = self.z * self.z
        let sum = sumX + sumY + sumZ
        let module = sum
        return module
    }
}

