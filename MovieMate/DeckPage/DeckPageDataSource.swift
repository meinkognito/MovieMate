//
//  DeckPageDataSource.swift
//  MovieMate
//
//  Created by denis.beloshitsky on 02.12.2023.
//

import Foundation
import Shuffle_iOS
import UIKit

final class DeckPageDataSource {
    weak var vc: UIViewController?
    weak var stack: SwipeCardStack?

    @Published
    private(set) var movies: [Movie] = []

    init() {
        initialLoad()
        setupModelActions()
    }

    private func initialLoad() {
        Task {
            do {
                movies = try await ApiClient.shared.getMovies()
            } catch {
                await AlertController.showAlert(vc: vc, error: error)
            }
        }
    }

    func setupModelActions() {
        MovieCardViewModel.onLikeTap = { [weak self] in
            self?.stack?.swipe(.right, animated: true)
        }

        MovieCardViewModel.onDislikeTap = { [weak self] in
            self?.stack?.swipe(.left, animated: true)
        }

        MovieCardViewModel.onUndoTap = { [weak self] in
            self?.stack?.undoLastSwipe(animated: true)
        }
    }
}

extension DeckPageDataSource: SwipeCardStackDataSource {
    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
        MovieCardFactory.makeCard(for: movies[safe: index])
    }

    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
        movies.count
    }
}

enum MovieCardFactory {
    static func makeCard(for movie: Movie?) -> SwipeCard {
        guard let movie else { return SwipeCard() }
        let view = MovieCardView()
        let viewModel = MovieCardViewModel(with: movie)
        view.configure(with: viewModel)

        let card = SwipeCard()
        card.swipeDirections = [.left, .right]
        card.content = view

        return card
    }
}
