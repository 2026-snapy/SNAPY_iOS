//
//  VoiceRecorderSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceRecorderSheet: View {
    var onSend: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorderVM()

    var body: some View {
        ZStack {
            Color.MainYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                // 드래그 인디케이터
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                Text("음성 댓글")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 14)

                Spacer()

                // 타이머
                Text(recorder.timerText)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .monospacedDigit()

                // 파형
                waveformView
                    .frame(height: 80)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer()

                // 하단 버튼
                if recorder.state == .recorded {
                    // 녹음 완료 → 다시녹음 / 재생 / 전송
                    recordedButtons
                } else {
                    // 녹음 중 → 정지 버튼
                    recordingButton
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            recorder.startRecording()
        }
        .onDisappear {
            recorder.cleanup()
        }
    }

    // MARK: - 파형

    private var waveformView: some View {
        HStack(spacing: 2) {
            ForEach(Array(recorder.waveformSamples.enumerated()), id: \.offset) { _, sample in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 3, height: max(4, CGFloat(sample) * 60))
            }
        }
    }

    // MARK: - 녹음 중 버튼

    private var recordingButton: some View {
        Button {
            recorder.stopRecording()
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .padding(18)
                .background(
                    Circle()
                        .fill(Color.red)
                )
        }
    }

    // MARK: - 녹음 완료 버튼들

    private var recordedButtons: some View {
        HStack(spacing: 40) {
            // 다시 녹음
            Button {
                recorder.resetAndRecord()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.orange, in: Circle())
            }

            // 재생
            Button {
                recorder.togglePlayback()
            } label: {
                Image(systemName: recorder.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.red, in: Circle())
            }

            // 전송
            Button {
                if let url = recorder.recordedURL {
                    onSend(url)
                    dismiss()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.orange, in: Circle())
            }
        }
    }
}

// MARK: - ViewModel

enum RecorderState {
    case idle, recording, recorded
}

@MainActor
final class VoiceRecorderVM: ObservableObject {
    @Published var state: RecorderState = .idle
    @Published var timerText: String = "00:00:00"
    @Published var waveformSamples: [Float] = []
    @Published var isPlaying = false

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var startTime: Date?
    private(set) var recordedURL: URL?

    private var fileURL: URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("snapy_voice_\(UUID().uuidString).m4a")
    }

    func startRecording() {
        // 마이크 권한 확인 후 녹음 시작
        AVAudioApplication.requestRecordPermission { granted in
            Task { @MainActor in
                guard granted else {
                    print("[VoiceRecorder] 마이크 권한 거부됨")
                    return
                }
                self.beginRecording()
            }
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[VoiceRecorder] 세션 설정 실패: \(error)")
            return
        }

        let url = fileURL
        recordedURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            state = .recording
            startTime = Date()
            startTimer()
        } catch {
            print("[VoiceRecorder] 녹음 시작 실패: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        stopTimer()
        state = .recorded
    }

    func resetAndRecord() {
        cleanup()
        waveformSamples = []
        timerText = "00:00:00"
        startRecording()
    }

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }
        guard let url = recordedURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("[VoiceRecorder] 재생 실패: \(error)")
        }
    }

    func cleanup() {
        audioRecorder?.stop()
        audioPlayer?.stop()
        stopTimer()
        isPlaying = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .recording else { return }
                self.updateTimer()
                self.updateWaveform()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimer() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        let hundredths = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
        timerText = String(format: "%02d:%02d:%02d", mins, secs, hundredths)
    }

    private func updateWaveform() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -60
        // -60~0 → 0~1 로 변환
        let normalized = max(0, (power + 60) / 60)
        waveformSamples.append(normalized)
        // 최대 표시 개수 제한
        if waveformSamples.count > 100 {
            waveformSamples.removeFirst()
        }
    }
}

#Preview {
    VoiceRecorderSheet(onSend: { _ in })
}
