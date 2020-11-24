 

pragma solidity ^0.4.18;

 
library SafeMath {
    function add(uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) pure internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}


 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require (!halted);
    _;
  }

  modifier onlyInEmergency {
    require (halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract WWWToken is StandardToken {
    using SafeMath for uint256;

     
    string public constant name = "Wowander WWW Token";
    string public constant symbol = "WWW";
    uint8 public decimals = 8;
    uint256 public totalSupply = 100 * 0.1 finney;

     
    function WWWToken() public
    {
        balances[msg.sender] = totalSupply;               
    }
}


contract WowanderICOPrivateCrowdSale is Haltable{
    using SafeMath for uint;
    string public name = "Wowander Private Sale ITO";

    address public beneficiary;
    uint public startTime;
    uint public duration;
    uint public tokensContractBalance;
    uint public price; 
    uint public discountPrice; 
    WWWToken public tokenReward;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public whiteList;

    event FundTransfer(address backer, uint amount, bool isContribution);
    
    bool public crowdsaleClosed = false;
    uint public tokenOwnerNumber = 0;
     
    uint public constant tokenOwnerNumberMax = 3;   
    uint public constant minPurchase = 0.01 * 1 ether;
    uint public constant discountValue = 1.0 * 1 ether;

     
    function WowanderICOPrivateCrowdSale(
        address addressOfTokenUsedAsReward,
		address addressOfBeneficiary
    ) public
    {
        beneficiary = addressOfBeneficiary;
         
        startTime = 1516021200 - 3600 * 24;  
        duration = 744 hours;
		tokensContractBalance =  5 * 0.1 finney;
        price = 0.000000000005 * 1 ether;
        discountPrice = 0.000000000005 * 1 ether * 0.9;
        tokenReward = WWWToken(addressOfTokenUsedAsReward);
    }

    modifier onlyAfterStart() {
        require (now >= startTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require (now <= startTime + duration);
        _;
    }

     
    function () payable stopInEmergency onlyAfterStart onlyBeforeEnd public
    {
        require (msg.value >= minPurchase);
        require (crowdsaleClosed == false);
        require (tokensContractBalance > 0);
        require (whiteList[msg.sender] == true);
		
		uint currentPrice = price;
		
        if (balanceOf[msg.sender] == 0)
        {
            require (tokenOwnerNumber < tokenOwnerNumberMax);
            tokenOwnerNumber++;
        }

        if (msg.value >= discountValue)
        {
            currentPrice = discountPrice;
        }		
		
		uint amountSendTokens = msg.value / currentPrice;
		
		if (amountSendTokens > tokensContractBalance)
		{
			uint refund = msg.value - (tokensContractBalance * currentPrice);
			amountSendTokens = tokensContractBalance;
			msg.sender.transfer(refund);
			FundTransfer(msg.sender, refund, true);
			balanceOf[msg.sender] += (msg.value - refund);
		}
		else 
		{
			balanceOf[msg.sender] += msg.value;
		}
		
		tokenReward.transfer(msg.sender, amountSendTokens);
		FundTransfer(msg.sender, amountSendTokens, true);
		
		tokensContractBalance -= amountSendTokens;

    }

    function joinWhiteList (address _address) public onlyOwner
    {
        if (_address != address(0)) 
        {
            whiteList[_address] = true;
        }
    }
	
    function finalizeSale () public onlyOwner
    {
       require (crowdsaleClosed == false);
       crowdsaleClosed = true;
    }

    function reopenSale () public onlyOwner
    {
       crowdsaleClosed = false;
    }

    function setPrice (uint _price) public onlyOwner
    {
        if (_price != 0)
        {
            price = _price;
        }
    }

    function setDiscount (uint _discountPrice) public onlyOwner
    {
        if (_discountPrice != 0)
        {
            discountPrice = _discountPrice;
        }
    }
	
    function fundWithdrawal (uint _amount) public onlyOwner
    {
        beneficiary.transfer(_amount);
    }
   
    function tokenWithdrawal (uint _amount) public onlyOwner
    {
        tokenReward.transfer(beneficiary, _amount);
    }
	
    function changeBeneficiary(address _newBeneficiary) public onlyOwner 
	{
        if (_newBeneficiary != address(0)) {
            beneficiary = _newBeneficiary;
        }
	}	
}