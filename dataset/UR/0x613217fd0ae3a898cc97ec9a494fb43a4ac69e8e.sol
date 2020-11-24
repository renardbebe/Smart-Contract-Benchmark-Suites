 

pragma solidity ^0.5.11;

 
library SafeMath256 {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
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
    require(msg.sender == owner, "Ownable: [onlyOwner]");
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "Ownable: _newOwner illegal");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "Pausable: not paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "Pausable: paused");
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
 

 
contract CoinMiner is Ownable, ERC20Basic, Pausable {
    using SafeMath256 for uint256;

    string private _name = "CoinMiner V1.1";
    string private _symbol = "COM";
    uint8 private _decimals = 6;
    uint256 private _totalSupply;
    mapping(address => uint256) internal balances;
     
    uint256 private _WHITELIST_TRIGGER = 1024000000;

     
    mapping (address => address) private _referee;
    mapping (address => address[]) private _referrals;
    mapping (address => bool) private _register;
     
    uint256 private _whitelistCounter = 0;

     
    uint8[10] private WHITELIST_REWARDS = [
        5,  
        4,  
        3,  
        2,  
        1  
    ];

     
    uint256 private _k1 = 1;
    uint256 private _k2 = 9765625;

     
    event Donate(address indexed account, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event JoinWhiteList(address indexed parent, address indexed child);

    constructor() public {
        _joinWhiteList(address(this), msg.sender);
    }

     
    function () external payable whenNotPaused {
        require(msg.value >= 1 ether, "CoinMiner: must greater 1 ether");

        require(!(balanceOf(msg.sender) > 0), "CoinMiner: balance is greater than zero");
        require(!isInWhiteList(msg.sender), "CoinMiner: already whitelisted");
        require(!_register[msg.sender], "CoinMiner: already register");
        uint256 award = 1024000000;
        uint256 useEther = award.mul(_k2).div(_k1);
        uint256 backEther = msg.value.sub(useEther);
         
        _register[msg.sender] = true;
         
        msg.sender.transfer(backEther);

        _mint(msg.sender, award);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_value == _WHITELIST_TRIGGER && isInWhiteList(_to) && !isInWhiteList(msg.sender)) {
             
             
            _joinWhiteList(_to, msg.sender);
            return _transfer(_to, _value);
        } else {
             
            return _transfer(_to, _value);
        }
    }

     
    function isInWhiteList(address account) private view returns(bool) {
        return _referee[account] != address(0);
    }

     
    function _joinWhiteList(address parent, address child) private returns (bool) {
         
        _referee[child] = parent;
         
        _referrals[parent].push(child);
         
        _whitelistCounter = _whitelistCounter.add(1);
        emit JoinWhiteList(parent, child);
        return true;
    }

     
    function _move(address from, address to, uint256 value) private {
        require(value <= balances[from], "CoinMiner: [_move] balance not enough");
        require(to != address(0), "CoinMiner: [_move] balance not enough");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
    }

     
    function _transfer(address to, uint256 value) private returns (bool) {
        _move(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function _mint(address to, uint256 value) private {
        _totalSupply = _totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }

     
    function _burn(address who, uint256 value) private {
        require(value <= balances[who], "CoinMiner: [_burn] value exceeds balance");
        balances[who] = balances[who].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(who, value);
        emit Transfer(who, address(0), value);
    }

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function whitelistOf(address who) public view returns (address[] memory) {
        return _referrals[who];
    }

     
    function parentOf(address who) public view returns(address) {
        return _referee[who];
    }

     
    function whitelistRewards() public view returns(uint8[10] memory) {
        return WHITELIST_REWARDS;
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

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function whitelistCounter() public view returns (uint256) {
        return _whitelistCounter;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function getScale() public view returns (uint256, uint256) {
        return (_k1, _k2);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "CoinMiner: [WithdrawEther] recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "CoinMiner: [WithdrawEther] amount exceeds balance");
        recipient.transfer(amount);
    }

     
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

     
    function burnByOwner(address who, uint256 value) external onlyOwner {
        _burn(who, value);
    }

     
    function setScale(uint256 k1, uint256 k2) external onlyOwner {
        _k1 = k1;
        _k2 = k2;
    }
}

 
 

contract CoinMinerPublicSale is Ownable {
    using SafeMath256 for uint256;

    string private _name = "CoinMinerPublicSale V1.1";

     
    struct Miner{
        uint256 time;
        uint256 etherAmount;
        bool isExist;
    }

     
    CoinMiner private _com;
     
    mapping(address => Miner) private _miners;
     
    uint256 _awardScale = 10;

     
    constructor(CoinMiner com) public {
        _com = com;
    }

     
    function () external payable {
         
        if (msg.value == 0) {
             
            _getMine(msg.sender);
        } else {
             
            _createMiner(msg.sender, msg.value);
             
            _dispatch(msg.sender, msg.value);
        }
    }

     
    function _createMiner(address who, uint256 etherValue) private {
        require(!_miners[who].isExist, "CoinMiner: you are already miner");
         
        uint256 comAmount = etherToCom(etherValue);
        uint256 award = comAmount.mul(_awardScale).div(100);
        _com.transfer(who, award);
         
        Miner memory miner = Miner(now, etherValue, true);
        _miners[msg.sender] = miner;
    }

     
    function _dispatch(address from, uint256 etherValue) private {
        uint8[10] memory rewards = _com.whitelistRewards();
        address pt = from;
        for (uint8 i = 0; i < rewards.length; i++) {
            pt = _com.parentOf(pt);
            if (pt == address(0)) {
                break;
            }
            uint256 vip = _com.whitelistOf(pt).length;
            if (vip < i + 1) {
                continue;
            }
            uint256 value = etherValue.mul(rewards[i]).div(100);
            require(address(this).balance >= value, "balance not enough");
            address payable recipient = address(uint160(pt));
            recipient.transfer(value);
        }
    }

     
    function _getMine(address  who) private {
        require(_miners[who].isExist, "CoinMiner: [_getAward] you are not a miner");
        Miner storage miner = _miners[msg.sender];
        require(now > miner.time, "CoinMiner: [_getAward] time is illegal, now less than taget time");
        uint256 timeDiff = now.sub(miner.time);
        uint256 etherMine = 0;
        uint256 comMine = 0;
        if (timeDiff > 12 * 30 days) {
             
            etherMine = miner.etherAmount.mul(2);
            comMine = _etherToCom(miner.etherAmount).mul(11).div(5);
        } else if(timeDiff > 6 * 30 days) {
             
            etherMine = miner.etherAmount.mul(3).div(2);
            comMine = _etherToCom(miner.etherAmount).mul(3).div(2);
        } else if (timeDiff > 3 * 30 days) {
             
            etherMine = miner.etherAmount;
            comMine = _etherToCom(miner.etherAmount);
        } else if (timeDiff > 1 * 30 days) {
             
            etherMine = miner.etherAmount.mul(3).div(5);
            comMine = _etherToCom(miner.etherAmount).mul(3).div(5);
        } else {
             
            etherMine = miner.etherAmount.mul(1).div(2);
            comMine = _etherToCom(miner.etherAmount).mul(2).div(5);
        }
        require(address(this).balance >= etherMine, "CoinMiner: [_getMine] ether balance is not enough");
        require(_com.balanceOf(address(this)) >= comMine, "CoinMiner: [_getMine] com balance is not enough");
         
        miner.isExist = false;
        address payable recipient = address(uint160(who));
         
        recipient.transfer(etherMine);
        _com.transfer(who, comMine);
    }

     
    function _etherToCom(uint256 amount) private view returns (uint256) {
        (uint256 k1, uint256 k2) = _com.getScale();
        return amount.mul(k1).div(k2);
    }

     
    function _comToEther(uint256 amount) private view returns (uint256) {
        (uint256 k1, uint256 k2) = _com.getScale();
        return amount.mul(k2).div(k1);
    }

     
    function etherToCom(uint256 amount) public view returns (uint256) {
        return _etherToCom(amount);
    }

     
    function comToEther(uint256 amount) public view returns (uint256) {
        return _comToEther(amount);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "CoinMiner: [withdrawEther] recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "CoinMiner: [withdrawEther] exceeds balance");
        recipient.transfer(amount);
    }

     
    function withdrawComToken(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "CoinMiner: [withdrawEther] recipient is the zero address");

        uint256 balance = _com.balanceOf(address(this));

        require(balance >= amount, "CoinMiner: [withdrawcom] exceeds balance");

        _com.transfer(recipient, amount);
    }
}