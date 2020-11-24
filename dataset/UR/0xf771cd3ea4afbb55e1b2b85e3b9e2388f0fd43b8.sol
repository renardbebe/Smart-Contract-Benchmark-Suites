 

pragma solidity ^0.4.24;

contract Owned {
  address public owner;

   
   
   
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner returns (address account) {
    owner = newOwner;
    return owner;
  }
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

contract ERC20 {
  function totalSupply() public constant returns (uint256);
  function balanceOf(address tokenOwner) public constant returns (uint256 balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract CSTKDropToken is ERC20, Owned {
  using SafeMath for uint256;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  bool public started;

  address public token;

  struct Level {
    uint256 price;
    uint256 available;
  }

  Level[] levels;

  mapping(address => uint256) balances;
  mapping(address => mapping(string => uint256)) orders;

  event TransferETH(address indexed from, address indexed to, uint256 eth);
  event Sell(address indexed to, uint256 tokens, uint256 eth);

   
   
   
  constructor(string _symbol, string _name, uint256 _supply, uint256 _decimals, address _token) public {
    symbol = _symbol;
    name = _name;
    decimals = _decimals;
    token = _token;
    _totalSupply = _supply;
    balances[owner] = _totalSupply;
    started = false;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function destruct() public onlyOwner {
    ERC20 tokenInstance = ERC20(token);

    uint256 balance = tokenInstance.balanceOf(this);

    if (balance > 0) {
      tokenInstance.transfer(owner, balance);
    }

    selfdestruct(owner);
  }

   
   
   
  function setToken(address newTokenAddress) public onlyOwner returns (bool success) {
    token = newTokenAddress;
    return true;
  }

   
   
   
  function totalSupply() public view returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }

   
   
   
   
   
   
  function changeTotalSupply(uint256 newSupply) public onlyOwner returns (bool success) {
    require(newSupply >= 0 && (
      newSupply >= _totalSupply || _totalSupply - newSupply <= balances[owner]
    ));
    uint256 diff = 0;
    if (newSupply >= _totalSupply) {
      diff = newSupply.sub(_totalSupply);
      balances[owner] = balances[owner].add(diff);
      emit Transfer(address(0), owner, diff);
    } else {
      diff = _totalSupply.sub(newSupply);
      balances[owner] = balances[owner].sub(diff);
      emit Transfer(owner, address(0), diff);
    }
    _totalSupply = newSupply;
    return true;
  }

   
   
   
  function balanceOf(address tokenOwner) public view returns (uint256 balance) {
    return balances[tokenOwner];
  }

   
   
   
  function start() public onlyOwner {
    started = true;
  }

   
   
   
  function stop() public onlyOwner {
    started = false;
  }

   
   
   
  function addLevel(uint256 price, uint256 available) public onlyOwner {
    levels.push(Level(price, available));
  }

   
   
   
  function removeLevel(uint256 price) public onlyOwner {
    if (levels.length < 1) {
      return;
    }

    Level[] memory tmp = levels;

    delete levels;

    for (uint i = 0; i < tmp.length; i++) {
      if (tmp[i].price != price) {
        levels.push(tmp[i]);
      }
    }
  }

   
   
   
  function replaceLevel(uint index, uint256 price, uint256 available) public onlyOwner {
    levels[index] = Level(price, available);
  }

   
   
   
  function clearLevels() public onlyOwner {
    delete levels;
  }

   
   
   
  function getLevelAmount(uint256 price) public view returns (uint256 available) {
    if (levels.length < 1) {
      return 0;
    }

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].price == price) {
        return levels[i].available;
      }
    }
  }

   
   
   
  function getLevelByIndex(uint index) public view returns (uint256 price, uint256 available) {
    price = levels[index].price;
    available = levels[index].available;
  }

   
   
   
  function getLevelsCount() public view returns (uint) {
    return levels.length;
  }

   
   
   
  function getCurrentLevel() public view returns (uint256 price, uint256 available) {
    if (levels.length < 1) {
      return;
    }

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].available > 0) {
        price = levels[i].price;
        available = levels[i].available;
        break;
      }
    }
  }

   
   
   
  function orderTokensOf(address customer) public view returns (uint256 balance) {
    return orders[customer]['tokens'];
  }

   
   
   
  function orderEthOf(address customer) public view returns (uint256 balance) {
    return orders[customer]['eth'];
  }

   
   
   
  function cancelOrder(address customer) public onlyOwner returns (bool success) {
    orders[customer]['eth'] = 0;
    orders[customer]['tokens'] = 0;
    return true;
  }

   
   
   
   
  function _checkOrder(address customer) private returns (uint256 tokens, uint256 eth) {
    require(started);

    eth = 0;
    tokens = 0;

    if (getLevelsCount() <= 0 || orders[customer]['tokens'] <= 0 || orders[customer]['eth'] <= 0) {
      return;
    }

    ERC20 tokenInstance = ERC20(token);
    uint256 balance = tokenInstance.balanceOf(this);

    uint256 orderEth = orders[customer]['eth'];
    uint256 orderTokens = orders[customer]['tokens'] > balance ? balance : orders[customer]['tokens'];

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].available <= 0) {
        continue;
      }

      uint256 _tokens = (10**decimals) * orderEth / levels[i].price;

       
      if (_tokens > levels[i].available) {
        _tokens = levels[i].available;
      }

       
      if (_tokens > orderTokens) {
        _tokens = orderTokens;
      }

      uint256 _eth = _tokens * levels[i].price / (10**decimals);
      levels[i].available -= _tokens;

       
      eth += _eth;
      tokens += _tokens;

       
      orderEth -= _eth;
      orderTokens -= _tokens;

      if (orderEth <= 0 || orderTokens <= 0 || levels[i].available > 0) {
         
        break;
      }
    }

     
    orders[customer]['tokens'] = orders[customer]['tokens'].sub(tokens);
    orders[customer]['eth'] = orders[customer]['eth'].sub(eth);

    tokenInstance.transfer(customer, tokens);

    emit Sell(customer, tokens, eth);
  }

   
   
   
  function checkOrder(address customer) public onlyOwner returns (uint256 tokens, uint256 eth) {
    return _checkOrder(customer);
  }

   
   
   
   
   
   
   
  function transfer(address to, uint256 tokens) public returns (bool success) {
    require(msg.sender == owner || to == owner || to == address(this));
    address receiver = msg.sender == owner ? to : owner;

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[receiver] = balances[receiver].add(tokens);

    emit Transfer(msg.sender, receiver, tokens);

    if (receiver == owner) {
      orders[msg.sender]['tokens'] = orders[msg.sender]['tokens'].add(tokens);
      _checkOrder(msg.sender);
    }

    return true;
  }

   
   
   
  function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
    tokenOwner;
    spender;
    return uint256(0);
  }

   
   
   
  function approve(address spender, uint tokens) public returns (bool success) {
    spender;
    tokens;
    return true;
  }

   
   
   
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
    from;
    to;
    tokens;
    return true;
  }

   
   
   
  function () public payable {
    owner.transfer(msg.value);
    emit TransferETH(msg.sender, address(this), msg.value);

    orders[msg.sender]['eth'] = orders[msg.sender]['eth'].add(msg.value);
    _checkOrder(msg.sender);
  }

   
   
   
  function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
    return ERC20(tokenAddress).transfer(owner, tokens);
  }

   
   
   
  function transferToken(uint256 tokens) public onlyOwner returns (bool success) {
    return transferAnyERC20Token(token, tokens);
  }

   
   
   
  function returnFrom(address tokenOwner, uint256 tokens) public onlyOwner returns (bool success) {
    balances[tokenOwner] = balances[tokenOwner].sub(tokens);
    balances[owner] = balances[owner].add(tokens);
    emit Transfer(tokenOwner, owner, tokens);
    return true;
  }

   
   
   
  function nullifyFrom(address tokenOwner) public onlyOwner returns (bool success) {
    return returnFrom(tokenOwner, balances[tokenOwner]);
  }
}

contract CSTK_CLT is CSTKDropToken('CSTK_CLT', 'CryptoStock CLT Promo Token', 100000 * 10**8, 8, 0x2001f2A0Cf801EcFda622f6C28fb6E10d803D969) {

}