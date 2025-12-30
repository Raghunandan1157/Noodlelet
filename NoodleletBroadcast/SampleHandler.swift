//
//  SampleHandler.swift
//  NoodleletBroadcast
//
//  Created by Jules on 12/9/25.
//

import ReplayKit
import Vision

class SampleHandler: RPBroadcastSampleHandler {

    // Throttling: Process every 3 seconds
    private let throttleInterval: TimeInterval = 3.0
    private var lastProcessedTime: Date = Date.distantPast

    private let logWriter = LogWriter()
    private var lastSnippet: String = ""

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        print("Broadcast started")
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        print("Broadcast finished")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            processVideoFrame(sampleBuffer)
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            break
        }
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= throttleInterval else {
            return
        }
        lastProcessedTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // OCR Request
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let observations = request.results as? [VNRecognizedTextObservation] {
                self.handleOCRResults(observations)
            }
        }

        request.recognitionLevel = .accurate // or .fast
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error)")
        }
    }

    private func handleOCRResults(_ observations: [VNRecognizedTextObservation]) {
        // Extract meaningful snippets
        // Strategy: Combine top candidates, but filter out noise.
        // We look for the most prominent text (highest confidence, reasonable length).

        var extractedLines: [String] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }

            // Heuristic filters
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip short/empty
            if text.count < 4 { continue }

            // Skip common UI noise (optional, requires a blocklist)

            extractedLines.append(text)
        }

        // Join top lines to form a snippet (limit to ~200 chars)
        let fullText = extractedLines.joined(separator: " ")
        var snippet = String(fullText.prefix(200))

        if snippet.isEmpty { return }

        // Deduplication: If snippet is very similar to last one, skip
        if snippet == lastSnippet {
            return
        }

        // Simple fuzzy check (levenshtein is better, but simple prefix/contains check works for exact static screens)
        // If 80% matches, skip? For now, exact match or simple variation.
        // Let's just check if the new snippet contains the old one or vice versa (scrolling)
        if lastSnippet.count > 10 && (snippet.contains(lastSnippet) || lastSnippet.contains(snippet)) {
             // Maybe update the last snippet but don't log a new entry?
             // Or just skip.
             lastSnippet = snippet
             return
        }

        lastSnippet = snippet

        // Determine "App Hint" (heuristic: top-most text often contains app name or header)
        // This is crude. A better way uses `SBApplication` which isn't available in extension sandbox easily.
        // We can guess from the first line.
        let appHint = extractedLines.first

        let entry = LogEntry(snippet: snippet, appHint: appHint, confidence: 1.0)

        logWriter.append(entry)
        print("Logged: \(snippet.prefix(30))...")
    }
}
