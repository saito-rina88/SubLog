import Foundation

struct EditServiceViewData {
    let trimmedName: String
    let selectedCategory: Category
    let canSave: Bool
    let iconButtonTitle: String
}

enum EditServiceViewDataBuilder {
    static func build(
        name: String,
        category: Category,
        presetIconCategory: Category?,
        iconData: Data?
    ) -> EditServiceViewData {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return EditServiceViewData(
            trimmedName: trimmedName,
            selectedCategory: presetIconCategory ?? category,
            canSave: !trimmedName.isEmpty,
            iconButtonTitle: "タップして変更"
        )
    }
}
