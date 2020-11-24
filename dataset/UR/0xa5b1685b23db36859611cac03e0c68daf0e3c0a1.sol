 

pragma solidity ^0.4.18;

 


contract SmartCityToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {}
    
    function setTokenStart(uint256 _newStartTime) public {}

    function burn() public {}
}

contract SmartCityCrowdsale {
    using SafeMath for uint256;

	 
    SmartCityToken public token;  
	
	address public owner;  

	mapping (address => bool) whitelist;  

    mapping(address => uint256) public balances;  
	
	mapping(address => uint256) public purchases;  

    uint256 public raisedEth;  

    uint256 public startTime;  

    uint256 public tokensSoldTotal = 0;  

    bool public crowdsaleEnded = false;  
	
	bool public paused = false;  

    uint256 public positionPrice = 5730 finney;  
	
	uint256 public usedPositions = 0;  
	
	uint256 public availablePositions = 100;  

    address walletAddress;  

	 
    uint256 constant public tokensForSale = 164360928100000;  

	uint256 constant public weiToTokenFactor = 10000000000000;

	uint256 constant public investmentPositions = 4370;  

    uint256 constant public investmentLimit = 18262325344444;  

	 
    event FundTransfer(address indexed _investorAddr, uint256 _amount, uint256 _amountRaised);  
	
	event Granted(address indexed party);  
	
	event Revoked(address indexed party);  
	
	event Ended(uint256 raisedAmount);  

	 
	modifier onlyWhenActive() {
		require(now >= startTime && !crowdsaleEnded && !paused);
		_;
	}
	
	modifier whenPositionsAvailable() {
		require(availablePositions > 0);
		_;
	}

	modifier onlyWhitelisted(address party) {
		require(whitelist[party]);
		_; 
	}
	
	modifier onlyNotOnList(address party) {
		require(!whitelist[party]);
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

     
    function SmartCityCrowdsale (
            address _tokenAddress,
            address _owner,
            address _walletAddress,
            uint256 _start) public {

        owner = _owner;
        token = SmartCityToken(_tokenAddress);
        walletAddress = _walletAddress;

        startTime = _start;  
    }

     
    function() public payable {
        invest();
    }

     
    function invest() public payable
				onlyWhitelisted(msg.sender)
				whenPositionsAvailable
				onlyWhenActive
	{
		address _receiver = msg.sender;
        uint256 amount = msg.value;  

        var (positionsCnt, tokensCnt) = getPositionsAndTokensCnt(amount); 

        require(positionsCnt > 0 && positionsCnt <= availablePositions && tokensCnt > 0);

		require(purchases[_receiver].add(tokensCnt) <= investmentLimit);  

        require(tokensSoldTotal.add(tokensCnt) <= tokensForSale);

        walletAddress.transfer(amount);  
		
        balances[_receiver] = balances[_receiver].add(amount);  
		purchases[_receiver] = purchases[_receiver].add(tokensCnt);  
        raisedEth = raisedEth.add(amount);  
		availablePositions = availablePositions.sub(positionsCnt);
		usedPositions = usedPositions.add(positionsCnt);
        tokensSoldTotal = tokensSoldTotal.add(tokensCnt);  

        require(token.transferFrom(owner, _receiver, tokensCnt));  

        FundTransfer(_receiver, amount, raisedEth);
		
		if (usedPositions == investmentPositions) {  
			token.burn();
			crowdsaleEnded = true;  
			
			Ended(raisedEth);
		}
    }
    
     
    function getPositionsAndTokensCnt(uint256 _value) public constant onlyWhenActive returns(uint256 positionsCnt, uint256 tokensCnt) {
			if (_value % positionPrice != 0 || usedPositions >= investmentPositions) {
				return(0, 0);
			}
			else {
				uint256 purchasedPositions = _value.div(positionPrice);
				uint256 purchasedTokens = ((tokensForSale.sub(tokensSoldTotal)).mul(purchasedPositions)).div(investmentPositions.sub(usedPositions));
				return(purchasedPositions, purchasedTokens);
			}
    }

	function getMinPurchase() public constant onlyWhenActive returns(uint256 minPurchase) {
		return positionPrice;
	}
	
	 
	
     
    function setAvailablePositions(uint256 newAvailablePositions) public onlyOwner {
        require(newAvailablePositions <= investmentPositions.sub(usedPositions));
		availablePositions = newAvailablePositions;
    }
	
	 
    function setPositionPrice(uint256 newPositionPrice) public onlyOwner {
        require(newPositionPrice > 0);
		positionPrice = newPositionPrice;
    }
	
	  
    function setPaused(bool _paused) public onlyOwner { paused = _paused; }

	 
	function drain() public onlyOwner { walletAddress.transfer(this.balance); }
	
	 
	function endCrowdsale() public onlyOwner {
		usedPositions = investmentPositions;
		availablePositions = 0;
		token.burn();  
		crowdsaleEnded = true;  
		
		Ended(raisedEth);
	}

	 
	function grant(address _party) public onlyOwner onlyNotOnList(_party)
	{
		whitelist[_party] = true;
		Granted(_party);
	}

	function revoke(address _party) public onlyOwner onlyWhitelisted(_party)
	{
		whitelist[_party] = false;
		Revoked(_party);
	}
	
	function massGrant(address[] _parties) public onlyOwner
	{
		uint len = _parties.length;
		
		for (uint i = 0; i < len; i++) {
			whitelist[_parties[i]] = true;
			Granted(_parties[i]);
		}
	}

	function massRevoke(address[] _parties) public onlyOwner
	{
		uint len = _parties.length;
		
		for (uint i = 0; i < len; i++) {
			whitelist[_parties[i]] = false;
			Revoked(_parties[i]);
		}
	}

	function isWhitelisted(address _party) public constant returns (bool) {
		return whitelist[_party];
	}
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
	
     