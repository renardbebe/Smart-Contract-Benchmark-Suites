 

pragma solidity 0.5.0;   


 
contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;  
  mapping(address => uint256) public holdersWithdrows;
  
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    uint256 _buffer = holdersWithdrows[msg.sender].mul(_value).div(balances[msg.sender]);
    holdersWithdrows[_to] += _buffer;
    holdersWithdrows[msg.sender] -= _buffer;
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

     
     
    require(_value != 0);
    uint256 _buffer = holdersWithdrows[msg.sender].mul(_value).div(balances[msg.sender]);
    holdersWithdrows[_to] += _buffer;
    holdersWithdrows[msg.sender] -= _buffer;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 
contract DepositAsset is StandardToken {
    
    using SafeMath for uint256;
    
    string public constant name = "Deposit Asset";
  
    string public constant symbol = "DA";
  
    uint32 public constant decimals = 6;

    uint256 private _totalSupply = 200000000000000;  
    
    uint public _totalWithdrow  = 0;
    
    uint public total_withdrows  = 0;
    
    constructor () public {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

	function totalSupply() public view returns(uint256 total) {
        return _totalSupply;
    }
    
     
    function () external payable {
        if (msg.value == 1 wei) {
            require(balances[msg.sender] > 0);
        
            uint256 _totalDevidends = devidendsOf(msg.sender);
            holdersWithdrows[msg.sender] += _totalDevidends;
            _totalWithdrow += _totalDevidends;
            
            msg.sender.transfer(_totalDevidends);
        }
    }
    
    /* TEST / function holdersWithdrowsOf(address _owner) public constant returns(uint256 hw) {
        return holdersWithdrows[_owner];
    } 
    function getDevidends() public returns (bool success){
        require(balances[msg.sender] > 0);
        
        uint256 _totalDevidends = devidendsOf(msg.sender);
        holdersWithdrows[msg.sender] += _totalDevidends;
        _totalWithdrow += _totalDevidends;
        
        msg.sender.transfer(_totalDevidends);
        
        return true;
    }
    function devidendsOf(address _owner) public view returns (uint256 devidends) {
        address self = address(this);
         
        return self.balance
            .add(_totalWithdrow)
            .mul(balances[_owner])
            .div(_totalSupply)
            .sub(holdersWithdrows[_owner]);
    }
   
    function fund() public payable returns(bool success) {
        success = true;
    }
}