 

pragma solidity ^0.4.18;
 

 
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


contract ERC20 {

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}



contract TokenERC20 is ERC20, Ownable{
     
    string public name;
    string public symbol;
    uint8  public decimals = 18;
     
    using SafeMath for uint256;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;


     
    event Burn(address indexed from, uint256 value);


     
    function TokenERC20(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        decimals = _decimals;

        totalSupply = _initialSupply * 10 ** uint256(decimals);   
        balances[msg.sender] = totalSupply;                 
    }

         
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }
    

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);

        require(_value >= 0);
         
        uint previousBalances = balances[_from].add(balances[_to]);
          
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        return _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        if (approve(_spender, _value)) {
            TokenRecipient spender = TokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }


   
  function transferForMultiAddresses(address[] _addresses, uint256[] _amounts)  public returns (bool) {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_amounts[i] <= balances[msg.sender]);
      require(_amounts[i] > 0);

       
      balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
      emit Transfer(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }

     
    function burn(uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] = balances[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

         
    function burnFrom(address _from, uint256 _value) public returns(bool) {
        require(balances[_from] >= _value);                 
        require(_value <= allowances[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                                  
        emit Burn(_from, _value);
        return true;
    }


     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        require(allowances[msg.sender][_spender].add(_addedValue) > allowances[msg.sender][_spender]);

        allowances[msg.sender][_spender] =allowances[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }


}


contract ZJLToken is TokenERC20 {

    function ZJLToken() TokenERC20(2500000000, "ZJLToken", "ZJLT", 18) public {

    }
	
	function () payable public {
       
       
      require(false);
    }
}