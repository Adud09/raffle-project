# 🎰 Raffle Smart Contract (Foundry)

A decentralized raffle system built using Solidity and Foundry.
Users can enter the raffle by paying an entrance fee, and a random winner is selected after a fixed interval.

---

## 📌 Overview

This project demonstrates:

* Smart contract development with Solidity
* Testing using Foundry
* Script deployment
* Basic randomness integration (Chainlink VRF style logic)

---

## ⚙️ Features

* 🎟️ Enter raffle by paying ETH
* ⏱️ Time-based winner selection
* 🎲 Pseudo-random / VRF-based winner picking
* 🔐 Secure fund handling
* 🧪 Unit & integration tests

---

## 🏗️ Tech Stack

* Solidity
* Foundry
* Chainlink (VRF / Automation concepts)

---

## 📂 Project Structure

```
src/        # Smart contracts
script/     # Deployment scripts
test/       # Unit & integration tests
lib/        # Dependencies
```

---

## 🚀 Getting Started

### 1. Clone the repo

```
git clone https://github.com/Adud09/raffle-project.git
cd raffle-project
```

---

### 2. Install dependencies

```
forge install
```

---

### 3. Build the project

```
forge build
```

---

### 4. Run tests

```
forge test -vv
```

---

### 5. Deploy (example)

```
forge script script/DeployRaffle.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

---

## 🧪 Testing

This project includes:

* Unit tests
* Integration tests
* Script testing

Run:

```
forge test
```

---

## 🔒 Security Considerations

* Reentrancy protection
* Proper state updates before transfers
* Input validation
* Gas optimization awareness

---

## 📈 Future Improvements

* Full Chainlink VRF integration
* Frontend (React / Next.js)
* Multi-round raffles
* Better randomness guarantees

---

## 👨‍💻 Author

Daniel (Adud09)

---

## 📄 License

MIT
