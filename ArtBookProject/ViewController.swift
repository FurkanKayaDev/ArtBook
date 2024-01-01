//
//  ViewController.swift
//  ArtBookProject
//
//  Created by Furkan Kaya on 1.01.2024.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPainting = ""
    var selectedPaintingId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // sağ üste add butonu ekleme ve navigation ekleme
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData()
    }
    // sayfa yüklenirken çalışacak kod
    override func viewWillAppear(_ animated: Bool) {
        // sayfa yüklenirken diğer sayfadan gelen mesaj kontrol edilir. Eğer mesaj "newData" ise getData fonksiyonunu çalıştırır
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newData"), object: nil)
    }
    
    // Yeni bir veri eklenince bu fonksiyon çağrılır.
    @objc func getData(){
        // Tekrar getData işlemini çalıştırdığımızda aynı verilerin tekrar tekrar gözükmemesi için temizleme işlemi yapılır.
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        // CoreData bağlantısı
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Lokaldeki "Paintings" verilerini getir.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            // Lokalden çekilen verileri results içine at.
            let results = try context.fetch(fetchRequest)
            
            if results.count > 0 {
                // Her bir sonuca ayrı ayrı bak.
                for result in results as! [NSManagedObject] {
                    // "name" key'ine sahip verileri ekle.
                    if let name = result.value(forKey: "name") as? String {
                        self.nameArray.append(name)
                    }
                    // "id" key'ine sahip verileri ekle.
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    // TableView'i güncelle.
                    self.tableView.reloadData()
                }
            }
        } catch{
            print("Error fetching data from CoreData")
        }
    }
    
    
    @objc func addButtonClicked () {
        selectedPainting = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsVC
            destinationVC.chosenPainting = selectedPainting
            destinationVC.chosenPaintingId = selectedPaintingId
        }
    }
    
    // TableView'da bir hücre seçildiğinde bu fonksiyon çağrılır.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Seçilen resmin adını ve id'sini değişkenlere ata.
        selectedPainting = nameArray[indexPath.row]
        selectedPaintingId = idArray[indexPath.row]
        // DetailsVC'ye geçiş yap.
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    
    // TableView'da bir hücre silindiğinde bu fonksiyon çağrılır.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // CoreData bağlantısı
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Silinecek resmin id'sini al.
            let idString = idArray[indexPath.row].uuidString
            
            // Silinecek resmi bulmak için NSFetchRequest oluştur.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            // id = %@, idString kısmı id si idStringe eşit olanı bul demek
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                // NSFetchRequest ile silinecek resmi bul.
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    // Bulunan resmi sil.
                    for result in results as! [NSManagedObject] {
                        context.delete(result)
                        nameArray.remove(at: indexPath.row)
                        idArray.remove(at: indexPath.row)
                        self.tableView.reloadData()
                        
                        // Değişiklikleri kaydet.
                        do {
                            try context.save()
                        } catch {
                            print("Error saving context after deletion")
                        }
                        break
                    }
                }
            } catch {
                print("Error fetching data for deletion from CoreData")
            }
        }
    }
}
