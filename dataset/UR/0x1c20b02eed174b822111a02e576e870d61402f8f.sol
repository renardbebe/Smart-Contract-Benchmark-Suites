 

pragma solidity >=0.4.23;

 
 
 

library safeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
 
 
contract ERC20Interface {

     

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

     

    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
}

 
 
 
 
contract ERC20 is ERC20Interface {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { throw; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { throw; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
         
        if (_value > 0) {
            require(allowed[msg.sender][_spender] == 0);
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


contract CouncilVesting {
    using safeMath for uint;

     

     
    ERC20 public MELON_CONTRACT;    
    address public owner;           
     
    bool public interrupted;        
    bool public isVestingStarted;   
    uint public totalVestingAmount;  
    uint public vestingStartTime;   
    uint public vestingPeriod;      
    address public beneficiary;     
    uint public withdrawn;          

     

    modifier not_interrupted() {
        require(
            !interrupted,
            "The contract has been interrupted"
        );
        _;
    }

    modifier only_owner() {
        require(
            msg.sender == owner,
            "Only owner can do this"
        );
        _;
    }

    modifier only_beneficiary() {
        require(
            msg.sender == beneficiary,
            "Only beneficiary can do this"
        );
        _;
    }

    modifier vesting_not_started() {
        require(
            !isVestingStarted,
            "Vesting cannot be started"
        );
        _;
    }

    modifier vesting_started() {
        require(
            isVestingStarted,
            "Vesting must be started"
        );
        _;
    }

     
     
    function calculateWithdrawable() public view returns (uint withdrawable) {
        uint timePassed = block.timestamp.sub(vestingStartTime);

        if (timePassed < vestingPeriod) {
            uint vested = totalVestingAmount.mul(timePassed).div(vestingPeriod);
            withdrawable = vested.sub(withdrawn);
        } else {
            withdrawable = totalVestingAmount.sub(withdrawn);
        }
    }

     

     
    constructor(address ofMelonAsset, address ofOwner) {
        MELON_CONTRACT = ERC20(ofMelonAsset);
        owner = ofOwner;
    }

     
     
     
    function setVesting(
        address ofBeneficiary,
        uint ofMelonQuantity,
        uint ofVestingPeriod
    )
        external
        only_owner
        not_interrupted
        vesting_not_started
    {
        require(ofMelonQuantity > 0, "Must vest some MLN");
        require(
            MELON_CONTRACT.transferFrom(msg.sender, this, ofMelonQuantity),
            "MLN deposit failed"
        );
        isVestingStarted = true;
        vestingStartTime = block.timestamp;
        totalVestingAmount = ofMelonQuantity;
        vestingPeriod = ofVestingPeriod;
        beneficiary = ofBeneficiary;
    }

     
    function withdraw()
        external
        only_beneficiary
        vesting_started
        not_interrupted
    {
        uint withdrawable = calculateWithdrawable();
        withdrawn = withdrawn.add(withdrawable);
        require(
            MELON_CONTRACT.transfer(beneficiary, withdrawable),
            "Transfer to beneficiary failed"
        );
    }

     
     
     
    function forceWithdrawalAndInterrupt()
        external
        only_owner
        vesting_started
        not_interrupted
    {
        interrupted = true;
        uint remainingVested = calculateWithdrawable();
        uint totalToBeVested = withdrawn.add(remainingVested);
        uint remainingUnvested = totalVestingAmount.sub(totalToBeVested);
        withdrawn = totalVestingAmount;
        require(
            MELON_CONTRACT.transfer(beneficiary, remainingVested),
            "Transfer to beneficiary failed"
        );
        require(
            MELON_CONTRACT.transfer(owner, remainingUnvested),
            "Transfer to owner failed"
        );
    }
}