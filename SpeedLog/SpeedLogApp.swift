import SwiftUI
import Combine

// MARK: - Model
struct ProductResponse: Decodable {
    let products: [Product]
}

struct Product: Identifiable, Decodable {
    let id: Int
    let title: String
    let description: String
    let tags: [String]
    let images: [String]
    let reviews: [Review]
    
    struct Review: Identifiable, Decodable {
        let id = UUID()
        let reviewerName: String
        let comment: String
    }
}

// MARK: - ViewModel
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    private var cancellables = Set<AnyCancellable>()
    let VIEWNAME = "products"
    func fetchProducts(onCompletion: @escaping () -> Void) {
        guard let url = URL(string: "https://dummyjson.com/products/?delay=1000&limit=50") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ProductResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Data fetched successfully.")
                case .failure(let error):
                    print("Failed to fetch data: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.products = response.products
                onCompletion()
            })
            .store(in: &cancellables)
    }
}

// MARK: - Views
struct MainView: View {
    @State private var isLinkActive = false
    let VIEWNAME = "main"
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    SpeedLog.begin(view: VIEWNAME, action: "show_products")
                    //                    print("Button tapped")
                    isLinkActive = true
                }) {
                    Text("Show Products")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .navigationDestination(isPresented: $isLinkActive) {
                    ProductListView()
                }
            }
            .navigationTitle("Main")
        }
    }
}

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    let VIEWNAME = "products"
    var body: some View {
        List(viewModel.products) { product in
            ProductRowView(product: product)
        }
        .background(
            ViewDidAppearModifier {
                SpeedLog.finishAppear(view: VIEWNAME)
                viewModel.fetchProducts {
                    SpeedLog.finishUpdateData(view: VIEWNAME)
                }
            }
        )
        .navigationTitle("Products")
    }
}

struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: product.images.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 150)
            } placeholder: {
                Color.gray
                    .frame(height: 150)
            }
            
            Text(product.title)
                .font(.headline)
            
            HStack {
                ForEach(product.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(product.description)
                .lineLimit(3)
                .truncationMode(.tail)
                .font(.subheadline)
            
            ForEach(product.reviews) { review in
                Text("[\(review.reviewerName)]: \(review.comment)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - App Entry Point
@main
struct ProductApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct ViewDidAppearModifier: UIViewControllerRepresentable {
    var onViewDidAppear: () -> Void
    
    func makeUIViewController(context: Context) -> ViewDidAppearViewController {
        return ViewDidAppearViewController(onViewDidAppear: onViewDidAppear)
    }
    
    func updateUIViewController(_ uiViewController: ViewDidAppearViewController, context: Context) {}
}

class ViewDidAppearViewController: UIViewController {
    var onViewDidAppear: () -> Void
    
    init(onViewDidAppear: @escaping () -> Void) {
        self.onViewDidAppear = onViewDidAppear
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onViewDidAppear()
    }
}
