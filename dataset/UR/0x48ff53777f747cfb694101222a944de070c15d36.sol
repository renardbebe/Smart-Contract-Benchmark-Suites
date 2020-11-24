 

pragma solidity ^0.4.17;

 
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

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) constant returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      hash = sha3(prefix, hash);
      return ecrecover(hash, v, r, s);
    }
  }

}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    require(_to != address(0));

     
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
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
  
   
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}













contract ValidationUtil {
    function requireNotEmptyAddress(address value){
        require(isAddressNotEmpty(value));
    }

    function isAddressNotEmpty(address value) internal returns (bool result){
        return value != 0;
    }
}












 

contract ImpToken is StandardToken, Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    bool public isDistributed;
    uint public distributedAmount;

    event UpdatedTokenInformation(string name, string symbol);

     
    function ImpToken(string _name, string _symbol, uint _totalSupply, uint _decimals) {
        require(_totalSupply != 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _totalSupply;
    }

     
    function distribute(address toAddress, uint tokenAmount) external onlyOwner {
        require(!isDistributed);

        balances[toAddress] = tokenAmount;

        distributedAmount = distributedAmount.add(tokenAmount);

        require(distributedAmount <= totalSupply);
    }

    function closeDistribution() external onlyOwner {
        require(!isDistributed);

        isDistributed = true;
    }

     
    function setTokenInformation(string newName, string newSymbol) external onlyOwner {
        name = newName;
        symbol = newSymbol;

         
        UpdatedTokenInformation(name, symbol);
    }

     
    function setDecimals(uint newDecimals) external onlyOwner {
        decimals = newDecimals;
    }
}






contract ImpCore is Ownable, ValidationUtil {
    using SafeMath for uint;
    using ECRecovery for bytes32;

     
    ImpToken public token;

     
    mapping (address => uint) private withdrawalsNonce;

    event Withdraw(address receiver, uint tokenAmount);
    event WithdrawCanceled(address receiver);

    function ImpCore(address _token) {
        requireNotEmptyAddress(_token);

        token = ImpToken(_token);
    }

    function withdraw(uint tokenAmount, bytes signedData) external {
        uint256 nonce = withdrawalsNonce[msg.sender] + 1;

        bytes32 validatingHash = keccak256(msg.sender, tokenAmount, nonce);

         
        address addressRecovered = validatingHash.recover(signedData);

        require(addressRecovered == owner);

         
        require(token.transfer(msg.sender, tokenAmount));

        withdrawalsNonce[msg.sender] = nonce;

        Withdraw(msg.sender, tokenAmount);
    }

    function cancelWithdraw() external {
        withdrawalsNonce[msg.sender]++;

        WithdrawCanceled(msg.sender);
    }


}