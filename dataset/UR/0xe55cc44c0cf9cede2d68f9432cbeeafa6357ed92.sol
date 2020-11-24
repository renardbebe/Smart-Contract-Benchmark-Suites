 

 

pragma solidity ^0.5.9;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value); 

}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.9;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.5.9;


 
contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   event Approval(address indexed owner, address indexed spender, uint256 value);
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.9;



 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.5.9;


                                        
contract RozToken is StandardToken, Pausable {

  string public name = "ROZEUS";
  string public symbol = "ROZ";
  uint8 public decimals = 8 ;
  uint256 _totalSupply = 10000000000;  
       
  constructor() public {
    totalSupply_ = _totalSupply * 10**uint(decimals);
    
    uint256 sale_fund = 2500000000 * 10**uint(decimals);
    uint256 team_fund = 500000000 * 10**uint(decimals);
    uint256 platform_fund = 4000000000 * 10**uint(decimals);
    uint256 ecosystem_fund = 2000000000 * 10**uint(decimals);
    uint256 bounty_fund = 1000000000 * 10**uint(decimals);

    balances[0x3B71AB34A2d5e28B5E3E2B6248D4D45D12f664CC] = sale_fund;
    balances[0x297f0a58e006A121C7af4F7B4Dd8a98383DC402C] = team_fund;
    balances[0x3dd7Ad80806F59dD62dfFd51c4D078c4AdbB048f] = platform_fund;
    balances[0x93f77A45933A22FA4bc43A9ceE3D707d2E537E2a] = ecosystem_fund;
    balances[0x16C5EB21D3441eF11815CFbF2B34861264F87924] = bounty_fund;
    
    emit Transfer(address(0), 0x3B71AB34A2d5e28B5E3E2B6248D4D45D12f664CC, sale_fund);
    emit Transfer(address(0), 0x297f0a58e006A121C7af4F7B4Dd8a98383DC402C, team_fund);
    emit Transfer(address(0), 0x3dd7Ad80806F59dD62dfFd51c4D078c4AdbB048f, platform_fund);
    emit Transfer(address(0), 0x93f77A45933A22FA4bc43A9ceE3D707d2E537E2a, ecosystem_fund);
    emit Transfer(address(0), 0x16C5EB21D3441eF11815CFbF2B34861264F87924, bounty_fund);
  }  

  function transfer( address to, uint256 value ) public whenNotPaused returns (bool)  {   
    return super.transfer(to, value);      
  }

  function transferFrom(address from, address to, uint256 value ) public whenNotPaused returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value ) public whenNotPaused returns (bool) {
    return super.approve(spender, value);
  }
   
  function increaseApproval( address _spender, uint256 _addedValue ) public whenNotPaused returns (bool)  {    
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval( address _spender, uint256 _subtractedValue ) public whenNotPaused returns (bool) {    
    return super.decreaseApproval( _spender, _subtractedValue );
  }
}