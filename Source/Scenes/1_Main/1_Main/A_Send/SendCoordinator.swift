//
//  SendCoordinator.swifr
//  Zupreme
//
//  Created by Alexander Cyon on 2018-09-08.
//  Copyright © 2018 Open Zesame. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Zesame

// MARK: - SendCoordinator
final class SendCoordinator: BaseCoordinator<SendCoordinator.Step> {
    enum Step {
        case finish
    }

    private let useCaseProvider: UseCaseProvider
    private let deepLinkedTransactionSubject: BehaviorSubject<Transaction?>

    init(navigationController: UINavigationController, useCaseProvider: UseCaseProvider, prefilledTransaction: Transaction?) {
        self.useCaseProvider = useCaseProvider
        deepLinkedTransactionSubject = BehaviorSubject<Transaction?>(value: prefilledTransaction)
        super.init(navigationController: navigationController)
    }

    override func start() {
        toPrepareTransaction()
    }
}

extension SendCoordinator {
    func prefillTranscaction(_ transaction: Transaction) {
        guard isTopmost(scene: PrepareTransaction.self) else { return }
        deepLinkedTransactionSubject.onNext(transaction)
    }
}


// MARK: - Navigate
private extension SendCoordinator {
    func toPrepareTransaction() {
        let viewModel = PrepareTransactionViewModel(
            walletUseCase: useCaseProvider.makeWalletUseCase(),
            transactionUseCase: useCaseProvider.makeTransactionsUseCase(),
            deepLinkedTransaction: deepLinkedTransactionSubject.asDriverOnErrorReturnEmpty().filterNil()
        )

        push(scene: PrepareTransaction.self, viewModel: viewModel) { [unowned self] userIntendsTo, _ in
            switch userIntendsTo {
            case .cancel: self.finish()
            case .signPayment(let payment): self.toSignPayment(payment)
            }
        }
    }

    func finish() {
        stepper.step(.finish)
    }

    func toSignPayment(_ payment: Payment) {
        let viewModel = SignTransactionViewModel(
            paymentToSign: payment,
            walletUseCase: useCaseProvider.makeWalletUseCase(),
            transactionUseCase: useCaseProvider.makeTransactionsUseCase()
        )

        push(scene: SignTransaction.self, viewModel: viewModel) { [unowned self] userDid, _ in
            switch userDid {
            case .sign(let transactionResponse):
                log.info("Doing nothing with tx with id \(transactionResponse.transactionIdentifier)")
                self.finish()
            }
        }
    }

//    // TODO extract this to its own type?
//    func toTransaction(viewTxDetailsFor transactionId: String) {
//        let baseURL = "https://dev-test-explorer.aws.z7a.xyz/"
//        guard let url = URL(string: "transactions/\(transactionId)", relativeTo: URL(string: baseURL)) else {
//            return log.error("failed to create url")
//        }
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//    }
}
