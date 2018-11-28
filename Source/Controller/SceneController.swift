//
//  SceneController.swift
//  Zupreme
//
//  Created by Alexander Cyon on 2018-09-08.
//  Copyright © 2018 Open Zesame. All rights reserved.
//

import UIKit

import RxSwift

/// The "Single-Line Controller" base class
class SceneController<View: ContentView>: AbstractController where View.ViewModel.Input.FromController == ControllerInput {
    typealias ViewModel = View.ViewModel

    private let bag = DisposeBag()
    private let viewModel: ViewModel

    // MARK: - Initialization
    required init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder) { interfaceBuilderSucks }

    deinit {
        log.verbose("💣 \(type(of: self))")
    }

    // MARK: View Lifecycle
    override func loadView() {
        view = View()
        view.backgroundColor = .white
        // We should not use autolayout here, but this works.
        view.bounds = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let titled = self as? TitledScene, case let sceneTitle = titled.sceneTitle, !sceneTitle.isEmpty {
            self.title = sceneTitle
        }
        if let rightButtonMaker = self as? RightBarButtonContentMaking {
            rightButtonMaker.setRightBarButton(for: self)
        }

        if let leftButtonMaker = self as? LeftBarButtonContentMaking {
            leftButtonMaker.setLeftBarButton(for: self)
        }
    }
}

// MARK: Private
private extension SceneController {

    func setup() {
        bindViewToViewModel()
        edgesForExtendedLayout = .bottom
    }

    // swiftlint:disable:next function_body_length
    func makeAndSubscribeToInputFromController() -> ControllerInput {
        let titleSubject = PublishSubject<String>()
        let leftBarButtonContentSubject = PublishSubject<BarButtonContent>()
        let rightBarButtonContentSubject = PublishSubject<BarButtonContent>()
        let toastSubject = PublishSubject<Toast>()

        bag <~ [
            titleSubject.asDriverOnErrorReturnEmpty().do(onNext: { [unowned self] in
                self.title = $0
            }).drive(),

            toastSubject.asDriverOnErrorReturnEmpty().do(onNext: { [unowned self] in
                $0.present(using: self)
            }).drive(),

            leftBarButtonContentSubject.asDriverOnErrorReturnEmpty().do(onNext: { [unowned self] in
                self.setLeftBarButtonUsing(content: $0)
            }).drive(),

            rightBarButtonContentSubject.asDriverOnErrorReturnEmpty().do(onNext: { [unowned self] in
                self.setRightBarButtonUsing(content: $0)
            }).drive()
        ]
        return ControllerInput(
            viewDidLoad: rx.viewDidLoad,
            viewWillAppear: rx.viewWillAppear,
            viewDidAppear: rx.viewDidAppear,
            leftBarButtonTrigger: leftBarButtonSubject.asDriverOnErrorReturnEmpty(),
            rightBarButtonTrigger: rightBarButtonSubject.asDriverOnErrorReturnEmpty(),
            titleSubject: titleSubject,
            leftBarButtonContentSubject: leftBarButtonContentSubject,
            rightBarButtonContentSubject: rightBarButtonContentSubject,
            toastSubject: toastSubject
        )
    }

    func bindViewToViewModel() {
        guard let contentView = view as? View else { return }

        let inputFromView = contentView.inputFromView
        let inputFromController = makeAndSubscribeToInputFromController()

        let input = ViewModel.Input(fromView: inputFromView, fromController: inputFromController)

        // Transform input from view and controller into output used to update UI
        // Navigatoin logic is handled by the Coordinator listening to navigation
        // steps in passed to the ViewModels `navigator` (`Stepper`).
        let output = viewModel.transform(input: input)

        // Update UI, dispose the array of `Disposable`s
        contentView.populate(with: output).forEach { $0.disposed(by: bag) }
    }
}