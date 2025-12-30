//
//  SampleHandler.swift
//  NoodleletBroadcast
//
//  Created by Jules on 12/9/25.
//

import ReplayKit
import Vision
import CoreMedia
import CoreVideo

class SampleHandler: RPBroadcastSampleHandler {

    // Throttling: Process every 4 seconds to be safe on battery and memory
    private let throttleInterval: TimeInterval = 4.0
    private var lastProcessedTime: Date = Date.distantPast

    private let logWriter = LogWriter()
    private var lastSnippet: String = ""

    // Status bar noise regex (Time format like 9:41, Battery %)
    private let noiseRegex = try? NSRegularExpression(pattern: "^(\\d{1,2}:\\d{2}|\\d{1,3}%)$", options: [])

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("Broadcast started")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        if sampleBufferType == .video {
            processVideoFrame(sampleBuffer)
        }
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= throttleInterval else { return }
        lastProcessedTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // MEMORY OPTIMIZATION: Extensions have a strict 50MB limit.
        // Vision request on full resolution Retina screens might crash.
        // We will perform OCR directly on the pixelBuffer but use .fast if possible,
        // or ensure we handle memory warnings (not possible in extension easily).
        // Best practice: The system usually handles the pixel buffer efficiently.
        // We will stick to .accurate but keep an eye on complexity.

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let observations = request.results as? [VNRecognizedTextObservation] {
                self.handleOCRResults(observations)
            }
        }

        // Use .accurate for better results, but if it crashes, switch to .fast
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // Only Recognize common languages to speed up
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("OCR Error: \(error)")
        }
    }

    private func handleOCRResults(_ observations: [VNRecognizedTextObservation]) {
        var extractedLines: [String] = []

        // Screen bounds estimation (normalized 0.0 to 1.0)
        // Top of screen (0.9 to 1.0) usually contains App Name / Header
        var potentialHeader: String? = nil

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)

            // Filter noise
            if shouldFilter(text) { continue }

            // Check for header (simple heuristic: high on screen)
            // Vision coordinates: (0,0) is bottom-left, (1,1) is top-right.
            // So y > 0.9 is the top status bar/nav bar area.
            let boundingBox = observation.boundingBox
            if boundingBox.minY > 0.9 && potentialHeader == nil {
                // It's at the very top, likely app name or time (if not filtered)
                if text.count > 3 { // Ignore short stuff like "LTE"
                    potentialHeader = text
                }
            } else {
                extractedLines.append(text)
            }
        }

        // Build Snippet
        let fullText = extractedLines.joined(separator: " ")
        var snippet = String(fullText.prefix(250))

        if snippet.count < 5 { return } // Too short to be useful

        // Deduplication
        if isDuplicate(snippet) {
            return
        }
        lastSnippet = snippet

        // Auto-Tagging
        let tags = generateTags(for: snippet)

        let entry = LogEntry(
            snippet: snippet,
            appHint: potentialHeader,
            source: "broadcast",
            confidence: 1.0,
            tags: tags
        )

        logWriter.append(entry)
    }

    private func shouldFilter(_ text: String) -> Bool {
        if text.count < 3 { return true }
        // Filter out time patterns (9:41) or simple numbers
        if let regex = noiseRegex {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    private func isDuplicate(_ newSnippet: String) -> Bool {
        if newSnippet == lastSnippet { return true }

        // Calculate similarity (Jaccard or simple containment)
        // Optimization: Just check if one contains the other (scrolling text)
        if lastSnippet.count > 15 && newSnippet.count > 15 {
             if newSnippet.contains(lastSnippet) || lastSnippet.contains(newSnippet) {
                 return true
             }
        }
        return false
    }

    private func generateTags(for text: String) -> [String] {
        var tags: [String] = []
        let lowerText = text.lowercased()

        if lowerText.contains("http") || lowerText.contains("www.") || lowerText.contains(".com") {
            tags.append("Link")
        }
        if lowerText.contains("func ") || lowerText.contains("var ") || lowerText.contains("let ") || lowerText.contains("{") {
            tags.append("Code")
        }
        if lowerText.contains("message") || lowerText.contains("chat") {
            tags.append("Chat")
        }
        return tags
    }
}
