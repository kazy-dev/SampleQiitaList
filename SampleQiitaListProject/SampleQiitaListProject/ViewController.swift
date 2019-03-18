//
//  ViewController.swift
//  SampleQiitaListProject
//
//  Created by Yoshikazu on 2019/03/18.
//  Copyright © 2019 YoshikazuIshii. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    private var articles: [Article]?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(), style: .grouped)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print(tableView)
        view.addSubview(tableView)
        
        getQiitaList()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    private func getQiitaList() {
        let url = "https://qiita.com/api/v2/items"
        
        guard var urlComponents = URLComponents(string: url) else {
            return
        }
        //50件取得する
        urlComponents.queryItems = [
            URLQueryItem(name: "per_page", value: "50"),
        ]
        //urlComponents.string: "https://qiita.com/api/v2/items?per_page=50"
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!) { [unowned self] data, response, error in
            
            guard let jsonData = data else {
                return
            }
            
            //今回の処理には関係ないが一応。
            if let httResponse = response as? HTTPURLResponse {
                print(httResponse.statusCode)
            }
            //レスポンスのバイナリデータがJSONとして解釈できる場合、JSONSerializationクラスのメソッドを使って Data型 -> Any型　に変換できる。
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                
                //今回のレスポンスはJSONの配列なので Any -> [Any] -> [String: Any] とキャストし、Articleのインスタンスを生成した。
                guard let jsonArray = jsonObject as? [Any] else {
                    return
                }
                
                let articles = jsonArray.compactMap { $0 as? [String: Any] }.map { Article($0) }
                debugPrint(articles)
                DispatchQueue.main.async { [unowned self] in
                    self.articles = articles
                    self.tableView.reloadData()
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
        //戻り値のURLSessionDataTaskクラスのresume()メソッドを実行すると通信が開始される。
        task.resume()
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let articles = self.articles else {
            return
        }
        let article = articles[indexPath.row]
        if let url = URL(string: article.url) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let articles = self.articles else {
            return UITableViewCell()
        }
        let article = articles[indexPath.row]
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "tableViewCell")
        cell.textLabel?.text = article.title + "\n" + article.userId
        cell.detailTextLabel?.text = article.userId
        
        return cell
    }
}

struct Article {
    var title: String = ""
    var userId: String = ""
    var url: String = ""
    
    init(_ json: [String: Any]) {
        
        if let title = json["title"] as? String {
            self.title = title
        }
        
        if let user = json["user"] as? [String: Any] {
            if let userId = user["id"] as? String {
                self.userId = userId
            }
        }
        
        if let url = json["url"] as? String {
            self.url = url
        }
    }
}

