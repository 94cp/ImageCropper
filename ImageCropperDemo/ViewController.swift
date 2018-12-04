//
//  ViewController.swift
//  ImageCropperDemo
//
//  Created by chen p on 2018/11/21.
//  Copyright © 2018 chenp. All rights reserved.
//

import UIKit
import ImageCropper
import Photos

class ViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var images: [UIImage] = []
    let imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.requestAuthorization({ (status) in
        })
        collectionView.delegate = self
        collectionView.dataSource = self
        
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        
        activityIndicator.hidesWhenStopped = true
    }
    
    private func cropFaces() {
        guard let image = imageView.image else { return }
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            image.detector.crop(type: .face, padding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)) { result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success(let cropImageResults):
                        self?.images = cropImageResults.map { return $0.image }
                        self?.collectionView.reloadData()
                    case .notFound(let image, _):
                        self?.images = [image]
                        self?.collectionView.reloadData()
                        print("Not Found")
                    case .failure(let image, _, let error):
                        self?.images = [image]
                        self?.collectionView.reloadData()
                        print(error.localizedDescription)
                    }
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    @IBAction private func changeImageTapped(_ sender: UIButton) {
        self.present(imagePickerController, animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.image = images[indexPath.row]
        return cell
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.images = []
        self.collectionView.reloadData()
        
        let chosenImage = info[.originalImage] as! UIImage
        imageView.image = chosenImage
        picker.dismiss(animated: true, completion: nil)
        cropFaces()
    }
}
