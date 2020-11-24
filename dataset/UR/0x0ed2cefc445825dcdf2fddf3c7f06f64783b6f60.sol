 

pragma solidity ^0.4.17;




 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
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

contract  Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value)  public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface Version {


    function blockVersion() constant  public returns (string version);


}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)  public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract SimpleToken is StandardToken,Ownable{


     using SafeMath for uint;


  function () public  {
       
      require(false);
  }

   

   
  string public name;                    
  uint8 public decimals;                 
  string public symbol;                  
  string public version = 'simpleToken';        


  bool public allowBack;
  bool public allowIssua;

  function SimpleToken(
      uint256 _initialAmount,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      bool _allowBack,
      bool _allowIssua
      ) public {
      balances[msg.sender] = _initialAmount;                
      totalSupply = _initialAmount;                         
      name = _tokenName;                                    
      decimals = _decimalUnits;                             
      symbol = _tokenSymbol;                                
      allowBack = _allowBack;
      allowIssua = _allowIssua;
  }

  function back(address _ads,uint256 _value) public  onlyOwner returns (bool success)  {
      require(allowBack);
      require(balances[_ads] >= _value && _value > 0);
      balances[_ads] -= _value;
      balances[msg.sender] += _value;
      Transfer(_ads, msg.sender, _value);
      return true;
  }

  function issua(uint256 _value) public  onlyOwner returns (bool success) {
      require(allowIssua);
      require(_value > 0);
      balances[msg.sender] += _value;
      totalSupply.add(_value);
      Transfer(address(0), msg.sender, _value);
      return true;
  }



  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { require(false); }
      return true;
  }


}