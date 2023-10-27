//
//  RoomMainRootView.swift
//  TUIRoomKit
//
//  Created by aby on 2022/12/27.
//  Copyright © 2022 Tencent. All rights reserved.
//

import Foundation

protocol RoomMainViewFactory {
    func makeBottomView() -> BottomView
    func makeTopView() -> TopView
    func makeVideoSeatView() -> UIView
    func makeRaiseHandNoticeView() -> UIView
    func makeMuteAudioButton() -> UIButton
}

struct RoomMainRootViewLayout { //横竖屏切换时的布局变化
    let bottomViewLandscapeSpace: Float = 0
    let bottomViewPortraitSpace: Float = 34.0
    let topViewLandscapeHight: Float = 75.0
    let topViewPortraitHight: Float = 61.0
    let videoSeatViewPortraitSpace: Float = 73.0
    let videoSeatViewLandscapeSpace: Float = 82.0
}

class RoomMainRootView: UIView {
    let viewModel: RoomMainViewModel
    let viewFactory: RoomMainViewFactory
    let layout: RoomMainRootViewLayout = RoomMainRootViewLayout()
    init(viewModel: RoomMainViewModel,
         viewFactory: RoomMainViewFactory) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
        super.init(frame: .zero)
    }
    private var currentLandscape: Bool = isLandscape
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var topView: TopView = {
        return viewFactory.makeTopView()
    }()
    
    lazy var videoSeatView: UIView = {
        return viewFactory.makeVideoSeatView()
    }()
    
    lazy var bottomView: BottomView = {
        return viewFactory.makeBottomView()
    }()
    
    lazy var raiseHandNoticeView: UIView = {
        return viewFactory.makeRaiseHandNoticeView()
    }()
    
    lazy var muteAudioButton: UIButton = {
        return viewFactory.makeMuteAudioButton()
    }()
    
    // MARK: - view layout
    private var isViewReady: Bool = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else { return }
        backgroundColor = UIColor(0x0F1014)
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        isViewReady = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard currentLandscape != isLandscape else { return }
        setupRootViewOrientation(isLandscape: isLandscape)
        viewModel.setResolutionMode()
        currentLandscape = isLandscape
    }
    
    func constructViewHierarchy() {
        addSubview(videoSeatView)
        addSubview(topView)
        addSubview(bottomView)
        addSubview(muteAudioButton)
        addSubview(raiseHandNoticeView)
    }
    
    func activateConstraints() {
        setupRootViewOrientation(isLandscape: isLandscape)
        raiseHandNoticeView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView.snp.top).offset(-15)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.width.equalTo(300)
        }
        muteAudioButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    private func bindInteraction() {
        muteAudioButton.transform = CGAffineTransform(translationX: 0, y: kScreenHeight)
        viewModel.viewResponder = self
        viewModel.applyConfigs()
        perform(#selector(hideToolBar),with: nil,afterDelay: 3.0)
    }
    
    func setupRootViewOrientation(isLandscape: Bool) {
        videoSeatView.snp.remakeConstraints { make in
            if isLandscape {
                make.leading.equalTo(layout.videoSeatViewLandscapeSpace)
                make.trailing.equalTo(-layout.videoSeatViewLandscapeSpace)
                make.top.bottom.equalToSuperview()
            } else {
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(layout.videoSeatViewPortraitSpace)
                make.bottom.equalTo(-layout.videoSeatViewPortraitSpace)
            }
        }
        topView.snp.remakeConstraints() { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading)
            make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing)
            if isLandscape {
                make.height.equalTo(layout.topViewLandscapeHight)
            } else {
                make.height.equalTo(layout.topViewPortraitHight)
            }
        }
        bottomView.snp.remakeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading)
            make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing)
            make.height.equalTo(bottomView.isUnfold ? 130.scale375() : 60.scale375())
            if isLandscape {
                make.bottom.equalToSuperview().offset(-layout.bottomViewLandscapeSpace)
            } else {
                make.bottom.equalToSuperview().offset(-layout.bottomViewPortraitSpace)
            }
        }
        topView.updateRootViewOrientation(isLandscape: isLandscape)
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        debugPrint("deinit \(self)")
    }
}

extension RoomMainRootView: RoomMainViewResponder {
    func updateMuteAudioButton(isSelected: Bool) {
        muteAudioButton.isSelected = isSelected
    }
    
    func showSelfBecomeRoomOwnerAlert() {
        let alertVC = UIAlertController(title: .haveBecomeMasterText,
                                        message: nil,
                                        preferredStyle: .alert)
        let sureAction = UIAlertAction(title: .alertOkText, style: .cancel) { _ in
        }
        alertVC.addAction(sureAction)
        RoomRouter.shared.presentAlert(alertVC)
    }
    
    func makeToast(text: String) {
        RoomRouter.makeToastInCenter(toast: text, duration: 1)
    }
    
    private func showToolBar() {
        topView.alpha = 1
        bottomView.alpha = 1
        topView.isHidden = false
        bottomView.isHidden = false
        hideMuteAudioButton()
    }
    
    @objc private func hideToolBar() {
        topView.alpha = 0
        bottomView.alpha = 0
        topView.isHidden = true
        bottomView.isHidden = true
        showMuteAudioButton()
    }
    
    private func showMuteAudioButton() {
        UIView.animate(withDuration: 0.3) { [weak self] () in
            guard let self = self else { return }
            self.muteAudioButton.transform = .identity
        } completion: { _ in
        }
    }
    
    private func hideMuteAudioButton() {
        muteAudioButton.transform = CGAffineTransform(translationX: 0, y: kScreenHeight)
    }
    
    func changeToolBarHiddenState() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideToolBar), object: nil)
        if topView.isHidden {
            showToolBar()
            perform(#selector(hideToolBar),with: nil,afterDelay: 3.0)
        } else if !bottomView.isUnfold {
            hideToolBar()
        }
    }
    
    func setToolBarDelayHidden(isDelay: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideToolBar), object: nil)
        guard !bottomView.isUnfold, isDelay else { return }
        perform(#selector(hideToolBar),with: nil,afterDelay: 3.0)
    }
}

private extension String {
    static var alertOkText: String {
        localized("TUIRoom.ok")
    }
    static var haveBecomeMasterText: String {
        localized("TUIRoom.have.become.master")
    }
}
