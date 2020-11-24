 

 
pragma solidity ^0.4.24;
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract EIP20Interface {
     
     
    uint256 public totalSupply;
     
     
    function balanceOf(address _owner) public view returns (uint256 balance);
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     
     
     
     
    function approve(address _spender, uint256 _value) public returns(bool success);
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,uint256 _value);
}


contract BTT is EIP20Interface,Ownable,SafeMath,Pausable{
     
    string public constant name ="Bamboo Treasure Token";
    string public constant symbol = "BTT";
    uint8 public constant decimals = 18;
    string  public version  = 'v0.1';
    uint256 public constant initialSupply = 1010101010;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    constructor() public{
        totalSupply = initialSupply*10**uint256(decimals);                         
        balances[msg.sender] = totalSupply;              
    }

    function balanceOf(address _account) public view returns (uint) {
        return balances[_account];
    }

    function _transfer(address _from, address _to, uint _value) internal whenNotPaused returns(bool) {
        require(_to != address(0x0)&&_value>0);
        require(balances[_from] >= _value);
        require(safeAdd(balances[_to],_value) > balances[_to]);

        uint previousBalances = safeAdd(balances[_from],balances[_to]);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        emit Transfer(_from, _to, _value);
        assert(safeAdd(balances[_from],balances[_to]) == previousBalances);
        return true;
    }


    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success){
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender],_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowances[msg.sender][_spender] = safeAdd(allowances[msg.sender][_spender],_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
  }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
            uint oldValue = allowances[msg.sender][_spender];
            if (_subtractedValue > oldValue) {
              allowances[msg.sender][_spender] = 0;
            } else {
              allowances[msg.sender][_spender] = safeSub(oldValue,_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
            return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function withdrawETH (address _addr) public onlyOwner returns(bool res) {
        _addr.transfer(address(this).balance);
        return true;
    }
    
    function() payable public {
        require (msg.value >= 0.001 ether);
    }
    

}