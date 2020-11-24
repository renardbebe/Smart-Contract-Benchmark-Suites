 

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

 
contract ERC20Basic {
    uint256 public totalSupply;
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

    mapping(address => uint256) balances;

     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
         
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
         
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
         
        return true;
    }

}

 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
         
         
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
         
        return true;
    }
}

contract UNTToken is MintableToken{

    string public constant name = "untx";
    string public constant symbol = "UNTX";
    uint32 public constant decimals = 8;
    mapping(address => uint256) public lockamount;
    address[] lockaddress;
    bool private isFreezed = false;

    function UNTToken() public {
        totalSupply = 2000000000E8;
        balances[msg.sender] = totalSupply;  
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(isFreezed == false);
        if(msg.sender == owner)
        {
            if(hasAddress(_to) == true)
            {
               lockamount[_to]+= _value;
            }
            else
            {
               lockaddress.push(_to);
               lockamount[_to] = _value;
            }

        }
        else if(hasAddress(msg.sender) == true)
        {

             require(balanceOf(msg.sender)-lockamount[msg.sender]>=_value);

        }


         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function lockToken(address target, uint256 amount) public
    {   require(owner == msg.sender);
        if(hasAddress(target) == false)
        {
            if(balanceOf(target)>=amount)
            {
              lockaddress.push(target);
              lockamount[target] = amount;
            }

        }
        else
        {
          if(balanceOf(target)-lockamount[target]>= amount)
          {

              lockamount[target] += amount;

          }

        }

    }

    function unlockToken(address target, uint256 amount) public
    {
        require(owner == msg.sender);
        if(hasAddress(target) == false)
        {

        }
        else
        {
          if(lockamount[target]>= amount)
          {

            lockamount[target]=lockamount[target]-amount;

          }

        }


    }

    function hasAddress(address target) private returns(bool)
    {

          for(uint i = 0; i< lockaddress.length; i++)
          {
              if(lockaddress[i] == target)
              {
                return true;
              }

          }
          return false;

    }

    function freezeToken() public
    {
       require(owner == msg.sender);
       isFreezed = true;
    }

    function unfreezeToken() public
    {
       require(owner == msg.sender);
       isFreezed = false;

    }




}