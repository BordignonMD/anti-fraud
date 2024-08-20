# Anti-Fraud System - Ruby on Rails

## Overview

This is a Ruby on Rails application designed to prevent credit card fraud by analyzing transactions in real-time and determining whether they should be approved or denied. The system evaluates each transaction based on predefined rules and returns a recommendation to either "approve" or "deny" the transaction.

## Industry Overview

### 1. Money Flow and Information Flow in the Acquirer Market

**Money Flow**: 
When a customer initiates a payment using their card, the process begins. The acquirer, which is the financial institution responsible for processing card payments on behalf of the merchant, collects funds from the customer's issuing bank. After deducting relevant fees, the acquirer transfers the remaining funds to the merchant's account.

**Information Flow**: 
Transaction details (e.g., card number, transaction amount) are sent from the merchant to the acquirer. The acquirer forwards this data to the card network (e.g., Visa, MasterCard), which then relays it to the issuing bank for approval. The bank's response (approval or denial) follows the reverse path back to the merchant.

**Main Players**: 
- **Merchant**: The entity selling goods or services.
- **Acquirer**: The financial institution processing payments for the merchant.
- **Issuing Bank**: The bank that issued the customer's credit or debit card.
- **Card Network**: Organizations like Visa or MasterCard that facilitate the transaction.

### 2. Acquirer, Sub-Acquirer, and Payment Gateway

**Acquirer**: 
A financial institution that processes card transactions for merchants, handling the movement of money and information.

**Sub-Acquirer**: 
Operates under an acquirer, usually offering specialized services or catering to smaller merchants. They depend on the acquirer for transaction processing.

**Payment Gateway**: 
A service that securely transmits transaction data from the merchant to the acquirer and card networks. It acts as an intermediary, handling the communication between the merchant and acquirer and often adding extra layers of security or functionality.

**Flow Differences**: 
With a payment gateway, the merchant interacts with the gateway rather than directly with the acquirer. The gateway manages the communication flow, providing additional security and features.

### 3. Chargebacks

**Definition**: 
A chargeback occurs when a customer disputes a transaction, leading to the issuing bank reversing the payment and withdrawing the funds from the merchant’s account.

**Difference from Cancellations**: 
A cancellation occurs when a transaction is voided before completion, usually by the merchant or customer. In contrast, a chargeback happens after the transaction is completed and involves reversing the payment.

**Connection with Fraud**: 
Chargebacks are often the result of fraud, such as unauthorized transactions or failure to deliver goods/services. They pose a significant risk in the acquiring world, leading to financial losses and penalties for merchants.

## Analysis and Findings

### Suspicious Activity Indicators:

- **Rapid Succession of Transactions**:
  - 502 transactions occurred within a short time frame (less than 1 minute) involving the same user, card number, or device ID. This rapid succession could indicate automated transactions or fraudulent activity.

- **High Transaction Amounts**:
  - 160 transactions were identified with unusually high amounts, falling within the top 5% of transaction values. These transactions should be reviewed for legitimacy.

- **Chargebacks**:
  - 391 transactions resulted in chargebacks. These often indicate disputes, which can signal fraudulent activity, especially if they involve the same user or card repeatedly.

### Additional Considerations for Fraud Detection:

- **Geolocation Data**: 
  - Helps determine if transactions occur from different locations within a short period, potentially indicating account takeover.

- **IP Address**: 
  - Multiple users or transactions from the same IP address might suggest organized fraud.

- **User Behavior History**: 
  - Analyzing transaction patterns over time for each user can highlight deviations from typical behavior, which might indicate fraud.

- **Cardholder Data**: 
  - Matching transaction details with known cardholder information can assist in identifying potential identity theft.
 
## Solving the problem

### Features

- **Single API Endpoint**: Receives transaction data and returns a recommendation to either approve or deny the transaction.
- **Rule-Based Decision Making**: Approve or deny transactions based on a set of predefined rules to identify potentially fraudulent activities.
- **Transaction Verification**: Verify transactions individually through an API route or by importing a CSV file containing multiple transaction records.
- **Scalability**: Designed to handle large volumes of transactions with low latency.

### Endpoints

#### Analyze Transaction

- **URL**: `/transactions/analyze`
- **Method**: POST
- **Description**: Receives a transaction payload and returns a recommendation on whether to approve or deny the transaction.

##### Request Payload

```json
{
  "transaction_id": 2342357,
  "merchant_id": 29744,
  "user_id": 97051,
  "card_number": "434505******9116",
  "transaction_date": "2019-11-31T23:16:32.812632",
  "transaction_amount": 373,
  "device_id": 285475
}
```

##### Response

```json
{
  "transaction_id": 2342357,
  "recommendation": "approve"
}
```

#### Import Transactions

- **URL**: `/transactions/import`
- **Method**: POST
- **Description**: Allows the importation of multiple transactions from a CSV file for batch processing and analysis.

### Anti-Fraud Rules

The system uses the following rules to determine whether a transaction should be approved or denied:

- Transaction Frequency: Reject a transaction if the user attempts too many transactions in a short period.
- Transaction Amount: Reject transactions above a certain threshold within a given time frame.
- Chargeback History: Reject transactions if the user has a history of chargebacks, even though this information is received after the transaction has been processed.

### Getting Started

#### Prerequisites

- **Ruby**: Version 3.2.2
- **Rails**: Version 7.1.3
- ##Docker**: Used for containerization
 
#### Setup

1. Clone the repository:

```
git clone https://github.com/yourusername/anti-fraud-system.git
cd anti-fraud-system
```

2. Build and start the Docker containers:

```
docker-compose up --build
```

3. Run database migrations:

```
docker exec -it web /bin/bash
rails db:migrate
```

### Deploy

The application is deployed on [Render](https://render.com/). You can access the deployed application at [https://anti-fraud.onrender.com/transactions](https://anti-fraud.onrender.com/transactions).

