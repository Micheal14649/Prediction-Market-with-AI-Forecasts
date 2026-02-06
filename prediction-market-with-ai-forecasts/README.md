# 🔮 Prediction Market with AI Forecasts

A decentralized prediction market smart contract where users and AI agents bet on future outcomes, with AI reputation staked on prediction accuracy.

## 🎯 What It Does

This smart contract implements a binary prediction market (YES/NO) where:
- 👥 **Users** create markets and place bets on outcomes
- 🤖 **AI Agents** participate by placing bets and staking reputation
- 🏆 **Winners** claim proportional payouts from the losing pool
- 📊 **AI Reputation** increases/decreases based on prediction accuracy

## ✨ Key Features

- **Market Creation**: Anyone can create prediction markets with deadlines
- **Betting Mechanism**: Binary YES/NO betting with dynamic odds
- **AI Participation**: AI agent bets with reputation at stake
- **Reputation Tracking**: AI reputation adjusts based on correct predictions
- **Payout System**: Winners receive their stake + proportional share of losing pool
- **Market Stats**: Real-time odds, percentages, and AI positioning

## 🚀 Usage

### Creating a Market

```clarity
(contract-call? .prediction-market create-market 
  "Will Bitcoin reach $100k by end of 2025?" 
  u52560)
```

Parameters:
- `question`: Market question (max 256 chars)
- `deadline`: Block height when betting closes

### Placing a Bet

```clarity
(contract-call? .prediction-market place-bet 
  u1        ;; market-id
  true      ;; position (true = YES, false = NO)
  u1000)    ;; amount
```

### AI Betting (AI Agent Only)

```clarity
(contract-call? .prediction-market ai-bet 
  u1        ;; market-id
  true      ;; position
  u500      ;; amount
  u100)     ;; reputation-stake
```

### Resolving a Market (Owner Only)

```clarity
(contract-call? .prediction-market resolve-market 
  u1        ;; market-id
  true)     ;; outcome (true = YES won, false = NO won)
```

### Claiming Winnings

```clarity
(contract-call? .prediction-market claim-winnings u1)
```

### Checking Market Stats

```clarity
(contract-call? .prediction-market get-market-stats u1)
```

Returns:
- Total pool size
- YES/NO odds
- Percentage breakdown
- AI position (if any)

### Checking AI Reputation

```clarity
(contract-call? .prediction-market get-ai-reputation)
```

Returns:
- Current reputation score
- Total bets placed
- Correct predictions
- Accuracy percentage

## 📋 Contract Functions

### Public Functions

| Function | Description |
|----------|-------------|
| `create-market` | Create a new prediction market |
| `place-bet` | Place a bet on YES or NO |
| `ai-bet` | AI agent places a bet with reputation stake |
| `resolve-market` | Resolve market outcome (owner only) |
| `claim-winnings` | Claim winnings after resolution |
| `ai-claim-winnings` | AI claims winnings (AI agent only) |
| `set-ai-agent` | Update AI agent principal (owner only) |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-market` | Get market details |
| `get-user-bet` | Get user's bet in a market |
| `get-ai-bet` | Get AI's bet in a market |
| `get-ai-reputation` | Get AI reputation stats |
| `get-market-stats` | Get market odds and statistics |

## 💡 How It Works

### Market Lifecycle

1. **Creation** 📝: User creates market with question and deadline
2. **Betting Period** 💰: Users and AI place bets until deadline
3. **Resolution** ⚖️: Owner resolves market after deadline passes
4. **Payout** 🎁: Winners claim proportional winnings

### Payout Formula

```
Payout = Your_Stake + (Your_Stake × Losing_Pool ÷ Winning_Pool)
```

### AI Reputation System

- 🎯 **Correct Prediction**: Reputation increases by staked amount
- ❌ **Wrong Prediction**: Reputation decreases by staked amount
- 📈 **Accuracy**: Tracked as (Correct_Bets ÷ Total_Bets) × 100

## 🔒 Security Features

- Markets cannot be resolved before deadline
- Bets cannot be placed after deadline or after resolution
- Users can only claim winnings once
- AI must have sufficient reputation to stake
- Only contract owner can resolve markets
- Only designated AI agent can place AI bets

## 🎓 What You Learn

- **Prediction Markets**: How crowd wisdom aggregates forecasts
- **AI Incentives**: Reputation-based accountability for AI agents
- **Market Mechanics**: Odds calculation and payout distribution
- **Forecast Aggregation**: Combining human and AI predictions
- **Smart Contract Patterns**: Maps, variables, and error handling

## 🛠️ Testing

Deploy with Clarinet and test scenarios:

```bash
clarinet test
```

Test cases to cover:
- Market creation with various deadlines
- Multiple users betting on different positions
- AI betting with reputation stakes
- Market resolution with different outcomes
- Payout calculations for winners
- AI reputation updates

## 📊 Example Scenario

```
Market: "Will it rain tomorrow?"
Deadline: Block 1000

Bets:
- Alice: 100 STX on YES
- Bob: 200 STX on NO
- AI: 50 STX on YES (stakes 20 reputation)

Total: 150 YES, 200 NO

Resolution: YES (it rained!)

Payouts:
- Alice: 100 + (100 × 200 ÷ 150) = 233.33 STX
- AI: 50 + (50 × 200 ÷ 150) = 116.67 STX
- AI Reputation: 1000 → 1020 (+20)
- Bob: 0 STX (lost)
```

## 🌟 Future Enhancements

- Multiple outcome markets (not just binary)
- Time-weighted reputation decay
- Market categories and tags
- Liquidity pools for automated market makers
- Oracle integration for automated resolution
- Partial bet closing before deadline

## 📜 License

MIT