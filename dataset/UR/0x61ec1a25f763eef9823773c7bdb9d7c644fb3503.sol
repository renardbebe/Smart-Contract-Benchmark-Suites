 

pragma solidity 0.5.2;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract Freeze is Ownable, ERC20 {
  
    using SafeMath for uint256;

    uint256 public endOfIco;
    uint256 public unlockSchema = 12;

    struct Group {
        address[] holders;
        uint until;
    }
    
     
    uint public groups;
    
    address[] public gofindAllowedAddresses;  
    
     
    mapping (uint => Group) public lockup;
    
     
    modifier lockupEnded (address _holder, address _recipient, uint256 actionAmount) {
        uint index = indexOf(_recipient, gofindAllowedAddresses);
        if (index == 0) {
            bool freezed;
            uint groupId;
            (freezed, groupId) = isFreezed(_holder);
            
            if (freezed) {
                if (lockup[groupId-1].until < block.timestamp)
                    _;
                    
                else if (getFullMonthAfterIco() != 0) {
                    uint256 available = getAvailableAmount();
                    if (actionAmount > available)
                        revert("Your holdings are freezed and your trying to use amount more than available");
                    else 
                        _;
                }
                else 
                    revert("Your holdings are freezed, wait until transfers become allowed");
            }
            else 
                _;
        }
        else
        _;
    }
    
     
    function changeEndOfIco (uint256 _date) public onlyOwner returns (bool) {
        endOfIco = _date;
    }
    
    function addGofindAllowedAddress (address _newAddress) public onlyOwner returns (bool) {
        require(indexOf(_newAddress, gofindAllowedAddresses) == 0, "that address already exists");
        gofindAllowedAddresses.push(_newAddress);
        return true;
    }
	
	 
    function isFreezed (address _holder) public view returns(bool, uint) {
        bool freezed = false;
        uint i = 0;
        while (i < groups) {
            uint index  = indexOf(_holder, lockup[i].holders);

            if (index == 0) {
                if (checkZeroIndex(_holder, i)) {
                    freezed = true;
                    i++;
                    continue;
                }  
                else {
                    i++;
                    continue;
                }
            } 
        
            if (index != 0) {
                freezed = true;
                i++;
                continue;
            }
            i++;
        }
        if (!freezed) i = 0;
        
        return (freezed, i);
    }
  
	 
    function indexOf (address element, address[] memory at) internal pure returns (uint) {
        for (uint i=0; i < at.length; i++) {
            if (at[i] == element) return i;
        }
        return 0;
    }
  
	 
    function checkZeroIndex (address _holder, uint lockGroup) internal view returns (bool) {
        if (lockup[lockGroup].holders[0] == _holder)
            return true;
            
        else 
            return false;
    }

     
    function getAvailableAmount () internal view returns (uint256) {
        uint256 monthes = getFullMonthAfterIco();
        uint256 balance = balanceOf(msg.sender);
        uint256 monthShare = balance.div(unlockSchema);
        uint256 available = monthShare * monthes;
        return available;
    }
    
     
    function getFullMonthAfterIco () internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < endOfIco)
            return 0;
        else {
            uint256 delta = currentTime - endOfIco;
            uint256 step = 2592000;
            if (delta > step) {
                uint256 times = delta.div(step);
                return times;
            }
            else {
                return 0;
            }
        }
    }
  
	 
    function setGroup (address[] memory _holders, uint _until) public onlyOwner returns (bool) {
        lockup[groups].holders = _holders;
        lockup[groups].until   = _until;
        
        groups++;
        return true;
    }
}

 
contract PausableToken is Freeze {

    function transfer(address _to, uint256 _value) public lockupEnded(msg.sender, _to, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public lockupEnded(msg.sender, _to, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public lockupEnded(msg.sender, _spender, _value) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseAllowance(address _spender, uint256 _addedValue)
        public lockupEnded(msg.sender, _spender, _addedValue) returns (bool success)
    {
        return super.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public lockupEnded(msg.sender, _spender, _subtractedValue) returns (bool success)
    {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }
}


contract SingleToken is PausableToken {

    using SafeMath for uint256;
    
    event TokensBurned(address from, uint256 value);
    event TokensMinted(address to, uint256 value);

    string  public constant name      = "Gofind XR"; 

    string  public constant symbol    = "XR";

    uint32  public constant decimals  = 8;

    uint256 public constant maxSupply = 13E16;
    
    constructor() public {
        totalSupply().add(maxSupply);
        super._mint(msg.sender, maxSupply);
    }
    
    function burn (address account, uint256 value) public onlyOwner returns (bool) {
        super._burn(account, value);
        return true;
    }
    
    function burnFrom (address account, uint256 value) public onlyOwner returns (bool) {
        super._burnFrom(account, value);
        return true;
    }
    
    function mint (address account, uint256 value) public onlyOwner returns (bool) {
        super._mint(account, value);
        return true;
    }
  
}