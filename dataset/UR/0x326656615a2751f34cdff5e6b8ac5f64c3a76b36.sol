 

pragma solidity ^0.4.11;


 
library SafeMath {
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

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}





 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}
 


contract BitnanRewardToken is StandardToken {
     
    string public constant NAME = "BitnanRewardToken";
    string public constant SYMBOL = "BRT";
    uint public constant DECIMALS = 18;
    uint256 public constant ETH_MIN_GOAL = 3000 ether;
    uint256 public constant ETH_MAX_GOAL = 6000 ether;
    uint256 public constant ORIGIN_ETH_BRT_RATIO = 3000;
    uint public constant UNSOLD_SOLD_RATIO = 50;
    uint public constant PHASE_NUMBER = 5;
    uint public constant BLOCKS_PER_PHASE = 30500;
    uint8[5] public bonusPercents = [
      20,
      15,
      10,
      5,
      0
    ];

     
    address public owner;
    uint public totalEthAmount = 0;
    uint public tokenIssueIndex = 0;
    uint public deadline;
    uint public durationInDays;
    uint public startBlock = 0;
    bool public isLeftTokenIssued = false;


     
    event TokenSaleStart();
    event TokenSaleEnd();
    event FakeOwner(address fakeOwner);
    event CommonError(bytes error);
    event IssueToken(uint index, address addr, uint ethAmount, uint tokenAmount);
    event TokenSaleSucceed();
    event TokenSaleFail();
    event TokenSendFail(uint ethAmount);

     
    modifier onlyOwner {
      if(msg.sender != owner) {
        FakeOwner(msg.sender);
        revert();
      }
      _;        
    }
    modifier beforeSale {
      if(!saleInProgress()) {
        _;
      }
      else {
        CommonError('Sale has not started!');
        revert();
      }
    }
    modifier inSale {
      if(saleInProgress() && !saleOver()) {
        _;
      }
      else {
        CommonError('Token is not in sale!');
        revert();
      }
    }
    modifier afterSale {
      if(saleOver()) {
        _;
      }
      else {
        CommonError('Sale is not over!');
        revert();
      }
    }
     
    function () payable {
      issueToken(msg.sender);
    }
    function issueToken(address recipient) payable inSale {
      assert(msg.value >= 0.01 ether);
      uint tokenAmount = generateTokenAmount(msg.value);
      totalEthAmount = totalEthAmount.add(msg.value);
      totalSupply = totalSupply.add(tokenAmount);
      balances[recipient] = balances[recipient].add(tokenAmount);
      IssueToken(tokenIssueIndex, recipient, msg.value, tokenAmount);
      if(!owner.send(msg.value)) {
        TokenSendFail(msg.value);
        revert();
      }
    }
    function issueLeftToken() internal {
      if(isLeftTokenIssued) {
        CommonError("Left tokens has been issued!");
      }
      else {
        require(totalEthAmount >= ETH_MIN_GOAL);
        uint leftTokenAmount = totalSupply.mul(UNSOLD_SOLD_RATIO).div(100);
        totalSupply = totalSupply.add(leftTokenAmount);
        balances[owner] = balances[owner].add(leftTokenAmount);
        IssueToken(tokenIssueIndex++, owner, 0, leftTokenAmount);
        isLeftTokenIssued = true;
      }
    }
    function BitnanRewardToken(address _owner) {
      owner = _owner;
    }
    function start(uint _startBlock) public onlyOwner beforeSale {
      startBlock = _startBlock;
      TokenSaleStart();
    }
    function close() public onlyOwner afterSale {
      if(totalEthAmount < ETH_MIN_GOAL) {
        TokenSaleFail();
      }
      else {
        issueLeftToken();
        TokenSaleSucceed();
      }
    }
    function generateTokenAmount(uint ethAmount) internal constant returns (uint tokenAmount) {
      uint phase = (block.number - startBlock).div(BLOCKS_PER_PHASE);
      if(phase >= bonusPercents.length) {
        phase = bonusPercents.length - 1;
      }
      uint originTokenAmount = ethAmount.mul(ORIGIN_ETH_BRT_RATIO);
      uint bonusTokenAmount = originTokenAmount.mul(bonusPercents[phase]).div(100);
      tokenAmount = originTokenAmount.add(bonusTokenAmount);
    }
     
    function saleInProgress() constant returns (bool) {
      return (startBlock > 0 && block.number >= startBlock);
    }
    function saleOver() constant returns (bool) {
      return startBlock > 0 && (saleOverInTime() || saleOverReachMaxETH());
    }
    function saleOverInTime() constant returns (bool) {
      return block.number >= startBlock + BLOCKS_PER_PHASE * PHASE_NUMBER;
    }
    function saleOverReachMaxETH() constant returns (bool) {
      return totalEthAmount >= ETH_MAX_GOAL;
    }
}