 

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

   
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract UniversalMobileToken is Ownable {
    
    using SafeMath for uint;

     
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    string public name;
     
    string public symbol;

     
    uint public decimals;

     
    uint public totalSupply;

     
    bool public mintingIsFinished;

     
    bool public transferIsPossible;

    modifier onlyEmitter() {
        require(emitters[msg.sender] == true);
        _;
    }
    
    mapping (address => uint) public balances;
    mapping (address => bool) public emitters;
    mapping (address => mapping (address => uint)) internal allowed;
    
    constructor() Ownable() public {
        name = "Universal Mobile Token";
        symbol = "UMT";
        decimals = 18;   
         
        emitters[msg.sender] = true;
    }

     
    function finishMinting() public onlyOwner {
        mintingIsFinished = true;
        transferIsPossible = true;
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
         
        require(transferIsPossible);
        require(_to != address(0) && _to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
         
        require(transferIsPossible);

        require(_to != address(0) && _to != address(this));

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function addEmitter(address _emitter) public onlyOwner {
        emitters[_emitter] = true;
    }
    
     
    function removeEmitter(address _emitter) public onlyOwner {
        emitters[_emitter] = false;
    }
    
     
    function batchMint(address[] _adresses, uint[] _values) public onlyEmitter {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(minted(_adresses[i], _values[i]));
        }
    }

     
    function batchTransfer(address[] _adresses, uint[] _values) public {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(transfer(_adresses[i], _values[i]));
        }
    }

     
    function burn(address _from, uint _value) public onlyEmitter {
         
        require(!mintingIsFinished);

        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }

     
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }

     
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }

    function minted(address _to, uint _value) internal returns (bool) {
         
        require(!mintingIsFinished);
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}