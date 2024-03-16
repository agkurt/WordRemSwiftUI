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
    
    let features = ["Random Sentence", "Translate", "News of the day", "The 100 most used English word in the world","The 100 most used English adjectives in the world","GEMINI AI"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        if viewModel.cardNames.isEmpty {
                            ProgressView()
                                .frame(width: 100,height: 100)
                                .background(Color(hex:"#1c2127"))
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
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible())]) {
                                ForEach(features.indices, id: \.self) { index in
                                    NavigationLink(destination: destinationView(for: index)) {
                                        Text(features[index])
                                            .frame(maxWidth: .infinity,minHeight:75,alignment:.center)
                                            .padding()
                                            .background(Color(hex: "#1c2127"))
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom,60)
                    }
                }
            }
            .navigationTitle("Cards")
            .onAppear {
                Task {
                    await viewModel.fetchCardName()
                }
            }
        }
    }
    
    @ViewBuilder
    func destinationView(for index: Int) -> some View {
        switch index {
        case 0:
            SentenceScreenView()
        case 1:
            TranslationView(viewModel: viewModel2)
        case 2:
            NewsView()
        case 3:
            Feature4View()
        case 4:
            Feature3View()
        case 5:
            GeminiAIView() // AI
        default:
            EmptyView()
        }
    }
}

struct Feature3View: View {
    var body: some View {
        Text("AI")
    }
}

struct Feature4View: View {
    var body: some View {
        Text("This is Feature 4")
    }
}


#Preview {
    HomeScreenView()
}

