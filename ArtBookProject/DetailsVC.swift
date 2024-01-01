// Detayları gösteren ve yeni resim eklemeye izin veren ekranın kontrolcüsü.

import UIKit
import CoreData

class DetailsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    // Seçilen resmin adı ve id'si
    var chosenPainting = ""
    var chosenPaintingId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Eğer bir resim seçilmişse, detayları göster ve "Save" butonunu gizle.
        if chosenPainting != "" {
            saveButton.isHidden = true
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            
            let idString = chosenPaintingId?.uuidString
            
            // Seçilen resmin id'sine göre fetch işlemi.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        // CoreData'den çekilen detayları ekrana yerleştir.
                        if let name = result.value(forKey: "name") as? String {
                            nameText.text = name
                        }
                        if let artist = result.value(forKey: "artist") as? String {
                            artistText.text = artist
                        }
                        if let year = result.value(forKey: "year") as? Int {
                            yearText.text = String(year)
                        }
                        if let imageData = result.value(forKey: "image") as? Data {
                            let image = UIImage(data: imageData)
                            imageView.image = image
                        }
                    }
                }
            } catch {
                // Hata durumunda bir şey yapma (bu kısmı daha sonra doldurabilirsiniz).
            }
            
        } else {
            // Eğer yeni bir resim ekleniyorsa, "Save" butonunu göster ve etkinleştirme.
            saveButton.isHidden = false
            saveButton.isEnabled = false
        }
        
        // Klavye gizleme için gesture recognizer ekle.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        // Resme tıklanınca galeriyi açmak için gesture recognizer ekle.
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTapRecognizer)
    }
    
    @objc func selectImage() {
        // Galeriyi açmak için image picker'ı başlat.
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    // Galeriden fotoğraf seçildikten sonra bu fonksiyon çalışır.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Kullanıcının seçtiği resmi imageView'e yerleştir.
        imageView.image = info[.originalImage] as? UIImage
        // "Save" butonunu etkinleştir.
        saveButton.isEnabled = true
        self.dismiss(animated: true)
    }
    
    @objc func hideKeyboard(){
        // Klavyeyi gizle.
        view.endEditing(true)
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        // Yeni bir resim kaydetmek için CoreData'ye kaydet.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context)
        
        // Kullanıcının girdiği bilgileri CoreData'ye kaydet.
        newPainting.setValue(nameText.text!, forKey: "name")
        newPainting.setValue(artistText.text!, forKey: "artist")
        
        if let year = Int(yearText.text!) {
            newPainting.setValue(year, forKey: "year")
        }
        // Yeni bir id oluştur ve CoreData'ye kaydet.
        newPainting.setValue(UUID(), forKey: "id")
        
        // Resmi JPEG formatında veriye çevir ve kaydet.
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPainting.setValue(data, forKey: "image")
        
        do {
            // Değişiklikleri kaydet.
            try context.save()
            
        } catch {
            // Hata durumunda bir şey yapma (bu kısmı daha sonra doldurabilirsiniz).
            print("Error")
        }
        
        // Önceki sayfaya giderken "newData" mesajını gönder.
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        
        // Önceki sayfaya git.
        self.navigationController?.popViewController(animated: true)
    }
}
