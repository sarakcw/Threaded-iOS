//
//  PatternsCollectionViewController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 2/10/2025.
//

import UIKit


class PatternsCollectionViewController: UICollectionViewController, UISearchResultsUpdating{
    
    private var searchTask: Task<Void, Never>? // Keep track of search bar activities
    
    let SECTION_PATTERN = 0
    let CELL_PATTERN = "PatternCell"
    
    var allPatterns: [PatternData] = [] // Data source
    var filteredPatterns: [PatternData] = []
    
    // Get api keys from info.plist
    private lazy var api: RavelryAPI = {
        let username = Bundle.main.object(forInfoDictionaryKey: "RAVELRY_API_USER") as? String ?? ""
        let password = Bundle.main.object(forInfoDictionaryKey: "RAVELRY_API_PASS") as? String ?? ""
        return RavelryAPI(username: username, password: password)
    }()
    
    let MAX_PAGES = 10


    override func viewDidLoad() {
        super.viewDidLoad()

        // Create Search Controller
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Patterns"

        // Put the search bar in the navigation bar
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // This view controller decides how the search controller is presented
        definesPresentationContext = true


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        
        // Do any additional setup after loading the view.

        
        // Setup layout
        collectionView.collectionViewLayout = createLayout()
        loadPatterns()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure navigation bar to be purple
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .violetColour
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationController?.navigationBar.isTranslucent = false
        

    }
    
    //MARK: - Search bar functions
    func updateSearchResults(for searchController: UISearchController){
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !query.isEmpty else {
            // If empty, show all patterns
            filteredPatterns = allPatterns
            collectionView.reloadData()
            return
        }
        
        // Cancel previous pending search
        searchTask?.cancel()
        
        // Debounce 0.4 seconds
        // Prevent calling API at every keystroke
        //https://www.swiftbysundell.com/articles/delaying-an-async-swift-task/
        searchTask = Task {
            
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s delay
            do {
                
                let results = try await api.fetchFreeDownloadablePatterns(query: query, page: 1)
                self.filteredPatterns = results
                await MainActor.run {
                    self.collectionView.reloadData()
                }
            } catch {
                print("Error fetching search results: \(error)")
            }
       }

    }
    
    //MARK: - Header Configuration
    override func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PatternsHeaderCollectionView.reuseIdentifier,
                for: indexPath
            ) as! PatternsHeaderCollectionView
            
            // Configure segmented control actions
            header.difficultySegmentedControl.addTarget(
                self,
                action: #selector(applyDifficultyFilter(_:)),
                for: .valueChanged
            )
            
            
            return header
        }
        return UICollectionReusableView()
    }
    
    // MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            
            if sectionIndex == self.SECTION_PATTERN{
                
                // Configure the layout for Events Section
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(380))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10 // Spacing beween each group
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16) // Padding
                
                // add a header (for search bar and segmented control)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .absolute(55))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
                
            }
            else{
                return nil
            }
        }
        return layout

    }
    
    //MARK: - Request Patterns
    private func loadPatterns() {
        Task {
            // Reset data before loading
            allPatterns.removeAll()
            filteredPatterns.removeAll()
            collectionView.reloadData()
            
            
            
            // Loop through multiple pages
           for page in 1...MAX_PAGES {
               do {
                   // Call the API method from your RavelryAPI.swift
                   let newPatterns = try await api.fetchFreeDownloadablePatterns(query: "", page: page)

                   // Stop if no results
                   if newPatterns.isEmpty { break }

                   // Append results
                   allPatterns.append(contentsOf: newPatterns)
                   filteredPatterns = allPatterns

                   // Update collection view immediately after each page
                    self.collectionView.reloadData()
                   

               } catch {
                   print("Error loading page \(page): \(error)")
                   break
               }
           }
           
        }
    }
    
    @objc func applyDifficultyFilter(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            // Beginner (difficulty average level is less than equal to 2)
            filteredPatterns = allPatterns.filter {
                
                let difficulty = $0.difficultyAverage ?? 0 //get difficulty
                return difficulty >= 0.1 && difficulty <= 2.0 // Return result of filter
                
            }
        case 2:
            // Intermediate (difficulty level below 6)
            filteredPatterns = allPatterns.filter {
                
                let difficulty = $0.difficultyAverage ?? 0 //get difficulty
                return difficulty >= 3.0 && difficulty <= 5.0 // Return result of filter
                
            }
        case 3:
            // Advanced (difficulty level above 6)
            filteredPatterns = allPatterns.filter { ($0.difficultyAverage ?? 0) >= 6.0 }
            
        default: // All
            filteredPatterns = allPatterns
        }
        collectionView.reloadData()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "showPatternDetails",
           let patternDetailsViewController = segue.destination as? PatternDetailsViewController,
           let indexPath = collectionView.indexPathsForSelectedItems?.first {
            patternDetailsViewController.pattern = filteredPatterns[indexPath.item]
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return filteredPatterns.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Use Pattern Collection View Cell when displaying pattern info cards
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PatternCell", for: indexPath) as! PatternsCollectionViewCell
        let pattern = filteredPatterns[indexPath.item]
        cell.configure(with: pattern)
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
