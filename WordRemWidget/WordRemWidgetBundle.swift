//
//  WordRemWidgetBundle.swift
//  WordRemWidget
//

import WidgetKit
import SwiftUI

@main
struct WordRemWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReviewCardWidget()
        WordOfTheDayWidget()
    }
}
