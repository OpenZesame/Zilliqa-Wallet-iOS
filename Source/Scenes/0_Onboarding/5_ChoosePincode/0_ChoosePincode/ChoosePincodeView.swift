// 
// MIT License
//
// Copyright (c) 2018-2019 Open Zesame (https://github.com/OpenZesame)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit
import RxSwift

final class ChoosePincodeView: ScrollableStackViewOwner {

    private lazy var inputPincodeView           = InputPincodeView()
    private lazy var pinOnlyLocksAppTextView    = UITextView()
    private lazy var doneButton                 = UIButton()

    lazy var stackViewStyle: UIStackView.Style = [
        inputPincodeView,
        pinOnlyLocksAppTextView,
        doneButton
    ]

    override func setup() {
        setupSubviews()
    }
}

extension ChoosePincodeView: ViewModelled {
    typealias ViewModel = ChoosePincodeViewModel

    var inputFromView: InputFromView {
        return InputFromView(
            pincode: inputPincodeView.rx.pincode.asDriver(),
            doneTrigger: doneButton.rx.tap.asDriver()
        )
    }

    func populate(with viewModel: ChoosePincodeViewModel.Output) -> [Disposable] {
        return [
            viewModel.inputBecomeFirstResponder --> inputPincodeView.rx.becomeFirstResponder,
            viewModel.isDoneButtonEnabled       --> doneButton.rx.isEnabled
        ]
    }
}

private typealias € = L10n.Scene.ChoosePincode
private extension ChoosePincodeView {
    func setupSubviews() {
        pinOnlyLocksAppTextView.withStyle(.nonSelectable) {
            $0.text(€.Text.pincodeOnlyLocksApp).textColor(.silverGrey)
        }

        doneButton.withStyle(.primary) {
            $0.title(€.Button.done)
                .disabled()
        }
    }
}
