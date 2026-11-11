//
//  CacheDeQuadros.swift
//  NovaUI
//
//  O cache de quadros da previa, como o RAM Preview do After Effects: cada quadro que a
//  previa monta fica guardado (na GPU, no tamanho da tela) e aparece como a faixa verde em
//  cima da regua da timeline. Quadro em cache sai na hora; o que falta e montado na vez.
//  Qualquer mudanca na composicao (ou nos efeitos carregados) limpa o cache.
//

import SwiftUI
import Metal
import UIKit

@MainActor
public final class CacheDeQuadros: ObservableObject {
    /// Quadros prontos (indice do quadro na composicao): a faixa verde.
    @Published public private(set) var prontos: Set<Int> = []

    private var texturas: [Int: MTLTexture] = [:]
    private var comp: Composition?
    private var assinaturaDosEfeitos: [String] = []
    private var bytesPorQuadro = 0
    private var esperando: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var avisoDeMemoria: NSObjectProtocol?

    /// Teto de memoria: um sexto da RAM do aparelho, no maximo 768 MB.
    let orcamento: Int = {
        let ram = Int(clamping: ProcessInfo.processInfo.physicalMemory)
        return max(96 << 20, min(768 << 20, ram / 6))
    }()

    public init() {
        avisoDeMemoria = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.limpar() }
        }
    }

    deinit {
        if let avisoDeMemoria { NotificationCenter.default.removeObserver(avisoDeMemoria) }
    }

    public static func quadro(_ t: Float, fps: Float) -> Int {
        Int((Double(t) * Double(max(fps, 1)) + 1e-4).rounded(.down))
    }

    /// Confere se a composicao mudou desde o ultimo quadro; se mudou, o cache vale de novo do zero.
    func validar(_ c: Composition, efeitos: [String]) {
        if comp != c || assinaturaDosEfeitos != efeitos {
            comp = c
            assinaturaDosEfeitos = efeitos
            limpar()
        }
    }

    public func limpar() {
        texturas.removeAll()
        publicar()
    }

    /// A faixa verde muda fora da atualizacao da tela (o pedido de quadro vem de dentro
    /// dela, e o SwiftUI nao aceita @Published mudando ali); varias mudancas viram uma.
    private var publicacaoMarcada = false
    private func publicar() {
        guard !publicacaoMarcada else { return }
        publicacaoMarcada = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.publicacaoMarcada = false
            let s = Set(self.texturas.keys)
            if s != self.prontos { self.prontos = s }
        }
    }

    func textura(_ q: Int) -> MTLTexture? { texturas[q] }

    func temQuadro(_ q: Int) -> Bool { texturas[q] != nil }

    /// Todos os quadros de [de, ate) ja estao no cache.
    public func completo(de: Int, ate: Int) -> Bool {
        guard ate > de else { return true }
        for q in de..<ate where texturas[q] == nil { return false }
        return true
    }

    func guardar(_ q: Int, _ t: MTLTexture, perto atual: Int) {
        bytesPorQuadro = t.width * t.height * 4
        texturas[q] = t
        // Passou do teto: sai o quadro mais longe do cursor (como o AE descarta o que esta longe).
        while texturas.count * bytesPorQuadro > orcamento, texturas.count > 1 {
            guard let longe = texturas.keys.max(by: { abs($0 - atual) < abs($1 - atual) }) else { break }
            texturas[longe] = nil
        }
        publicar()
        avisar(q)
    }

    /// A previa mostrou o quadro q (do cache ou recem-montado).
    func mostrou(_ q: Int) { avisar(q) }

    private func avisar(_ q: Int) {
        if let cs = esperando.removeValue(forKey: q) { cs.forEach { $0.resume() } }
    }

    /// Espera a previa mostrar o quadro q (para tocar sem pular enquanto o cache enche).
    public func esperar(_ q: Int, limite: Double = 10) async {
        if texturas[q] != nil { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            esperando[q, default: []].append(c)
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(limite * 1_000_000_000))
                self?.avisar(q)
            }
        }
    }

    /// Faixas de quadros seguidos, para desenhar a barra verde sem um retangulo por quadro.
    public static func faixas(_ s: Set<Int>) -> [ClosedRange<Int>] {
        let v = s.sorted()
        var out: [ClosedRange<Int>] = []
        var ini: Int?, ant = 0
        for q in v {
            if let i = ini, q == ant + 1 { ant = q; _ = i; continue }
            if let i = ini { out.append(i...ant) }
            ini = q; ant = q
        }
        if let i = ini { out.append(i...ant) }
        return out
    }
}
