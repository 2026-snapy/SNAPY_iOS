//
//  NotificationRow.swift
//  SNAPY_iOS
//
//  Separated from NotificationView.swift
//

import SwiftUI
import Kingfisher

struct NotificationRow: View {
    let notification: NotificationData
    let message: AttributedString
    var onProfileTap: (() -> Void)? = nil
    var onContentTap: (() -> Void)? = nil

    private var isServiceNotification: Bool {
        notification.type == .albumPhotoUploadReminder
    }

    var body: some View {
        HStack(spacing: 12) {
            if isServiceNotification {
                Image(systemName: notificationIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.MainYellow)
                    .frame(width: 40, height: 40)
                    .background(Color(white: 0.2))
                    .clipShape(Circle())
            } else if let urlString = notification.senderProfileImageUrl,
                      let url = URL(string: urlString) {
                Button { onProfileTap?() } label: {
                    KFImage(url)
                        .resizable()
                        .placeholder { Color.customDarkGray }
                        .fade(duration: 0.2)
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }
            } else {
                Image("Profile_img")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }

            Button {
                onContentTap?()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if isServiceNotification {
                        Text("앨범에 사진을 올려주세요!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.textWhite)
                    } else {
                        HStack(spacing: 0) {
                            if let name = notification.senderUsername ?? notification.senderHandle {
                                Button {
                                    onProfileTap?()
                                } label: {
                                    Text(name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.textWhite)
                                }
                                .buttonStyle(.plain)

                                Text(messageSuffix)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textWhite)
                            }
                        }
                        .lineLimit(2)
                    }

                    Text(timeAgo(notification.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color.customGray300)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if !notification.read {
                Circle()
                    .fill(Color.mainYellow)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(notification.read ? Color.clear : Color.white.opacity(0.03))
    }

    private var messageSuffix: String {
        switch notification.type {
        case .storyLike:        return "님이 스토리에 좋아요를 눌렀습니다."
        case .feedLike:         return "님이 게시물에 좋아요를 눌렀습니다."
        case .friendRequest:    return "님이 친구 요청을 보냈습니다."
        case .friendAccepted:   return "님이 친구 요청을 수락했습니다."
        case .albumPublished:   return "님의 앨범이 발행되었습니다."
        case .newStory:         return "님이 새 스토리를 올렸습니다."
        case .feedComment:      return "님이 댓글을 남겼습니다."
        case .guestbookCreated: return "님이 방명록을 남겼습니다."
        case .albumPhotoUploadReminder: return ""
        }
    }

    private var notificationIcon: String {
        switch notification.type {
        case .storyLike, .feedLike:      return "heart.fill"
        case .friendRequest:             return "person.badge.plus"
        case .friendAccepted:            return "person.2.fill"
        case .albumPublished:            return "book.fill"
        case .newStory:                  return "camera.fill"
        case .feedComment:               return "bubble.left.fill"
        case .guestbookCreated:          return "text.book.closed.fill"
        case .albumPhotoUploadReminder:  return "bell.fill"
        }
    }

    private func timeAgo(_ dateString: String) -> String {
        guard let date = NotificationDateParser.parse(dateString) else { return dateString }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 0 || seconds < 60 { return "방금 전" }
        if seconds < 3600 { return "\(seconds / 60)분 전" }
        let hours = seconds / 3600
        if hours < 24 { return "\(hours)시간 전" }
        let days = seconds / 86400
        if days < 7 { return "\(days)일 전" }
        let df = DateFormatter()
        df.dateFormat = "M월 d일"
        df.locale = Locale(identifier: "ko_KR")
        return df.string(from: date)
    }
}

// MARK: - 날짜 파싱 유틸

enum NotificationDateParser {
    static func parse(_ dateString: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: dateString) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: dateString) { return date }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for tz in [TimeZone(identifier: "Asia/Seoul")!, TimeZone(identifier: "UTC")!] {
            for fmt in [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss"
            ] {
                df.dateFormat = fmt
                df.timeZone = tz
                if let date = df.date(from: dateString) { return date }
            }
        }
        return nil
    }
}
