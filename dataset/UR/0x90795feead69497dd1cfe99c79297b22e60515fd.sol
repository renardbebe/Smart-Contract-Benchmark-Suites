 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract SynchroCoin is Ownable, StandardToken {

    string public constant symbol = "SYC";

    string public constant name = "SynchroCoin";

    uint8 public constant decimals = 12;
    

    uint256 public STARTDATE;

    uint256 public ENDDATE;

     
    uint256 public crowdSale;

     
     
    address public multisig;

    function SynchroCoin(
    uint256 _initialSupply,
    uint256 _start,
    uint256 _end,
    address _multisig) {
        totalSupply = _initialSupply;
        STARTDATE = _start;
        ENDDATE = _end;
        multisig = _multisig;
        crowdSale = _initialSupply * 55 / 100;
        balances[multisig] = _initialSupply;
    }

     
    uint256 public totalFundedEther;

     
    uint256 public totalConsideredFundedEther = 338;

    mapping (address => uint256) consideredFundedEtherOf;

    mapping (address => bool) withdrawalStatuses;

    function calcBonus() public constant returns (uint256){
        return calcBonusAt(now);
    }

    function calcBonusAt(uint256 at) public constant returns (uint256){
        if (at < STARTDATE) {
            return 140;
        }
        else if (at < (STARTDATE + 1 days)) {
            return 120;
        }
        else if (at < (STARTDATE + 7 days)) {
            return 115;
        }
        else if (at < (STARTDATE + 14 days)) {
            return 110;
        }
        else if (at < (STARTDATE + 21 days)) {
            return 105;
        }
        else if (at <= ENDDATE) {
            return 100;
        }
        else {
            return 0;
        }
    }


    function() public payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address participant) public payable {
        require(now >= STARTDATE);

        require(now <= ENDDATE);

         
        require(msg.value >= 100 finney);

        totalFundedEther = totalFundedEther.add(msg.value);

        uint256 _consideredEther = msg.value.mul(calcBonus()).div(100);
        totalConsideredFundedEther = totalConsideredFundedEther.add(_consideredEther);
        consideredFundedEtherOf[participant] = consideredFundedEtherOf[participant].add(_consideredEther);
        withdrawalStatuses[participant] = true;

         
        Fund(
        participant,
        msg.value,
        totalFundedEther
        );

         
        multisig.transfer(msg.value);
    }

    event Fund(
    address indexed buyer,
    uint256 ethers,
    uint256 totalEther
    );

    function withdraw() public returns (bool success){
        return proxyWithdraw(msg.sender);
    }

    function proxyWithdraw(address participant) public returns (bool success){
        require(now > ENDDATE);
        require(withdrawalStatuses[participant]);
        require(totalConsideredFundedEther > 1);

        uint256 share = crowdSale.mul(consideredFundedEtherOf[participant]).div(totalConsideredFundedEther);
        participant.transfer(share);
        withdrawalStatuses[participant] = false;
        return true;
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(now > ENDDATE);
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public
    returns (bool success)
    {
        require(now > ENDDATE);
        return super.transferFrom(_from, _to, _amount);
    }

}