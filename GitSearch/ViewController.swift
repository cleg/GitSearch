//
//  ViewController.swift
//  GitSearch
//
//  Created by Paul Dmitryev on 24.12.2020.
//

import UIKit

class ViewController: UIViewController {
    private let requestMaker: RequestMaker = DefaultRequestMaker()

    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.translatesAutoresizingMaskIntoConstraints = false

        return bar
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false

        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
        ])

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        searchBar.delegate = self
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }

        let request = Request.search(searchText)

        requestMaker.perform(request: request) { [weak self] (response: Result<ReposSearchResponse, Error>) in
            switch response {
            case let .failure(error):
                print("!!! \(error)")
            case let .success(data):
                let repos = data.items
                print("!!! \(repos.count)")
                print("!!! \(repos.first)")
            }
        }
    }
}
