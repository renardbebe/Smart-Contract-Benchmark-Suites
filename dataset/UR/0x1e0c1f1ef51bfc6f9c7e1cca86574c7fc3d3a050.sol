 

pragma solidity ^0.5.10;

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
     
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

contract alive is ERC20Interface {

  using SafeMath for uint;
  using Math for uint;
  uint8 public constant decimals = 18;
  string public constant symbol = "ALIVE";
  string public constant name = "PROOF OF LIFE";
  uint public constant maxSupply = 1000000 * 10**uint(decimals);
  uint private _totalSupply = 0;
  uint private _minted = 0;
  uint private _nextAirdrop = 9571 * 10**uint(decimals);
  address devAddress = address(0x8160aEBf3B1a65D1b4992A95Bd50350b1a08E35b);
  address[] private _holderArray;

  mapping(address => uint) private _balances;
  mapping(address => mapping (address => uint)) private _allowances;
  mapping(address => bool) private _airdropClaim; 
  mapping(address => bool) private _holderFlag;
  mapping(address => uint) private _timeStamp;

  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return _balances[tokenOwner];
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return _allowances[tokenOwner][spender];
  }

  function transfer(address to, uint amount) public returns (bool success) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  function approve(address spender, uint amount) public returns (bool success) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint amount) public returns (bool success) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
  }

   
  function _isHuman(address addr) private returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size == 0;
  }

  function _approve(address owner, address spender, uint amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(address sender, address recipient, uint amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

     
    if (amount == 0) {
      emit Transfer(sender, recipient, 0);
      return;
    }

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);

     
     
    if(_holderFlag[recipient] != true && _isHuman(recipient) && (_balances[recipient] > 0)){ 
      _holderArray.push(recipient);
      _holderFlag[recipient] = true;
    }

     
    _timeStamp[sender] = now;
    _timeStamp[recipient] = now;
    if(_minted >= 785000 * 10**uint(decimals)){
      _findSlashCandidate();
    }
  }

  function _findSlashCandidate() private {
    uint oldestTimestamp = now;
    address oldestInactive = address(0);
    for(uint i=0; i<_holderArray.length; i++) {  
      if(_timeStamp[_holderArray[i]]<oldestTimestamp && (_balances[_holderArray[i]] > 0)) {
        oldestInactive = _holderArray[i];
        oldestTimestamp = _timeStamp[oldestInactive];
      }
    }
    _slash(oldestInactive);
  }

  function _slash(address account) private {
    uint slashingAmount = _balances[account].div(2);
    if(slashingAmount < 1*10**(decimals)) {  
      slashingAmount = _balances[account];
    }
    _timeStamp[account] = now;  
    _burn(account,slashingAmount);  
  }

  function _burn(address account, uint amount) private {
    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _mint(address account, uint amount) internal {
    _totalSupply = _totalSupply.add(amount);
    _minted = _minted.add(amount);
    uint devReward = (amount.mul(5)).div(100);
    _balances[devAddress] = _balances[devAddress].add(devReward);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
    emit Transfer(address(0), devAddress, devReward);
  }

  function _airdrop(address account) internal {
    require(_minted < maxSupply);  
    require(_airdropClaim[account] != true);  
    _nextAirdrop = Math.min((_nextAirdrop.mul(995)).div(1000),(maxSupply - _minted));
    _holderArray.push(account);
    _timeStamp[account] = now;
    _holderFlag[account] = true;
    _airdropClaim[account] = true;
    _mint(account,_nextAirdrop);
  }

  function () external payable {
    if(msg.value > 0){
      revert();
    }
    else {
      _airdrop(msg.sender);
    }
  }

  function burned() public view returns(uint) {
    return _minted-_totalSupply;
  }
}