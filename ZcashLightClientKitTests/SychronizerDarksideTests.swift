//
//  SychronizerDarksideTests.swift
//  ZcashLightClientKit-Unit-Tests
//
//  Created by Francisco Gindre on 10/20/20.
//

import XCTest
@testable import ZcashLightClientKit
class SychronizerDarksideTests: XCTestCase {
    var seedPhrase = "still champion voice habit trend flight survey between bitter process artefact blind carbon truly provide dizzy crush flush breeze blouse charge solid fish spread" //TODO: Parameterize this from environment?
    
    let testRecipientAddress = "zs17mg40levjezevuhdp5pqrd52zere7r7vrjgdwn5sj4xsqtm20euwahv9anxmwr3y3kmwuz8k55a" //TODO: Parameterize this from environment
    
    let sendAmount: Int64 = 1000
    var birthday: BlockHeight = 663150
    let defaultLatestHeight: BlockHeight = 663175
    var coordinator: TestCoordinator!
    var syncedExpectation = XCTestExpectation(description: "synced")
    var sentTransactionExpectation = XCTestExpectation(description: "sent")
    var expectedReorgHeight: BlockHeight = 665188
    var expectedRewindHeight: BlockHeight = 665188
    var reorgExpectation: XCTestExpectation = XCTestExpectation(description: "reorg")
    
    var foundTransactions = [ConfirmedTransactionEntity]()
    override func setUpWithError() throws {
        
        coordinator = try TestCoordinator(
            seed: seedPhrase,
            walletBirthday: birthday,
            channelProvider: ChannelProvider()
        )
        try coordinator.reset(saplingActivation: 663150)
    }
    
    override func tearDownWithError() throws {
        NotificationCenter.default.removeObserver(self)
        try coordinator.stop()
        try? FileManager.default.removeItem(at: coordinator.databases.cacheDB)
        try? FileManager.default.removeItem(at: coordinator.databases.dataDB)
        try? FileManager.default.removeItem(at: coordinator.databases.pendingDB)
    }
   
    func testFoundTransactions() throws {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFoundTransactions(_:)), name: Notification.Name.synchronizerFoundTransactions, object: nil)
        
        try FakeChainBuilder.buildChain(darksideWallet: self.coordinator.service)
        let receivedTxHeight: BlockHeight = 663188
        
    
        try coordinator.applyStaged(blockheight: receivedTxHeight + 1)
        
        sleep(2)
        let preTxExpectation = XCTestExpectation(description: "pre receive")
        

        try coordinator.sync(completion: { (synchronizer) in
            
            preTxExpectation.fulfill()
        }, error: self.handleError)
        
        wait(for: [preTxExpectation], timeout: 5)
        
        XCTAssertEqual(self.foundTransactions.count, 2)
    }
    
    @objc func handleFoundTransactions(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let transactions = userInfo[SDKSynchronizer.NotificationKeys.foundTransactions] as? [ConfirmedTransactionEntity] else {
            return
        }
        self.foundTransactions.append(contentsOf: transactions)
    }
    
    func handleError(_ error: Error?) {
        _ = try? coordinator.stop()
        guard let testError = error else {
            XCTFail("failed with nil error")
            return
        }
        XCTFail("Failed with error: \(testError)")
    }
}
