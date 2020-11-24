 

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
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



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
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


 
contract WagaToken is StandardToken {

    string public constant LOVEYOUFOREVER = "LIANGZAI";
    string public constant NAME = "WagaToken";
    string public constant SYMBOL = "WGT";
    uint public constant DECIMALS = 18;

     
    event InvalidCaller(address caller);

     
    event Issue(uint issueIndex, address addr, uint tokenAmount);

    uint public issueIndex = 0;

    uint constant totalAmount = 21000000;
     
    uint public issueAmount = 0.0;

    address owner;
    uint currentFactor = 10 ** DECIMALS;

    modifier onlyOwner {
        if (owner == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            revert();
        }
    }

    function WagaToken() {
        owner = msg.sender;
        totalSupply = 21 * 10 ** 24;
    }

     
     
    function issueTo(address addr,uint fee) onlyOwner {
        var tokenAmount =  21 * fee * getFactor();
        balances[addr] = balances[addr].add(tokenAmount);
        issueAmount = issueAmount.add(tokenAmount);
        Issue(issueIndex++, addr, tokenAmount);
    }


    function getFactor() internal returns (uint) {
        if(2 * (totalSupply - issueAmount) <= currentFactor * totalAmount) {
            currentFactor /= 2;
        }
        return currentFactor;
    }


}