 

pragma solidity ^0.4.19;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

contract AtomicSwap {
  struct Swap {
    uint expiration;
    address initiator;
    address participant;
    uint256 value;
    bool isToken;
    address token;
    bool exists;
  }

  event InitiateSwap(address _initiator, address _participant, uint _expiration, bytes20 _hash, address _token, bool _isToken, uint256 _value);
  event RedeemSwap(address indexed _participant, bytes20 indexed _hash, bytes32 _secret);
  event RefundSwap(address _initiator, address _participant, bytes20 _hash);
   
  mapping(address => mapping(bytes20 => Swap)) public swaps;

  function initiate(uint _expiration, bytes20 _hash, address _participant, address _token, bool _isToken, uint256 _value) payable public {
    Swap storage s = swaps[_participant][_hash];
     
     
    require (s.exists == false);
     
    require (now < _expiration);

    if (_isToken) {
       
      ERC20 token = ERC20(_token);
      require(token.allowance(msg.sender, this) == _value);
      token.transferFrom(msg.sender, this, _value);
    }
     
    swaps[_participant][_hash] = Swap(_expiration, msg.sender, _participant, _isToken ? _value : msg.value, _isToken, _token, true);
    InitiateSwap(msg.sender, _participant, _expiration, _hash, _token, _isToken, _isToken ? _value : msg.value);
  }

  function redeem(bytes32 _secret) public {
     
     
    bytes20 hash = ripemd160(_secret);
    Swap storage s = swaps[msg.sender][hash];
    
     
    require(s.exists);
     
    require(now < s.expiration);
    
     
    s.exists = false;
    if (s.isToken) {
      ERC20 token = ERC20(s.token);
      token.transfer(msg.sender, s.value);
    } else {
      msg.sender.transfer(s.value);
    }

    RedeemSwap(msg.sender, hash, _secret);
  }

  function refund(bytes20 _hash, address _participant) public {
    Swap storage s = swaps[_participant][_hash];
     
    require(now > s.expiration);
     
    require(msg.sender == s.initiator);
     
    require(s.exists);

    s.exists = false;
    if (s.isToken) {
      ERC20 token = ERC20(s.token);
      token.transfer(msg.sender, s.value);
    } else {
      msg.sender.transfer(s.value);
    }

    RefundSwap(msg.sender, s.participant, _hash);
  }
}