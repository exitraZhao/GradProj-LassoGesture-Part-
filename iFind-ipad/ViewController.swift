//
//  ViewController.swift
//  iFind-ipad
//
//  Created by 赵一达 on 2018/5/10.
//  Copyright © 2018年 赵一达. All rights reserved.
//

import UIKit
import SceneKit
import CoreData

enum DrawingState {
    case began, moved, ended
}

class ViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate {
    
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var placeHolder: UIImageView!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    @IBOutlet weak var drawPadView: DrawPadView!
    @IBOutlet weak var padBackground: UIView!
    @IBOutlet weak var pencilButton: UIButton!
    @IBOutlet weak var eraserButton: UIButton!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBAction func pencil(_ sender: Any) {
        print("pencil")
//        drawPadView.usePencil()
        self.drawPadView.strokeWidth = 5
        self.drawPadView.brush = self.brushes[0]
    }
    @IBAction func eraser(_ sender: Any) {
        print("eraser")
//        drawPadView.useEraser()
//        self.drawPadView.clean()
        self.drawPadView.strokeWidth = 20
        self.drawPadView.brush = self.erasers[0]
    }
    @IBAction func search(_ sender: Any) {
        searchForResult()
    }
    @IBAction func undo(_ sender: Any) {
        undoer.undo()
    }
    @IBAction func redo(_ sender: Any) {
        undoer.redo()
    }
    @IBAction func clean(_ sender: Any) {
        self.drawPadView.clean()
    }
    var brushes = [PencilBrush()]
    var erasers = [EraserBrush()]
    var resultArray = [String]()
    var undoer = UndoManager()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        resultCollectionView.delegate = self
        resultCollectionView.dataSource = self
//        resultCollectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: "mediaCollectionCell")
        setUI()
        setDrawBoard()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setUI(){
        self.padBackground.layer.shadowOpacity = 0.16
        self.padBackground.layer.shadowColor = UIColor.black.cgColor
        self.padBackground.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.padBackground.layer.shadowRadius = 6
        indicator.isHidden = true
      
        self.mediaCollectionView.layer.shadowOpacity = 0.16
        self.mediaCollectionView.layer.shadowColor = UIColor.black.cgColor
        self.mediaCollectionView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.mediaCollectionView.layer.shadowRadius = 6
    }
    func setDrawBoard(){
        self.drawPadView.brush = self.brushes[0]
        self.drawPadView.undoer = self.undoer
    }
    func searchForResult(){
        
        
        resultArray = ["m820.dae","m821.dae","m823.dae","m827.dae"]
        placeHolder.isHidden = true
        indicator.isHidden = false
        indicator.startAnimating()
        let delay = DispatchTime.now() + DispatchTimeInterval.seconds(2)
        DispatchQueue.main.asyncAfter(deadline: delay){
            self.indicator.stopAnimating()
            self.indicator.isHidden = true
            self.mediaCollectionView.reloadData()
        }
    }
    func showResult(){
        
        mediaCollectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCollectionCell", for: indexPath) as! MediaCollectionCell
        
        cell.addSCNView(withName: addedPath(resultArray[indexPath.item]))
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMedia" {
            
            if let destination = segue.destination as? MediaViewController {
                destination.mediaArray = resultArray
                destination.mediaAddress = resultArray[mediaCollectionView.indexPathsForSelectedItems![0].item]
            }
            
        }
    }
}

class MediaViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var thing = [NSManagedObject]()
    
    @IBOutlet weak var animeBase: UIView!
    var anime = UIImageView()
    
    @IBOutlet weak var mediaOverView: UITableView!
    @IBOutlet weak var mediaSCNView: SCNView!
    @IBAction func add(_ sender: Any) {
        if isAdded {
            deleteData()
        }else{
            saveData()
        }
    }
    
    var mediaArray = [String]()
    var mediaAddress = ""{
        didSet{
//            if mediaAddress != "" {
//                setSCNView(addedPath(self.mediaAddress))
//            }
        }
    }
    var isAdded = false{
        didSet{
            if isAdded == true {
                self.anime.image = #imageLiteral(resourceName: "heart-1")
            }else{
                self.anime.image = #imageLiteral(resourceName: "heart")
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.mediaOverView.delegate = self
        self.mediaOverView.dataSource = self
        
        anime.image = #imageLiteral(resourceName: "heart")
        anime.frame = CGRect(x: 0, y: 0, width: 45, height: 38)
        animeBase.addSubview(anime)
        
        
        setSCNView(addedPath(mediaAddress))
        findId()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func setSCNView(_ name:String){
        mediaSCNView.backgroundColor = UIColor.white
        let scene = SCNScene(named: name)!
        
        let node = scene.rootNode.childNodes.first
        node?.geometry?.materials.first?.diffuse.contents = UIImage(named: addedPath("texture.jpg"))
        let action = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 1))
        node?.runAction(action)
        print(node?.position)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0 , y: 0.5, z: 1.4)
        
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
       
        mediaSCNView.scene = scene
    
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaArray.count
    }
    func saveData() {
        // 1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2
        let entity = NSEntityDescription.entity(forEntityName: "Favor",in: managedContext)
        let person = NSManagedObject.init(entity: entity!, insertInto: managedContext)
        
        // 3
        person.setValue(self.mediaAddress, forKey: "modelName")
        // 4
        do {
            try managedContext.save()
            thing.append(person)
            isAdded = true
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    func findId(){
        
        // 1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Favor")
        
        // 4
        do {
            let results = try managedContext.fetch(fetchRequest)
            thing = results as! [NSManagedObject]
            
            isAdded = false
            for each in thing {
                let addedName = addedPath(each.value(forKey: "modelName") as! String)
                if addedName == addedPath(mediaAddress) {
                    isAdded = true
                    break
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func deleteData(){
        
        // 1
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Favor")
        
        // 3
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            thing = results as! [NSManagedObject]
            
            for each in thing {
                let addedName = addedPath(each.value(forKey: "modelName") as! String)
                if addedName == addedPath(mediaAddress) {
                    managedContext.delete(each)
                    isAdded = false
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        do {
            try managedContext.save()
            
        } catch let err as NSError {
            print(err)
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaTableViewCell", for: indexPath) as! MediaTableCell
        cell.addSCNView(withName: addedPath(mediaArray[indexPath.item]))
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.mediaAddress = self.mediaArray[indexPath.item]
        setSCNView(addedPath(self.mediaAddress))
        findId()
    }
    func setUI(){
    }
}

class FavorViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
   
    var things = [NSManagedObject]()
    
    var mediaArray = [String]()
    
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = self
//        mediaCollectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: "mediaCollectionCell")
        
        readRecord()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        readRecord()
        self.mediaCollectionView.reloadData()
    }
    
    func setUI(){}
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
            things = results as! [NSManagedObject]
            var array = [String]()
            for thing in things {
                array.append(thing.value(forKey: "modelName") as! String)
            }
            mediaArray = array
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = UICollectionViewCell()
//        let sceneView = SCNView.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: cell.frame.size))
//        print(indexPath.row)
//        print(mediaArray[indexPath.row])
//
//        if let assetScene = SCNScene(named: "art.scnassets/" + mediaArray[indexPath.row]) {
//            sceneView.scene?.rootNode.addChildNode(assetScene.rootNode)
//        }
//        cell.addSubview(sceneView)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCollectionCell", for: indexPath) as! MediaCollectionCell
        
        cell.addSCNView(withName: addedPath(mediaArray[indexPath.item]))
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMedia" {
            
            if let destination = segue.destination as? MediaViewController {
                destination.mediaArray = mediaArray
                destination.mediaAddress = addedPath(mediaArray[mediaCollectionView.indexPathsForSelectedItems![0].item])
            }
            
        }
    }

}

class MediaCollectionView: UICollectionView {
    
    func setVisual(){}
}
class MediaCollectionCell: UICollectionViewCell {
    var mediaAddress = ""
    var label = UILabel()
    var mediaView = UIView()
    
    
    override func awakeFromNib() {
        setVisual()
    }
    
    
    func addSCNView(withName:String){
        mediaAddress = withName
        let sceneView = SCNView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: self.frame.size))
        
        sceneView.backgroundColor = UIColor(displayP3Red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        
        let scene = SCNScene(named: withName)!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0.5, z: 2)
        
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
        
        sceneView.scene = scene
      
        sceneView.layer.shadowOpacity = 0.16
        sceneView.layer.shadowColor = UIColor.black.cgColor
        sceneView.layer.shadowOffset = CGSize(width: 0, height: 13)
        sceneView.layer.shadowRadius = 6
        sceneView.layer.shouldRasterize = true
        
        self.addSubview(sceneView)
    }
    func addImgView(){
        
    }
    func setVisual(){
        self.backgroundColor = UIColor(displayP3Red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        self.layer.cornerRadius = 10
    }
}
class DrawPadView: UIImageView {
    fileprivate var drawingState: DrawingState!
    var strokeColor:UIColor = UIColor.black
    
    var strokeWidth:CGFloat = 5
    var brush:BaseBrush?
    var undoer:UndoManager?
    var realImage:UIImage?
    var isBoardBeenDrawedOnce:Bool = false
    var cleanImage:UIImage?
    
    convenience init() {
        self.init(frame:CGRect.zero)
        self.cleanImage = self.image
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        undoer?.beginUndoGrouping()
        
        if let brush = self.brush {
            
            brush.lastPoint = nil
            brush.beginPoint = touches.first?.location(in: self)
            brush.endPoint = brush.beginPoint
            self.drawingState = .began
            self.drawingImage()
            
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let brush = self.brush {
            
            brush.endPoint = touches.first?.location(in: self)
            self.drawingState = .moved
            self.drawingImage()
            
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.drawingState = .ended
        self.drawingImage()
        undoer?.endUndoGrouping()
        isBoardBeenDrawedOnce = true
        
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
    func clean(){
        self.image = self.cleanImage
        self.realImage = self.cleanImage
    }
    func usePencil(){}
    func useEraser(){}
    func setVisual(){}
    func setColor(color:UIColor){
        self.strokeColor = color
    }
}
