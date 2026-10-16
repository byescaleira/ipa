import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

struct DownloadTaskRow: View {
    @Environment(LibraryModel.self) private var library
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let task: DownloadTask

    var body: some View {
        let progress = library.progress(for: task)
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(spacing: .spaceM) {
                AppArtwork(task.app.artworkURL, size: .badgeL)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: task.app.name).font(.rowTitle).lineLimit(1)
                    Text(verbatim: library.versionText(for: task))
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                if task.failure == nil {
                    Button("Cancel Download", systemImage: "xmark") { library.cancel(task) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .tint(Color.secondary)
                        .frame(minWidth: .rowHeight, minHeight: .rowHeight)
                        .contentShape(.rect)
                }
            }
            if task.failure == nil {
                ProgressView(value: progress)
                    .tint(appTint)
                    .animation(reduceMotion ? nil : .smooth, value: progress)
                    .accessibilityHidden(true)
            }
            Text(verbatim: library.statusText(for: task))
                .font(.footnote)
                .foregroundStyle(task.failure == nil ? Color.secondary : Color.negative)
                .contentTransition(.numericText())
            if task.failure != nil {
                HStack(spacing: .spaceL) {
                    Button("Retry", systemImage: "arrow.clockwise") { library.retry(task) }
                    Button("Dismiss", systemImage: "xmark") { library.cancel(task) }
                        .tint(Color.secondary)
                }
                .font(.buttonLabel)
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, .space2XS)
    }
}

struct DownloadRecordRow: View {
    @Environment(LibraryModel.self) private var library
    let record: DownloadRecord

    var body: some View {
        let url = library.fileURL(for: record)
        HStack(spacing: .spaceM) {
            HStack(spacing: .spaceM) {
                AppArtwork(record.artworkURL, size: .badgeL)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: record.name).font(.rowTitle).lineLimit(2)
                    Text(verbatim: library.caption(for: record))
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            ShareButton([url]) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .frame(minWidth: .rowHeight, minHeight: .rowHeight)
            .contentShape(.rect)
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                library.deletion = record
            }
            ShareButton([url]) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .contextMenu {
            ShareButton([url]) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            #if os(macOS)
                Button("Show in Finder", systemImage: "folder") { library.reveal(record) }
            #endif
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                library.deletion = record
            }
        }
    }
}
