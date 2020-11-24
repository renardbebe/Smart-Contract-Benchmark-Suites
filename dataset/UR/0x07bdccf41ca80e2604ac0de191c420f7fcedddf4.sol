 

pragma solidity ^0.5.10;

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

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Error: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Error: addition overflow");

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "Error: division overflow"); 
    uint256 c = a / b;

    return c;
  }
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require((c / a == b), "Error: multiplication overflow");
    return c;
  }
  
}


contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to the zero address not allowed");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address not allowed");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address not allowed");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address not allowed");
        require(spender != address(0), "ERC20: approve to the zero address not allowed");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(value));
    }
    
    function distribution(address[] memory holdersAddresses, uint256[] memory volumeArray, uint256 _todayEmission, uint256 totalVolume, uint256 _emissionLeft, uint256 _emitCap) internal returns (uint256) {
        require((_emitCap>_totalSupply), "Emission: Emission capacity has been reached");
        
        uint256 amountEmitted = 0;
        _todayEmission = _todayEmission.mul(10000);
        uint256 amount = _todayEmission.div(totalVolume);
        for (uint i = 0; i < holdersAddresses.length; i++) {
            
            uint256 volume = volumeArray[i];
            uint256 toTransfer = amount.mul(volume);
            toTransfer = toTransfer.div(10000);
            address holderAddr = holdersAddresses[i];
            if(toTransfer > 0){
                if (_emissionLeft >= toTransfer) {
                    _mint(holderAddr, toTransfer);
                    _emissionLeft = _emissionLeft.sub(toTransfer);
                    amountEmitted = amountEmitted.add(toTransfer);
                }
            }
        }
        return amountEmitted;
    }
    
}


contract ERC20Burnable is ERC20 {
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

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
        require(isOwner(), "Access: You are not allowed to perform this action");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract PicToken is ERC20, ERC20Detailed, Ownable, ERC20Burnable {
  using SafeMath for uint256;

  uint8 constant DECIMALS = 18;

  uint256 private constant _emitCap = 50000000 * (10 ** uint256(DECIMALS));
  uint256 private _emitted;
  uint256 private todayEmission;
  uint256 private todayEmissionLeft;
  uint256 constant lowerBound = 20;  
  uint256 constant upperBound = 100;  
  
  uint constant oneDay = 86400;

  uint constant percentDecimals = 100000;
  
  uint createdAt;  
  uint releaseAt = now;  
  
  event Emit(uint256 emitAmount, uint256 percentage);
  event Distributed(address[] holdersAddresses, uint256[] volumeArray, uint256 totalVolume, uint256 emittedAmount);

  event AdminChanged(address indexed account);
  
  address private _admin;
  
  modifier onlyAdmin() {
      require(isAdmin(), "Admin: caller does not have the Admin role");
      _;
    }

  function isAdmin() public view returns (bool) {
      return msg.sender == _admin;
  }

  function changeAdmin(address account) public onlyOwner {
      _changeAdmin(account);
  }

  function _changeAdmin(address account) internal {
      require(account != address(0), "Admin: account is the zero address");
      _admin = account;
      emit AdminChanged(account);
  }  

  function emitTokens(uint256 _percentage) public onlyAdmin returns (uint256) {
      require((_emitted < _emitCap), "Error: Emission limit has been reached");
      require((releaseAt <= now), "Error: Release time has not passed");

      if (_percentage <= lowerBound) {
          _percentage = lowerBound;
      }
      if (_percentage >= upperBound) {
          _percentage = upperBound;
      }
      
      releaseAt = releaseAt + oneDay;  
      
       
      uint256 _emitAmount = _percentage.mul(_emitCap);
      _emitAmount = _emitAmount.div(percentDecimals);  
      
       
      _emitted = _emitted.add(_emitAmount);
      
       
      todayEmission = _emitAmount;
      todayEmissionLeft = todayEmission;
      
       
      emit Emit(_emitAmount, _percentage);
      
      return _emitAmount;

  }
  
    function distribute(address[] memory holdersAddresses, uint256[] memory volumeArray, uint256 totalVolume) public onlyAdmin returns (uint256) {
       
      require((todayEmissionLeft > 0), "Error: Distribution reached limit");
      uint256 _amount = distribution(holdersAddresses, volumeArray, todayEmission, totalVolume, todayEmissionLeft, _emitCap);
      todayEmissionLeft = todayEmissionLeft.sub(_amount);
      emit Distributed(holdersAddresses, volumeArray, totalVolume, _amount);
      return _amount;
    }
  
    function getTodayEmission() public view returns (uint256) {
        return todayEmission;
    }
    
    function getTodayEmissionLeft() public view returns (uint256) {
        return todayEmissionLeft;
    }
  
    function emitable() public view returns (bool) {
        return (releaseAt <= now);
    }
  
    function totalEmitCap() public pure returns (uint256) {
        return _emitCap;
    }

    function emitted() public view returns (uint256) {
        return _emitted;
    }
 

  constructor () public ERC20Detailed("THE PIC TOKEN", "PIC", DECIMALS) {
      createdAt = now;
      
       
       
       
      address emitTransferAccount = 0xf59aaab6B3685b23a9d8D19dC705861Ca9D37842;
      uint256 _AmountEmittedAlready = 539950 * (10 ** uint256(DECIMALS));
      _emitted = _emitted.add(_AmountEmittedAlready);
      _mint(emitTransferAccount, _AmountEmittedAlready);
      
  }
}