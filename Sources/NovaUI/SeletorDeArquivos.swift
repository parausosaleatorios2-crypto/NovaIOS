//
//  SeletorDeArquivos.swift
//  NovaUI
//
//  O seletor de documentos do iOS (UIDocumentPickerViewController) para os arquivos do After
//  Effects (.aep, .ffx). O .fileImporter do SwiftUI falhava aqui: so um por tela funciona (a
//  Home tem o de .nova e o de .aep) e, no editor, o tipo trocava depois de abrir e os .ffx
//  vinham cinza. Este abre direto, aceita qualquer arquivo e entrega uma copia local.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SeletorDeArquivos: UIViewControllerRepresentable {
    var tipos: [UTType] = [.item]
    var varios = false
    let escolheu: ([URL]) -> Void

    func makeCoordinator() -> Coord { Coord(escolheu) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: tipos, asCopy: true)
        p.allowsMultipleSelection = varios
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    final class Coord: NSObject, UIDocumentPickerDelegate {
        let escolheu: ([URL]) -> Void
        init(_ f: @escaping ([URL]) -> Void) { escolheu = f }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            escolheu(urls)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { escolheu([]) }
    }
}

extension AEImportador {
    /// Tudo: o arquivo do AE tem tipo proprio (ou nenhum) em cada app de arquivos.
    static let tiposDoSeletor: [UTType] = [.item, .data, .content]
}
