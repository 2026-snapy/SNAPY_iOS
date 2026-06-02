//
//  AudioCommentPlayer.swift
//  SNAPY_iOS
//
//  Separated from CommentSheetView.swift
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioCommentPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var waveformHeights: [CGFloat] = Array(repeating: 4, count: 30)

    private var player: AVAudioPlayer?
    private var downloadTask: URLSessionDataTask?
    private var progressTimer: AnyCancellable?
    private var cachedAudioData: Data?
    private let barCount = 30

    func loadDuration(urlString: String) {
        guard duration == 0, let url = URL(string: urlString), urlString.hasPrefix("http") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.cachedAudioData = data
                if let tempPlayer = try? AVAudioPlayer(data: data) {
                    self.duration = tempPlayer.duration
                }
                self.extractWaveform(from: data)
            }
        }.resume()
    }

    private func extractWaveform(from data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("waveform_\(UUID().uuidString).m4a")
        do {
            try data.write(to: tempURL)
            let file = try AVAudioFile(forReading: tempURL)
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
                try? FileManager.default.removeItem(at: tempURL)
                return
            }
            try file.read(into: buffer)
            try? FileManager.default.removeItem(at: tempURL)

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            let samplesPerBar = max(frameCount / barCount, 1)

            var heights: [CGFloat] = []
            for i in 0..<barCount {
                let start = i * samplesPerBar
                let end = min(start + samplesPerBar, frameCount)
                var sum: Float = 0
                for j in start..<end {
                    sum += abs(channelData[j])
                }
                let avg = sum / Float(end - start)
                heights.append(CGFloat(avg))
            }

            let maxVal = heights.max() ?? 1
            if maxVal > 0 {
                waveformHeights = heights.map { max(4, ($0 / maxVal) * 28) }
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private func startProgressTimer() {
        progressTimer?.cancel()
        progress = 0
        currentTime = 0
        progressTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.player, player.isPlaying else { return }
                self.currentTime = player.currentTime
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
    }

    private func stopProgressTimer() {
        progressTimer?.cancel()
        progressTimer = nil
        progress = 0
        currentTime = 0
    }

    func togglePlayback(urlString: String) {
        if isPlaying {
            player?.stop()
            isPlaying = false
            stopProgressTimer()
            return
        }

        guard let url = URL(string: urlString) else { return }

        if url.isFileURL {
            playLocalFile(url)
            return
        }

        if let cached = cachedAudioData {
            playData(cached)
            return
        }

        downloadTask?.cancel()
        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data, error == nil else { return }
            DispatchQueue.main.async {
                self?.cachedAudioData = data
                self?.playData(data)
            }
        }
        downloadTask?.resume()
    }

    private func playLocalFile(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            duration = player?.duration ?? 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            print("[AudioPlayer] 로컬 재생 실패: \(error)")
        }
    }

    private func playData(_ data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            duration = player?.duration ?? 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            print("[AudioPlayer] 재생 실패: \(error)")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
        }
    }
}
