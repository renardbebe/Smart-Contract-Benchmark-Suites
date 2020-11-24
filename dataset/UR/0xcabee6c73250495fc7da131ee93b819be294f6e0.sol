 

pragma solidity ^0.4.13;

 
library SafeMath {
    function add(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract preDGZToken is StandardToken {
    using SafeMath for uint256;

     
    string public constant name = "Dogezer preDGZ Token";
    string public constant symbol = "preDGZ";
    uint8 public decimals = 8;
    uint256 public totalSupply = 200000000000000;

     
    function preDGZToken() 
    {
        balances[msg.sender] = totalSupply;               
    }
}



contract DogezerPreICOCrowdsale is Haltable{
    using SafeMath for uint;
    string public name = "Dogezer preITO";

    address public beneficiary;
    uint public startTime;
    uint public duration;


    uint public fundingGoal; 
    uint public amountRaised; 
    uint public price; 
    preDGZToken public tokenReward;

    mapping(address => uint256) public balanceOf;

    event SaleFinished(uint finishAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool public crowdsaleClosed = false;


     
    function DogezerPreICOCrowdsale(
        address addressOfTokenUsedAsReward,
		address addressOfBeneficiary
    ) {
        beneficiary = addressOfBeneficiary;
        startTime = 1504270800;
        duration = 707 hours;
        fundingGoal = 4000 * 1 ether;
        amountRaised = 0;
        price = 0.00000000002 * 1 ether;
        tokenReward = preDGZToken(addressOfTokenUsedAsReward);
    }

    modifier onlyAfterStart() {
        require (now >= startTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require (now <= startTime + duration);
        _;
    }

     
    function () payable stopInEmergency onlyAfterStart onlyBeforeEnd
    {
		require (msg.value >= 0.002 * 1 ether);
        require (crowdsaleClosed == false);
        require (fundingGoal >= amountRaised + msg.value);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;  
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true); 
        if (amountRaised == fundingGoal)
        {
            crowdsaleClosed = true;
            SaleFinished(amountRaised);
        }
    }
 
   function withdrawal (uint amountWithdraw) onlyOwner
   {
		beneficiary.transfer(amountWithdraw);
   }
   
   function changeBeneficiary(address newBeneficiary) onlyOwner {
		if (newBeneficiary != address(0)) {
		  beneficiary = newBeneficiary;
		}
	}
   
   function finalizeSale () onlyOwner
   {
       require (crowdsaleClosed == false);
       crowdsaleClosed = true;
       SaleFinished(amountRaised);
   }
}