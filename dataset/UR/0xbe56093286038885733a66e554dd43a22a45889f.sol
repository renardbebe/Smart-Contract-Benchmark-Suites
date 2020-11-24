 

contract DaoChallenge
{
	modifier noEther() {if (msg.value > 0) throw; _}

	modifier onlyOwner() {if (owner != msg.sender) throw; _}

	event notifySellToken(uint256 n, address buyer);
	event notifyRefundToken(uint256 n, address tokenHolder);
	event notifyTerminate(uint256 finalBalance);

	 
  mapping (address => uint256) public tokenBalanceOf;

	uint256 constant tokenPrice = 1000000000000000;  

	 
	address owner;

	function DaoChallenge () {
		owner = msg.sender;  
	}

	function () {
		address sender = msg.sender;
		if(tokenBalanceOf[sender] != 0) {
			throw;
		}
		tokenBalanceOf[sender] = msg.value / tokenPrice;  
		notifySellToken(tokenBalanceOf[sender], sender);
	}

	function refund() noEther {
		address sender = msg.sender;
		uint256 tokenBalance = tokenBalanceOf[sender];
		if (tokenBalance <= 0) { throw; }
		tokenBalanceOf[sender] = 0;
		sender.send(tokenBalance * tokenPrice);
		notifyRefundToken(tokenBalance, sender);
	}

	 
	function terminate() noEther onlyOwner {
		notifyTerminate(this.balance);
		suicide(owner);
	}
}