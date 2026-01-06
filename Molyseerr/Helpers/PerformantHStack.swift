//
//  PerformantHStack.swift
//  Molyseerr
//
//  Optimized horizontal collection view for tvOS performance
//  Solves tvOS 18 _UIFocusRegionEvaluator bug by using UICollectionView instead of LazyHStack
//

import SwiftUI
import UIKit

/// Performant horizontal scroll container for tvOS
/// Uses UICollectionView under the hood to avoid SwiftUI LazyHStack performance issues on tvOS 18
struct PerformantHStack<Item: Identifiable & Hashable, Content: View>: UIViewRepresentable {

    let items: [Item]
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let content: (Item) -> Content

    init(
        items: [Item],
        itemWidth: CGFloat = 250,
        itemHeight: CGFloat = 375,
        spacing: CGFloat = 40,
        horizontalPadding: CGFloat = 60,
        verticalPadding: CGFloat = 40,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(HostingCell<Content>.self, forCellWithReuseIdentifier: "cell")

        // Critical for tvOS - allows focus to work properly
        collectionView.remembersLastFocusedIndexPath = true

        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        uiView.reloadData()
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: verticalPadding,
            leading: horizontalPadding,
            bottom: verticalPadding,
            trailing: horizontalPadding
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
        var parent: PerformantHStack

        init(_ parent: PerformantHStack) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return parent.items.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! HostingCell<Content>
            let item = parent.items[indexPath.item]
            cell.configure(with: parent.content(item))
            return cell
        }

        // Enable focus on tvOS
        func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            return true
        }
    }

    // MARK: - Hosting Cell

    private class HostingCell<Content: View>: UICollectionViewCell {
        private var hostController: UIHostingController<Content>?

        override func prepareForReuse() {
            super.prepareForReuse()
            hostController?.view.removeFromSuperview()
            hostController = nil
            // Reset focus effects
            transform = .identity
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 2
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupFocusEffect()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupFocusEffect()
        }

        private func setupFocusEffect() {
            // Initial shadow
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowOpacity = 0.2
            layer.shadowRadius = 2
            layer.masksToBounds = false
        }

        // CRITICAL: tvOS focus animation
        override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            super.didUpdateFocus(in: context, with: coordinator)

            coordinator.addCoordinatedAnimations({
                if self.isFocused {
                    // Scale up when focused (Apple TV+ style)
                    self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    self.layer.shadowOpacity = 0.5
                    self.layer.shadowRadius = 10
                    self.layer.shadowOffset = CGSize(width: 0, height: 5)
                } else {
                    // Scale back to normal
                    self.transform = .identity
                    self.layer.shadowOpacity = 0.2
                    self.layer.shadowRadius = 2
                    self.layer.shadowOffset = CGSize(width: 0, height: 1)
                }
            }, completion: nil)
        }

        func configure(with view: Content) {
            hostController = UIHostingController(rootView: view)
            hostController?.view.backgroundColor = .clear

            if let hostView = hostController?.view {
                hostView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(hostView)

                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
        }
    }
}
