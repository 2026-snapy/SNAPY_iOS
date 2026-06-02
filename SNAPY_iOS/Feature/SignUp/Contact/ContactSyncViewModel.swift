//
//  ContactSyncViewmodel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 6/2/26.
//


//
//  ContactSyncViewModel.swift
//  SNAPY_iOS
//
//  Separated from ContactSyncView.swift
//

import Foundation
@preconcurrency import Contacts
import Combine

@MainActor
final class ContactSyncViewModel: ObservableObject {
    @Published var synced = false
    @Published var isSyncing = false
    @Published var contactUsers: [ContactUserData] = []
    @Published var requestedHandles: Set<String> = []

    // MARK: - 친구 요청

    func sendFriendRequest(handle: String) {
        requestedHandles.insert(handle)
        Task {
            do {
                try await FriendService.shared.sendRequest(handle: handle)
            } catch {
                requestedHandles.insert(handle)
            }
        }
    }

    // MARK: - 연락처 동기화

    func requestContactAccess(onDenied: @escaping () -> Void) {
        isSyncing = true
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, _ in
            if granted {
                let phones = self?.fetchAllPhoneNumbers(store: store) ?? []
                Task { @MainActor [weak self] in
                    do {
                        let contacts = try await FriendService.shared.syncContacts(phones: phones)
                        let handles = contacts.map { $0.handle }
                        UserDefaults.standard.set(handles, forKey: "contactSyncedHandles")
                        self?.contactUsers = contacts
                        self?.isSyncing = false
                        self?.synced = true
                    } catch {
                        self?.isSyncing = false
                        self?.synced = true
                    }
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.isSyncing = false
                    onDenied()
                }
            }
        }
    }

    nonisolated private func fetchAllPhoneNumbers(store: CNContactStore) -> [String] {
        let keys = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var phones: [String] = []
        try? store.enumerateContacts(with: request) { contact, _ in
            for number in contact.phoneNumbers {
                let cleaned = number.value.stringValue
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "+82", with: "0")
                phones.append(cleaned)
            }
        }
        return phones
    }
}
