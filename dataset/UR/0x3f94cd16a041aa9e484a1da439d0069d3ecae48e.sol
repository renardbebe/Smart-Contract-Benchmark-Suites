 

pragma solidity 0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
	event NewOwner(address indexed old, address indexed current);

	address public owner = msg.sender;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

  constructor () internal {
    owner = msg.sender;
  }

	function setOwner(address _new)
		external
		onlyOwner
	{
		emit NewOwner(owner, _new);
		owner = _new;
	}
}

 
 contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

contract Faucet is Ownable {
    using SafeMath for uint256;

     

    event TokenExchanged(address receiver, uint etherReceived, uint tokenSent);

     

    address public tokenAddress;
    uint16 public exchangeRate;  
    uint public exchangeLimit;  

     

    constructor(address _tokenAddress, uint16 _exchangeRate, uint _exchangeLimit) public {
        tokenAddress = _tokenAddress;
        exchangeRate = _exchangeRate;
        exchangeLimit = _exchangeLimit;
    }

    function() public payable {
        require(msg.value <= exchangeLimit);

        uint transferAmount = msg.value.mul(exchangeRate);
        require(ERC20(tokenAddress).transfer(msg.sender, transferAmount), "insufficient erc20 token balance");

        emit TokenExchanged(msg.sender, msg.value, transferAmount);
    }

    function withdrawEther(uint amount) onlyOwner public {
        owner.transfer(amount);
    }

    function withdrawToken(uint amount) onlyOwner public {
        ERC20(tokenAddress).transfer(owner, amount);
    }

    function getTokenBalance() public view returns (uint) {
        return ERC20(tokenAddress).balanceOf(this);
    }

    function getEtherBalance() public view returns (uint) {
        return address(this).balance;
    }

    function updateExchangeRate(uint16 newExchangeRate) onlyOwner public {
        exchangeRate = newExchangeRate;
    }

    function updateExchangeLimit(uint newExchangeLimit) onlyOwner public {
        exchangeLimit = newExchangeLimit;
    }
}