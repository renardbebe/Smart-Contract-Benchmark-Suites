 

pragma solidity ^0.4.19;

 



 
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

 


contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
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


 


contract CellBlocksToken is EIP20Interface, Ownable {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    function CellBlocksToken() public {
        balances[msg.sender] = 25*(10**25);             
        totalSupply = 25*(10**25);                      
        name = "CellBlocks";                           
        decimals = 18;                                 
        symbol = "CLBK";                                
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        if (totalSupply > 83*(10**24) && block.timestamp >= 1529474460) {
            uint halfP = halfPercent(_value);
            burn(msg.sender, halfP);
            _value = SafeMath.sub(_value, halfP);
        }
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        if (totalSupply > 83*(10**24) && block.timestamp >= 1529474460) {
            uint halfP = halfPercent(_value);
            burn(_from, halfP);
            _value = SafeMath.sub(_value, halfP);
        }
        balances[_to] = SafeMath.add(balances[_to], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

     
     
     
    function halfPercent(uint _value) private pure returns(uint amount) {
        if (_value > 0) {
             
            uint temp = SafeMath.mul(_value, 5);
            amount = SafeMath.div(temp, 1000);

            if (amount == 0) {
                amount = 1;
            }
        }   
        else {
            amount = 0;
        }
        return;
    }

     
     
     
    function burn(address burner, uint256 _value) public {
        require(_value <= balances[burner]);
         
         
        if (_value > 0) {
            balances[burner] = SafeMath.sub(balances[burner], _value);
            totalSupply = SafeMath.sub(totalSupply, _value);
            Burn(burner, _value);
            Transfer(burner, address(0), _value);
        }
    }

    event Burn(address indexed burner, uint256 value);
}