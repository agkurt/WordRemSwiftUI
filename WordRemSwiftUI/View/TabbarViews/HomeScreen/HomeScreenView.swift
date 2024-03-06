//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//


import SwiftUI

struct HomeScreenView: View {
    
    @ObservedObject var viewModel = HomeScreenViewModel()
    @ObservedObject var viewModel2 = TranslateViewModel()
    @State private var currentPage: Int = 0
    @State private var selectedCard: String = ""
    
    let features = ["Random Sentence used to word", "Translate", "The 100 most used English adjectives in the world", "The 100 most used English word in the world","News of the day"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        if viewModel.cardNames.isEmpty {
                            ProgressView()
                                .frame(width: 100,height: 100)
                                .background(Color(hex:"#8b6072"))
                                .foregroundStyle(.white)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .padding()
                            
                        }else {
                            TabView(selection: $currentPage) {
                                ForEach(viewModel.cardNames.indices, id: \.self) { index in
                                    NavigationLink(destination: CardDetailView(cardName: viewModel.cardNames[index], cardId:viewModel.cardIds[index])) {
                                        CardView(title: viewModel.cardNames[index],
                                                 image: Image(systemName: "pencil"))
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                            .frame(height: geometry.size.height * 0.3)
                        }
                        
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
            .onAppear(perform: {
                Task {
                    await viewModel.fetchCardName()
                }
            })
        }
    }
    
    //SwiftUI’de ViewBuilder ve View döndüren fonksiyonlar genellikle View’ların içinde bulunur. Bunun nedeni, View’ların durumunu yönetme ve yeniden oluşturma yeteneğidir.
    @ViewBuilder
    func destinationView(for index: Int) -> some View {
        switch index {
        case 0:
            GetWordsView()
        case 1:
            TranslationView(viewModel: viewModel2)
        case 2:
            Feature3View()
        case 3:
            Feature4View()
        case 4:
            NewsView()
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
