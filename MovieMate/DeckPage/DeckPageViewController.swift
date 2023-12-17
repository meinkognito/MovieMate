//
//  DeckPageViewController.swift
//  MovieMate
//
//  Created by denis.beloshitsky on 30.10.2023.
//

import Combine
import Shuffle_iOS
import SnapKit
import UIKit

final class DeckPageViewController: UIViewController {
    private let deckView = SwipeCardStack()
    private let dataSource = DeckPageDataSource()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        super.init(nibName: nil, bundle: nil)
        dataSource.stack = deckView
        dataSource.vc = self
        deckView.dataSource = dataSource
        deckView.delegate = self

        dataSource.$movies
            .receive(on: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .sink { [weak self] _ in
                self?.deckView.reloadData()
            }.store(in: &cancellables)

        ApiClient.shared.$lobbyInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleStateChanged($0)
            }.store(in: &cancellables)
    }

    private func handleStateChanged(_ info: LobbyInfo?) {
        guard let info else { return }

        switch info.appState {
        case .finished:
            Router.shared.navigate(in: self.navigationController,
                                   to: .resultPage(info.matchedMovie != nil ? .good : .bad),
                                   makeRoot: true)
        case .choosingMoviesMatchError:
            Router.shared.navigate(in: self.navigationController,
                                   to: .resultPage(.bad),
                                   makeRoot: true)
        case .choosingMoviesTimeout:
            Router.shared.navigate(in: self.navigationController, to: .welcomePage, makeRoot: true)
        default:
            break
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(deckView)
        deckView.cardStackInsets = .zero
        deckView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

extension DeckPageViewController: SwipeCardStackDelegate {
    func cardStack(_ cardStack: SwipeCardStack, didSwipeCardAt index: Int, with direction: SwipeDirection) {
        guard let movie = dataSource.movies[safe: index], direction == .right else { return }
        Task {
            await ApiClient.shared.like(movie: movie)
        }
    }

    func cardStack(_ cardStack: SwipeCardStack, didUndoCardAt index: Int, from direction: SwipeDirection) {
        guard let movie = dataSource.movies[safe: index], direction == .right else { return }
        Task {
            await ApiClient.shared.undoLike(movie: movie)
        }
    }

    func didSwipeAllCards(_ cardStack: SwipeCardStack) {
        Task {
            await ApiClient.shared.notifyEmpty()
        }
    }
}
