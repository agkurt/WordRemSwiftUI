//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//


import SwiftUI

struct HomeScreenView: View {
    
    @ObservedObject var viewModel = HomeScreenViewModel()
    @State private var currentPage: Int = 0
    @State private var selectedCard: String = ""
    
    // Farklı ekranlara geçiş yapacak elemanların listesi
    let features = ["Random Sentence used to word", "Top 100 most used English verbs in the world ", "The 100 most used English adjectives in the world", "The 100 most used English word in the world","News of the day"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        TabView(selection: $currentPage) {
                            ForEach(viewModel.cardNames.indices, id: \.self) { index in
                                NavigationLink(destination: CardDetailView(cardName: viewModel.cardNames[index])) {
                                    CardView(title: viewModel.cardNames[index],
                                             image: Image(systemName: "pencil"))
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                        .frame(height: geometry.size.height * 0.3)
                        
                        LineView(textPlace: "More Features")
                        
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 20) {
                            ForEach(features.indices, id: \.self) { index in
                                NavigationLink(destination: destinationView(for: index)) {
                                    Text(features[index])
                                        .padding()
                                        .background(Color(hex: "#8b6072"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cards")
        }
        .onAppear {
            Task {
                await viewModel.fetchCardName()
            }
        }
    }
    //SwiftUI’de ViewBuilder ve View döndüren fonksiyonlar genellikle View’ların içinde bulunur. Bunun nedeni, View’ların durumunu yönetme ve yeniden oluşturma yeteneğidir.
    @ViewBuilder
    func destinationView(for index: Int) -> some View {
        switch index {
        case 0:
            GetWordsView()
        case 1:
            Feature2View()
        case 2:
            Feature3View()
        case 3:
            Feature4View()
        case 4:
            Feature5View()
        default:
            EmptyView()
        }
    }
}

struct Feature1View: View {
    var body: some View {
        Text("This is Feature 1")
    }
}

struct Feature2View: View {
    var body: some View {
        Text("This is Feature 2")
    }
}

struct Feature3View: View {
    var body: some View {
        Text("This is Feature 3")
    }
}

struct Feature4View: View {
    var body: some View {
        Text("This is Feature 4")
    }
}

struct Feature5View: View {
    var body: some View {
        Text("This is Feature 5")
    }
}

#Preview {
    HomeScreenView()
}

