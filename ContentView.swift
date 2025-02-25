// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ArbitrageView()
                .tabItem {
                    Label("Арбитраж", systemImage: "arrow.left.arrow.right")
                }
                .tag(0)
            
            StakingView()
                .tabItem {
                    Label("Стейкинг", systemImage: "percent")
                }
                .tag(1)
            
            LiquidityView()
                .tabItem {
                    Label("Ликвидность", systemImage: "drop.fill")
                }
                .tag(2)
            
            IDOView()
                .tabItem {
                    Label("IDO", systemImage: "rocket")
                }
                .tag(3)
            
            NFTStreamView()
                .tabItem {
                    Label("NFT Аренда", systemImage: "film")
                }
                .tag(4)
            
            PortfolioView()
                .tabItem {
                    Label("Портфель", systemImage: "chart.pie")
                }
                .tag(5)
            
            LogsView()
                .tabItem {
                    Label("Логи", systemImage: "list.bullet")
                }
                .tag(6)
        }
        .accentColor(.blue)
        .animation(.easeInOut, value: selectedTab)
    }
}

// MARK: - Арбитраж
struct ArbitrageView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    @State private var minSpreadPercent: Double = 0.1
    @State private var showSettings = false
    @State private var searchText = ""
    
    private var filteredOpportunities: [Opportunity] {
        viewModel.opportunities
            .filter { $0.spreadPercent >= minSpreadPercent }
            .filter { searchText.isEmpty || $0.symbol.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Мин. спред: \(minSpreadPercent.formatted())%")
                            .font(.caption)
                        Slider(value: $minSpreadPercent, in: 0...5, step: 0.1)
                            .tint(.blue)
                    }
                    TextField("Поиск монеты", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if viewModel.isScanning {
                    ProgressView("Сканирование...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredOpportunities.isEmpty {
                    Text("Возможности не найдены")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOpportunities) { opportunity in
                                OpportunityCard(opportunity: opportunity)
                                    .transition(.scale)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Арбитраж")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.scanForOpportunities() } }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(viewModel.isScanning ? .degrees(360) : .zero)
                            .animation(viewModel.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isScanning)
                    }
                    .disabled(viewModel.isScanning)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Стейкинг
struct StakingView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.stakingOptions) { option in
                        StakingCard(option: option)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("Стейкинг")
        }
    }
}

// MARK: - Майнинг Ликвидности
struct LiquidityView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.liquidityPools) { pool in
                        LiquidityCard(pool: pool)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("Майнинг Ликвидности")
        }
    }
}

// MARK: - IDO
struct IDOView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.idoOpportunities) { ido in
                        IDOCard(ido: ido)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("IDO")
        }
    }
}

// MARK: - NFT Аренда
struct NFTStreamView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.nftStreams) { stream in
                        NFTStreamCard(stream: stream)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("NFT Аренда")
        }
    }
}

// MARK: - Портфель
struct PortfolioView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var totalValue: Double {
        viewModel.portfolio.reduce(0) { $0 + $1.amount * $1.currentPrice }
    }
    
    var totalProfitLoss: Double {
        viewModel.portfolio.reduce(0) { $0 + $1.profitLoss }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Text("Общая стоимость: $\(totalValue.formatted())")
                        .font(.title2.bold())
                    Text("Прибыль/Убыток: \(totalProfitLoss.formatted()) (\(totalProfitLossPercent.formatted())%)")
                        .foregroundColor(totalProfitLoss >= 0 ? .green : .red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.portfolio) { asset in
                            PortfolioCard(asset: asset)
                                .transition(.scale)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Портфель")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.updatePortfolioPrices() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    private var totalProfitLossPercent: Double {
        totalProfitLoss / (totalValue - totalProfitLoss) * 100
    }
}

// MARK: - Логи
struct LogsView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.logs.reversed()) { log in
                        LogCard(log: log)
                            .transition(.opacity)
                    }
                }
                .padding()
            }
            .navigationTitle("Логи")
        }
    }
}

