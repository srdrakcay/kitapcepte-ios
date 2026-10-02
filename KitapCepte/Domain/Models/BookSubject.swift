/// Home chip filtreleri. `rawValue`, Open Library `subject:` değeridir.
enum BookSubject: String, CaseIterable, Identifiable, Sendable {
    case fantasy
    case scienceFiction = "science_fiction"
    case romance
    case mystery
    case history
    case thriller
    case horror
    case biography

    /// Hiçbir chip seçili değilken kullanılan konu.
    static let `default`: BookSubject = .fantasy

    var id: String { rawValue }
}
