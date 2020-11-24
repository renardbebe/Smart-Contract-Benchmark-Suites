 

contract SellOrder {
   

   

   

   
   
  address public challengeOwner;
  address public owner;  
  uint256 public tokens;
  uint256 public price;  

   


   

  modifier noEther() {if (msg.value > 0) throw; _}

  modifier onlyOwner() {if (owner != msg.sender) throw; _}

  modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _}

   

  function SellOrder (uint256 _tokens, uint256 _price, address _challengeOwner) noEther {
    owner = msg.sender;

    tokens = _tokens;
    price = _price;

     
    challengeOwner = _challengeOwner;
  }

  function () {
    throw;
  }

   

   

  function cancel () noEther onlyOwner {
    suicide(owner);
  }

  function execute () {
     

     
     
  }

   
  function terminate() noEther onlyChallengeOwner {
    suicide(challengeOwner);
  }
}

contract AbstractDaoChallenge {
	function isMember (DaoAccount account, address allegedOwnerAddress) returns (bool);
	function tokenPrice() returns (uint256);
}

contract DaoAccount
{
	 

	 

	 

	 

	address public daoChallenge;  

	 
   
  address public challengeOwner;

	 

	uint256 tokenBalance;  
  address owner;         

	 

	modifier noEther() {if (msg.value > 0) throw; _}

	modifier onlyOwner() {if (owner != msg.sender) throw; _}

	modifier onlyDaoChallenge() {if (daoChallenge != msg.sender) throw; _}

	modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _}

	 

  function DaoAccount (address _owner, address _challengeOwner) noEther {
    owner = _owner;
    daoChallenge = msg.sender;
		tokenBalance = 0;

     
    challengeOwner = _challengeOwner;
	}

	function () {
		throw;
	}

	 

	 

	function getOwnerAddress() constant returns (address ownerAddress) {
		return owner;
	}

	function getTokenBalance() constant returns (uint256 tokens) {
		return tokenBalance;
	}

	function buyTokens() onlyDaoChallenge returns (uint256 tokens) {
		uint256 amount = msg.value;
		uint256 tokenPrice = AbstractDaoChallenge(daoChallenge).tokenPrice();

		 
		if (amount == 0) throw;

		 
		if (amount % tokenPrice != 0) throw;

		tokens = amount / tokenPrice;

		tokenBalance += tokens;

		return tokens;
	}

	function transfer(uint256 tokens, DaoAccount recipient) noEther onlyDaoChallenge {
		if (tokens == 0 || tokenBalance == 0 || tokenBalance < tokens) throw;
		if (tokenBalance - tokens > tokenBalance) throw;  
		tokenBalance -= tokens;
		recipient.receiveTokens(tokens);
	}

	function receiveTokens(uint256 tokens) {
		 
		DaoAccount sender = DaoAccount(msg.sender);
		if (!AbstractDaoChallenge(daoChallenge).isMember(sender, sender.getOwnerAddress())) throw;

		if (tokens > sender.getTokenBalance()) throw;

		 
		if (tokenBalance + tokens < tokenBalance) throw;

		tokenBalance += tokens;
	}

  function placeSellOrder(uint256 tokens, uint256 price) noEther onlyDaoChallenge returns (SellOrder) {
    if (tokens == 0 || tokenBalance == 0 || tokenBalance < tokens) throw;
    if (tokenBalance - tokens > tokenBalance) throw;  
    tokenBalance -= tokens;

    SellOrder order = new SellOrder(tokens, price, challengeOwner);
    return order;
  }

  function cancelSellOrder(SellOrder order) noEther onlyDaoChallenge {
    uint256 tokens = order.tokens();
    tokenBalance += tokens;
    order.cancel();
  }

	 
	function terminate() noEther onlyChallengeOwner {
		suicide(challengeOwner);
	}
}

