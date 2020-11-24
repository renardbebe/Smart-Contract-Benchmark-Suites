 

pragma solidity ^0.4.18;

contract ERC20 {
	uint public totalSupply;
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	 

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20Token is ERC20 {
	using SafeMath for uint256;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) allowed;

	modifier onlyPayloadSize(uint size) {
		require(msg.data.length >= (size + 4));
		_;
	}

	function () public{
		revert();
	}

	function balanceOf(address _owner) public constant returns (uint balance) {
		return balances[_owner];
	}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
		_transferFrom(msg.sender, _to, _value);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		_transferFrom(_from, _to, _value);
		return true;
	}
	function _transferFrom(address _from, address _to, uint256 _value) internal {
		require(_value > 0);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
}

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
}

contract ZodiaqToken is ERC20Token, owned {
	string public name = 'Zodiaq Token';
	string public symbol = 'ZOD';
	uint8 public decimals = 6;

	uint256 public totalSupply = 50000000000000;		 

	address public reservationWallet;
	uint256 public reservationSupply = 11000000000000;	 

	address public bountyWallet;
	uint256 public bountySupply = 2000000000000;		 

	address public teamWallet;
	uint256 public teamSupply = 3500000000000;			 

	address public partnerWallet;
	uint256 public partnerSupply = 3500000000000;		 

	address public currentIcoWallet;
	uint256 public currentIcoSupply;


	function ZodiaqToken () public {
		balances[this] = totalSupply;
	}

	function setWallets(address _reservationWallet, address _bountyWallet, address _teamWallet, address _partnerWallet) public onlyOwner {
		reservationWallet = _reservationWallet;
		bountyWallet = _bountyWallet;
		teamWallet = _teamWallet;
		partnerWallet = _partnerWallet;

		_transferFrom(this, reservationWallet, reservationSupply);
		_transferFrom(this, bountyWallet, bountySupply);
		_transferFrom(this, teamWallet, teamSupply);
		_transferFrom(this, partnerWallet, partnerSupply);
	}

	 
	 
	 
	function setICO(address icoWallet, uint256 IcoSupply) public onlyOwner {
		allowed[this][icoWallet] = IcoSupply;
		Approval(this, icoWallet, IcoSupply);
		 

		currentIcoWallet = icoWallet;
		currentIcoSupply = IcoSupply;
	}

	function mintToken(uint256 mintedAmount) public onlyOwner {
		totalSupply = totalSupply.add(mintedAmount);
		balances[this] = balances[this].add(mintedAmount);
	}

	function burnBalance() public onlyOwner {
		balances[this] = 0;
	}
}

contract ZodiaqICO is owned {
	string public name;

	uint256 public saleStart;
	uint256 public saleEnd;

	uint256 public tokenPrice;

	ZodiaqToken public token;

	function balance() public constant returns (uint256 tokens) {
		return token.allowance(token, this);
	}

	function active() public constant returns (bool yes){
		return ((now > saleStart) && (now < saleEnd));
	}

	function canBuy() public constant returns (bool yes){
		return active();
	}

	function getBonus() public constant returns (uint256 bonus){
		return 0;
	}

	function stopForce() public onlyOwner {
		saleEnd = now;
	}

	function sendTokens(address _to, uint tokens) public onlyOwner {
		require(active() && token.transferFrom(token, _to, tokens));
	}
}

contract ZodiaqPrivateTokenSale is ZodiaqICO {

	function ZodiaqPrivateTokenSale (
		 
	) public {
		 
		token = ZodiaqToken(0x6488ab8f1DF285d5B70CCF57A489CD27888a4d14);

		name = 'Private Token Sale';
		saleStart = 1511989200;		 
		saleEnd = 1519938000;		 
	}

	function () public payable {
		revert();
	}

	function canBuy() public constant returns (bool yes){
		return false;
	}
}