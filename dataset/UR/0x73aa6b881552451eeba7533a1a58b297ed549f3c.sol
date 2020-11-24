 

pragma solidity ^0.5.1;

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
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    uint c = a - b;
    return c;
  }

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    return c;
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

contract triskaidekaphobia is ERC20Interface {

  using SafeMath for uint;
  using Math for uint;
  uint8 public constant decimals = 18;
  uint8 public constant maxRank = 15;
  string public constant symbol = " TRIS";
  string public constant name = "TRISKAIDEKAPHOBIA";
  uint public constant maxSupply = 1000000 * 10**uint(decimals);
  uint private _totalSupply = 0;
  uint private _minted = 0;
  uint private _nextAirdrop = 10000 * 10**uint(decimals);
  address rankHead = address(0);
  address devAddress = address(0x3409E6883b3CB6DDc9aEA58f24593F7218B830c7);

  mapping (address => uint) private _balances;
  mapping (address => mapping (address => uint)) private _allowances;
  mapping (address => bool) private _airdropped;  
  mapping(address => bool) ranked;
  mapping(address => address) rankList;

  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint balance) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view returns (uint remaining) {
    return _allowances[owner][spender];
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

     
    _pop(sender);
    _pop(recipient);
    _insert(sender);
    _insert(recipient);
    _slash();
  }

  function _slash() internal {
    if(_minted >= 400000 * 10**uint(decimals)){
    address rankThirteen = _getRankThirteen();
    address rankFourteen = rankList[rankThirteen];
    if( (rankThirteen != address(0)) && (balanceOf(rankThirteen) > 0) ) {
      uint alterBalance = balanceOf(rankThirteen).div(3);
      if(rankFourteen != address(0)){
        _burn(rankThirteen,alterBalance);
        _balances[rankThirteen] = _balances[rankThirteen].sub(alterBalance);
        _balances[rankFourteen] = _balances[rankFourteen].add(alterBalance);
        emit Transfer(rankThirteen, rankFourteen, alterBalance);
        _pop(rankThirteen);
        _pop(rankFourteen);
        _insert(rankThirteen);
        _insert(rankFourteen);
      }
      else {
        _burn(rankThirteen,2*alterBalance);
        _pop(rankThirteen);
        _insert(rankThirteen);
      }
    }
    }
  }

  function _burn(address account, uint amount) internal {
    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _mint(address account, uint amount) internal {
    _totalSupply = _totalSupply.add(amount);
    _minted = _minted.add(amount);
    _airdropped[account] = true;
    uint devReward = (amount.mul(5)).div(100);
    uint accountMint = amount.sub(devReward);
    _balances[devAddress] = _balances[devAddress].add(devReward);
    _balances[account] = _balances[account].add(accountMint);
    emit Transfer(address(0), account, accountMint);
    emit Transfer(address(0), devAddress, devReward);
  }

  function _airdrop(address account) internal {
    require(account != address(0));
    require(_minted < maxSupply);  
    require(_airdropped[account] != true);  
    require(_nextAirdrop > 0);  

    _mint(account,_nextAirdrop);
    _nextAirdrop = Math.min((_nextAirdrop.mul(99)).div(100),(maxSupply - _minted));
    _insert(account);
  }

  function () external payable {
    if(msg.value > 0){
      revert();
    }
    else {
      _airdrop(msg.sender);
    }
  }

  function _insert(address addr) internal {  
    require(addr != address(0));
    if(ranked[addr] != true){  
      if(rankHead == address(0)){  
        rankHead = addr;  
        rankList[addr] = address(0);  
        ranked[addr] = true;
        return;
      }
      else if(_balances[addr] > _balances[rankHead]){  
        rankList[addr] = rankHead;  
        rankHead = addr;  
        ranked[addr] = true;
        return;
      }
      else {  
        address tracker = rankHead;  
        for(uint8 i = 1; i<=maxRank; i++){  
           
          if(_balances[addr] > _balances[rankList[tracker]] || rankList[tracker] == address(0)){
            rankList[addr] = rankList[tracker];  
            rankList[tracker] = addr;  
            ranked[addr] = true;
            return;
          }
          tracker = rankList[tracker];
        }
      }
    }
  }

  function _pop(address addr) internal {  
    if(ranked[addr] == true) {  
      address tracker = rankHead;  
      if(tracker == addr){  
        rankHead = rankList[tracker];  
        ranked[addr] = false;  
        return;
      }
      else{
         
        while (rankList[tracker] != address(0)){  
          if(rankList[tracker] == addr){  
            rankList[tracker] = rankList[addr];  
            ranked[addr] = false;  
            return;
          }
          tracker = rankList[tracker];  
        }
        ranked[addr] = false; 
        return;
      }
    }
  }

  function getRank() public view returns(uint) {  
    if(ranked[msg.sender] == true){  
      address tracker = rankHead;
      for(uint8 i = 1; i <= maxRank; i++ ){  
        if(msg.sender == tracker){
          return uint(i);
        }
        tracker = rankList[tracker];
      }
    }
    return 0;  
  }

  function _getRankThirteen() internal returns(address) {
    address tracker = rankHead;
    for(uint i = 1; i < 13; i++ ){
      if(tracker == address(0)){  
        return address(0);  
      }
      tracker = rankList[tracker];
    }
    return tracker;  
  }

  function burned() public view returns(uint) {
    return _minted-_totalSupply;
  }
}