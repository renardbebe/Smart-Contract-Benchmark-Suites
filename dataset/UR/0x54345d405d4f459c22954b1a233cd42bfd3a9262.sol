 

 


pragma solidity ^0.4.18;


 

 


 


 


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 


 
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
 

 

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address minter;

    modifier onlyMinter(){
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) onlyMinter {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }
}
 
 



 




 
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data);

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
 
 

 

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) payable;
}

 

 
contract ERC23PayableToken is BasicToken, ERC23{
     
    function transfer(address to, uint value, bytes data){
        transferAndPay(to, value, data);
    }

     
     
    function transfer(address to, uint value) returns (bool){
        bytes memory empty;
        transfer(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes data) payable {

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if(codeLength>0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if(msg.value > 0){
            to.transfer(msg.value);
        }

        Transfer(msg.sender, to, value);
        if(data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}
 


contract NYXToken is MintableToken, ERC23PayableToken {
    string public constant name = "NYX Token";
    string public constant symbol = "NYX";

    bool public transferEnabled = true;

     
    uint private constant CAP = 15*(10**6);

    function mint(address _to, uint _amount){
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    function NYXToken(address team) {
         
        transferOwnership(team);
         
        minter = msg.sender; 
         
        mint(team, 3000000);
    }

     
    function transferAndPay(address to, uint value, bytes data) payable{
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function enableTransfer(bool enabled) onlyOwner{
        transferEnabled = enabled;
    }

}