// MARK: - Компоненты
struct OpportunityCard: View {
    let opportunity: Opportunity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(opportunity.symbol)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Спред: \(opportunity.spreadPercent.formatted())%")
                    .font(.subheadline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Покупка: $\(opportunity.buyPrice.formatted())")
                    Text(opportunity.buyExchange.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack(alignment: .trailing) {
                    Text("Продажа: $\(opportunity.sellPrice.formatted())")
                    Text(opportunity.sellExchange.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                if let buyURL = URL(string: opportunity.buyLink) {
                    Link("Купить", destination: buyURL)
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
                Spacer()
                if let sellURL = URL(string: opportunity.sellLink) {
                    Link("Продать", destination: sellURL)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct StakingCard: View {
    let option: StakingOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(option.coin)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Доходность: \(option.apy.formatted())%")
                Spacer()
                Text("Блокировка: \(option.lockPeriod == 0 ? "Гибкая" : "\(option.lockPeriod) дней")")
            }
            .font(.subheadline)
            
            Text("Мин. стейк: \(option.minimumStake.formatted()) \(option.coin)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct LiquidityCard: View {
    let pool: LiquidityPool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pool.pair)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Доходность: \(pool.apy.formatted())%")
                Spacer()
                Text("Платформа: \(pool.platform)")
            }
            .font(.subheadline)
            
            Text("Риск: \(pool.riskLevel)")
                .font(.caption)
                .foregroundColor(pool.riskLevel == "Высокий" ? .red : pool.riskLevel == "Средний" ? .orange : .green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct IDOCard: View {
    let ido: IDOOpportunity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ido.projectName)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Токен: \(ido.token)")
                Spacer()
                Text("Дата: \(ido.launchDate, style: .date))")
            }
            .font(.subheadline)
            
            HStack {
                Text("Мин. вклад: $\(ido.minInvestment.formatted())")
                Spacer()
                Text("Ожид. ROI: \(ido.expectedROI.formatted())%")
                    .foregroundColor(.green)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct NFTStreamCard: View {
    let stream: NFTStream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stream.nftName)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Коллекция: \(stream.collection)")
                Spacer()
                Text("Ставка: $\(stream.dailyRate.formatted())/день")
            }
            .font(.subheadline)
            
            Text("Доступно: \(stream.availableDays) дней")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct PortfolioCard: View {
    let asset: PortfolioAsset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(asset.symbol)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Количество: \(asset.amount.formatted())")
                    Text("Средняя цена: $\(asset.averagePrice.formatted())")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Стоимость: $\(asset.amount * asset.currentPrice.formatted())")
                    Text("П/У: \(asset.profitLoss.formatted()) (\(asset.profitLossPercent.formatted())%)")
                        .foregroundColor(asset.profitLoss >= 0 ? .green : .red)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct LogCard: View {
    let log: LogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.type == .error ? "exclamationmark.triangle" :
                    log.type == .warning ? "exclamationmark" :
                    log.type == .success ? "checkmark.circle" : "info.circle")
                .foregroundColor(log.type == .error ? .red :
                                log.type == .warning ? .yellow :
                                log.type == .success ? .green : .blue)
            
            VStack(alignment: .leading) {
                Text(log.message)
                    .font(.subheadline)
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ArbitrageViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Биржи")) {
                    ForEach(viewModel.availableExchanges, id: \.self) { exchange in
                        Toggle(exchange.capitalized, isOn: binding(for: exchange))
                    }
                }
                
                Section(header: Text("Монеты")) {
                    ForEach(viewModel.availableCoins, id: \.self) { coin in
                        Toggle(coin, isOn: binding(for: coin))
                    }
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                Button("Готово") { dismiss() }
            }
        }
    }
    
    private func binding(for item: String) -> Binding<Bool> {
        Binding(
            get: { 
                viewModel.selectedExchanges.contains(item) || viewModel.selectedCoins.contains(item) 
            },
            set: { newValue in
                if viewModel.availableExchanges.contains(item) {
                    if newValue {
                        viewModel.selectedExchanges.insert(item)
                    } else {
                        viewModel.selectedExchanges.remove(item)
                    }
                } else {
                    if newValue {
                        viewModel.selectedCoins.insert(item)
                    } else {
                        viewModel.selectedCoins.remove(item)
                    }
                }
            }
        )
    }
}