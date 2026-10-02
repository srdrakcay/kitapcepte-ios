extension BookSubject {
    var title: String {
        switch self {
        case .fantasy: String(localized: "subject.fantasy")
        case .scienceFiction: String(localized: "subject.science_fiction")
        case .romance: String(localized: "subject.romance")
        case .mystery: String(localized: "subject.mystery")
        case .history: String(localized: "subject.history")
        case .thriller: String(localized: "subject.thriller")
        case .horror: String(localized: "subject.horror")
        case .biography: String(localized: "subject.biography")
        }
    }
}