contract DaoChallenge
{
	 


	 

	event notifyTerminate(uint256 finalBalance);
	event notifyTokenIssued(uint256 n, uint256 price, uint deadline);

	event notifyNewAccount(address owner, address account);
	event notifyBuyToken(address owner, uint256 tokens, uint256 price);
	event notifyTransfer(address owner, address recipient, uint256 tokens);
  event notifyPlaceSellOrder(uint256 tokens, uint256 price);
  event notifyCancelSellOrder();

	 

	 
	uint public tokenIssueDeadline = now;
	uint256 public tokensIssued = 0;
	uint256 public tokensToIssue = 0;
	uint256 public tokenPrice = 1000000000000000;  

	mapping (address => DaoAccount) public daoAccounts;
  mapping (address => SellOrder) public sellOrders;

   
  address public challengeOwner;

	 

	 

	modifier noEther() {if (msg.value > 0) throw; _}

	modifier onlyChallengeOwner() {if (challengeOwner != msg.sender) throw; _}

	 

	function DaoChallenge () {
		challengeOwner = msg.sender;  
	}

	function () noEther {
	}

	 

	function accountFor (address accountOwner, bool createNew) private returns (DaoAccount) {
		DaoAccount account = daoAccounts[accountOwner];

		if(account == DaoAccount(0x00) && createNew) {
			account = new DaoAccount(accountOwner, challengeOwner);
			daoAccounts[accountOwner] = account;
			notifyNewAccount(accountOwner, address(account));
		}

		return account;
	}

	 

	function createAccount () {
		accountFor(msg.sender, true);
	}

	 
	function isMember (DaoAccount account, address allegedOwnerAddress) returns (bool) {
		if (account == DaoAccount(0x00)) return false;
		if (allegedOwnerAddress == 0x00) return false;
		if (daoAccounts[allegedOwnerAddress] == DaoAccount(0x00)) return false;
		 
		if (daoAccounts[allegedOwnerAddress] != account) return false;
		return true;
	}

	function getTokenBalance () constant noEther returns (uint256 tokens) {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) return 0;
		return account.getTokenBalance();
	}

	 
	 
	 
	function issueTokens (uint256 n, uint256 price, uint deadline) noEther onlyChallengeOwner {
		 
		if (now < tokenIssueDeadline) throw;

		 
		if (deadline < now) throw;

		 
		if (n == 0) throw;

		tokenPrice = price;
		tokenIssueDeadline = deadline;
		tokensToIssue = n;
		tokensIssued = 0;

		notifyTokenIssued(n, price, deadline);
	}

	function buyTokens () returns (uint256 tokens) {
		tokens = msg.value / tokenPrice;

		if (now > tokenIssueDeadline) throw;
		if (tokensIssued >= tokensToIssue) throw;

		 
		 
		tokensIssued += tokens;
		if (tokensIssued > tokensToIssue) throw;

	  DaoAccount account = accountFor(msg.sender, true);
		if (account.buyTokens.value(msg.value)() != tokens) throw;

		notifyBuyToken(msg.sender, tokens, msg.value);
		return tokens;
 	}

	function transfer(uint256 tokens, address recipient) noEther {
		DaoAccount account = accountFor(msg.sender, false);
		if (account == DaoAccount(0x00)) throw;

		DaoAccount recipientAcc = accountFor(recipient, false);
		if (recipientAcc == DaoAccount(0x00)) throw;

		account.transfer(tokens, recipientAcc);
		notifyTransfer(msg.sender, recipient, tokens);
	}

  function placeSellOrder(uint256 tokens, uint256 price) noEther returns (SellOrder) {
    DaoAccount account = accountFor(msg.sender, false);
    if (account == DaoAccount(0x00)) throw;

    SellOrder order = account.placeSellOrder(tokens, price);

    sellOrders[address(order)] = order;

    notifyPlaceSellOrder(tokens, price);
    return order;
  }

  function cancelSellOrder(address addr) noEther {
    DaoAccount account = accountFor(msg.sender, false);
    if (account == DaoAccount(0x00)) throw;

    SellOrder order = sellOrders[addr];
    if (order == SellOrder(0x00)) throw;

    if (order.owner() != address(account)) throw;

    sellOrders[addr] = SellOrder(0x00);

    account.cancelSellOrder(order);

    notifyCancelSellOrder();
  }

	 
	function terminate() noEther onlyChallengeOwner {
		notifyTerminate(this.balance);
		suicide(challengeOwner);
	}
}