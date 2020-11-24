 

pragma solidity ^0.4.20;
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

contract OwnableToken {
	address public owner;
	address public minter;
	address public burner;
	address public controller;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function OwnableToken() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyMinter() {
		require(msg.sender == minter);
		_;
	}
	
	modifier onlyBurner() {
		require(msg.sender == burner);
		_;
	}
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}
  
	modifier onlyPayloadSize(uint256 numwords) {                                       
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setMinter(address _minterAddress) public onlyOwner {
		minter = _minterAddress;
	}
	
	function setBurner(address _burnerAddress) public onlyOwner {
		burner = _burnerAddress;
	}
	
	function setControler(address _controller) public onlyOwner {
		controller = _controller;
	}
}

contract KYCControl is OwnableToken {
	event KYCApproved(address _user, bool isApproved);
	mapping(address => bool) public KYCParticipants;
	
	function isKYCApproved(address _who) view public returns (bool _isAprroved){
		return KYCParticipants[_who];
	}

	function approveKYC(address _userAddress) onlyController public {
		KYCParticipants[_userAddress] = true;
		emit KYCApproved(_userAddress, true);
	}
}

contract VernamCrowdSaleToken is OwnableToken, KYCControl {
	using SafeMath for uint256;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    
	 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
	
	 
	uint256 constant POW = 10 ** 18;
	uint256 _circulatingSupply;
	
	 
	mapping (address => uint256) public balances;
		
	 
	event Burn(address indexed from, uint256 value);
	event Mint(address indexed _participant, uint256 value);

	 
	function VernamCrowdSaleToken() public {
		name = "Vernam Crowdsale Token";                             
		symbol = "VCT";                               				 
		decimals = 18;                            					 
		_totalSupply = SafeMath.mul(1000000000, POW);     			 
		_circulatingSupply = 0;
	}
	
	function mintToken(address _participant, uint256 _mintedAmount) public onlyMinter returns (bool _success) {
		require(_mintedAmount > 0);
		require(_circulatingSupply.add(_mintedAmount) <= _totalSupply);
		KYCParticipants[_participant] = false;

        balances[_participant] =  balances[_participant].add(_mintedAmount);
        _circulatingSupply = _circulatingSupply.add(_mintedAmount);
		
		emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _participant, _mintedAmount);
		emit Mint(_participant, _mintedAmount);
		
		return true;
    }
	
	function burn(address _participant, uint256 _value) public onlyBurner returns (bool _success) {
        require(_value > 0);
		require(balances[_participant] >= _value);   							 
		require(isKYCApproved(_participant) == true);
		balances[_participant] = balances[_participant].sub(_value);             
		_circulatingSupply = _circulatingSupply.sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      			 
		emit Transfer(_participant, 0, _value);
        emit Burn(_participant, _value);
        
		return true;
    }
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function circulatingSupply() public view returns (uint256) {
		return _circulatingSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}

contract VernamPrivatePreSale is OwnableToken, KYCControl {
	using SafeMath for uint256;

	VernamCrowdSaleToken public vernamCrowdsaleToken;
	
	mapping(address => uint256) public privatePreSaleTokenBalances;
	mapping(address => uint256) public weiBalances;
	
	uint256 constant public minimumContributionWeiByOneInvestor = 25000000000000000000 wei;
	uint256 public privatePreSalePrice = 100000000000000 wei;
	uint256 public totalSupplyInWei = 5000000000000000000000 wei;
	uint256 public totalTokensForSold = 50000000000000000000000000; 
	uint256 public privatePreSaleSoldTokens;
	uint256 public totalInvested;
	
	address public beneficiary;
	
	function VernamPrivatePreSale() public {
		beneficiary = 0xd977af9f1cf2cf615ab7d61c84aabb315b9a0337;
		vernamCrowdsaleToken = VernamCrowdSaleToken(0x6d908a2ef63aeac21cb2b5c3d32a145f14144b38);
	}
	
	function() public payable {
		buyPreSale(msg.sender, msg.value);
	}
	
	function buyPreSale(address _participant, uint256 _value) payable public {
		require(_value >= minimumContributionWeiByOneInvestor);
		require(totalSupplyInWei >= totalInvested.add(_value));
		
		beneficiary.transfer(_value);
		
		weiBalances[_participant] = weiBalances[_participant].add(_value);
		
		totalInvested = totalInvested.add(_value);
		
		uint256 tokens = ((_value).mul(1 ether)).div(privatePreSalePrice);
		
		privatePreSaleSoldTokens = privatePreSaleSoldTokens.add(tokens);
		privatePreSaleTokenBalances[_participant] = privatePreSaleTokenBalances[_participant].add(tokens);
		
		vernamCrowdsaleToken.mintToken(_participant, tokens);
	}
	
	function getPrivatePreSaleTokenBalance(address _participant) public view returns(uint256) {
		return privatePreSaleTokenBalances[_participant];
	}	

	function getWeiBalance(address _participant) public view returns(uint256) {
		return weiBalances[_participant];
	}
	
	function setBenificiary(address _benecifiaryAddress) public view onlyOwner {
		beneficiary = _benecifiaryAddress;
	}
}