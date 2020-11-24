 

pragma solidity ^0.4.21;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit  Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit  Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MandalaToken is MintableToken {

    using SafeMath for uint256;
    string public name = "MANDALA TOKEN";
    string public   symbol = "MDX";
    uint public   decimals = 18;
    bool public  TRANSFERS_ALLOWED = false;
    uint256 public MAX_TOTAL_SUPPLY = 400000000 * (10 **18);


    struct LockParams {
        uint256 TIME;
        address ADDRESS;
        uint256 AMOUNT;
    }

    LockParams[] public  locks;

    event Burn(address indexed burner, uint256 value);

    function burnFrom(uint256 _value, address victim) onlyOwner canMint {
        require(_value <= balances[victim]);

        balances[victim] = balances[victim].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        Burn(victim, _value);
    }

    function burn(uint256 _value) onlyOwner {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        Burn(msg.sender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        require(canBeTransfered(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }


    function lock(address _to, uint256 releaseTime, uint256 lockamount) onlyOwner public returns (bool) {

         
         
         
         
         

        LockParams memory lockdata;
        lockdata.TIME = releaseTime;
        lockdata.AMOUNT = lockamount;
        lockdata.ADDRESS = _to;

        locks.push(lockdata);

        return true;
    }

    function canBeTransfered(address addr, uint256 value) returns (bool){
        for (uint i=0; i<locks.length; i++) {
            if (locks[i].ADDRESS == addr){
                if ( value > balanceOf(addr).sub(locks[i].AMOUNT) && locks[i].TIME > now){

                    return false;
                }
            }
        }

        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        if (totalSupply_.add(_amount) > MAX_TOTAL_SUPPLY){
            return false;
        }

        return super.mint(_to, _amount);
    }


    function transfer(address _to, uint256 _value) returns (bool){
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        require(canBeTransfered(msg.sender, _value));

        return super.transfer(_to, _value);
    }

    function stopTransfers() onlyOwner {
        TRANSFERS_ALLOWED = false;
    }

    function resumeTransfers() onlyOwner {
        TRANSFERS_ALLOWED = true;
    }

}