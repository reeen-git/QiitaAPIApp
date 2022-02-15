//
//  ViewController.swift
//  QiitaAPIApp
//
//  Created by 高橋蓮 on 2022/02/14.
//

import UIKit

//受け取った値をswiftの形にするために構造体を用意する
struct Qiita: Codable {
    let title: String
    let createdAt: String
    let user: User //以下で用意したUserの型を使用して中身を取り出す
    
    enum CodingKeys: String, CodingKey { //_(アンスコ)はswiftでは基本使わないのでenumを使ってる
        case title = "title"
        case createdAt = "created_at"
        case user = "user"
    }
}

//上で取得したuserはその中にまだ情報があるのでそれを取得するための構造体も用意する
struct User: Codable {
    let name: String
    let profileImageUrl: String
    
    enum CodingKeys: String, CodingKey { //CodingKeyはdecodeとencodeに必要なキーを定義するとき使うプロトコルである。
        case name = "name"
        case profileImageUrl = "profile_image_url"
    }
}

class ViewController: UIViewController {
    
    private let cellId = "cellId"
    private var qiitas = [Qiita]()
    
    let tableView: UITableView = {
        let tv = UITableView()
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.frame.size = view.frame.size
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight=50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(QiitaTableViewCell.self, forCellReuseIdentifier: cellId)
        
        navigationItem.title = "Qiitaの記事"
        
        getQiitaAPI()
    }
    
    
    private func getQiitaAPI() {
        //guard letとすることで、取得できなかった場合処理を抜けられる
        guard let url = URL(string: "https://qiita.com/api/v2/items?page=1&per_page=20") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, err) in
            if let err = err { //errだった場合に実行される
                print("情報の取得に失敗しました。：", err)
                return //errなので処理を止めてる
            }
            
            if let data = data { //dataがあった場合に実行される
                do { //do catchで書くことでエラーが出ても適切に処理される
//                    jsonの形でとってきてる
//                    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                    let qiita = try JSONDecoder().decode([Qiita].self, from: data)
                    self.qiitas = qiita
                    DispatchQueue.main.async {
                        self.tableView.reloadData() //この処理はmainスレッドで必ず行わなくてはいけないのでDispatchQueueの中に書いてる
                    }
//                    print("json: ", json)
                } catch(let err) {
                 print("情報の取得に失敗しました", err)
                }
            }
        }
        task.resume()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return qiitas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! QiitaTableViewCell
        cell.qiita = qiitas[indexPath.row]
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 5)
        return cell
    }
    
}

class QiitaTableViewCell: UITableViewCell {
    
    var qiita: Qiita? {
        didSet {
            bodyTextLabel.text = qiita?.title
            let url = URL(string: qiita?.user.profileImageUrl ?? "")
            do {
                let data = try Data(contentsOf: url!)
                let image = UIImage(data: data)
                userImageView.image = image
            }catch let err {
                print("Error : \(err.localizedDescription)")
            }
        }
    }
    
    let userImageView: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.clipsToBounds = true
        return iv
    }()
    
    let bodyTextLabel: UILabel = {
        let label = UILabel()
        label.text = "something in here"
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(userImageView)
        addSubview(bodyTextLabel)
        [
            userImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 50),
            userImageView.heightAnchor.constraint(equalToConstant: 50),
            
            bodyTextLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 20),
            bodyTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        
            ].forEach{ $0.isActive = true }
        
        userImageView.layer.cornerRadius = 50 / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

