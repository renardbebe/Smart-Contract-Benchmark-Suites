 

pragma solidity ^0.4.24;

 
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

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
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

 
contract TokenUnidirectional {
    using SafeMath for uint256;

    struct PaymentChannel {
        address sender;
        address receiver;
        uint256 value;  

        uint256 settlingPeriod;  
        uint256 settlingUntil;  
        address tokenContract;  
    }

    mapping (bytes32 => PaymentChannel) public channels;

    event DidOpen(bytes32 indexed channelId, address indexed sender, address indexed receiver, uint256 value, address tokenContract);
    event DidDeposit(bytes32 indexed channelId, uint256 deposit);
    event DidClaim(bytes32 indexed channelId);
    event DidStartSettling(bytes32 indexed channelId);
    event DidSettle(bytes32 indexed channelId);

     

     
     
     
     
     
     
     
     
    function open(bytes32 channelId, address receiver, uint256 settlingPeriod, address tokenContract, uint256 value) public {
        require(isAbsent(channelId), "Channel with the same id is present");

        StandardToken token = StandardToken(tokenContract);
        require(token.transferFrom(msg.sender, address(this), value), "Unable to transfer token to the contract");

        channels[channelId] = PaymentChannel({
            sender: msg.sender,
            receiver: receiver,
            value: value,
            settlingPeriod: settlingPeriod,
            settlingUntil: 0,
            tokenContract: tokenContract
        });

        emit DidOpen(channelId, msg.sender, receiver, value, tokenContract);
    }

     
     
     
     
    function canDeposit(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

     
     
     
    function deposit(bytes32 channelId, uint256 value) public {
        require(canDeposit(channelId, msg.sender), "canDeposit returned false");

        PaymentChannel storage channel = channels[channelId];
        StandardToken token = StandardToken(channel.tokenContract);
        require(token.transferFrom(msg.sender, address(this), value), "Unable to transfer token to the contract");
        channel.value = channel.value.add(value);

        emit DidDeposit(channelId, value);
    }

     
     
     
     
    function canStartSettling(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

     
     
     
    function startSettling(bytes32 channelId) public {
        require(canStartSettling(channelId, msg.sender), "canStartSettling returned false");

        PaymentChannel storage channel = channels[channelId];
        channel.settlingUntil = block.number.add(channel.settlingPeriod);

        emit DidStartSettling(channelId);
    }

     
     
     
    function canSettle(bytes32 channelId) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        bool isWaitingOver = block.number >= channel.settlingUntil;
        return isSettling(channelId) && isWaitingOver;
    }

     
     
     
    function settle(bytes32 channelId) public {
        require(canSettle(channelId), "canSettle returned false");

        PaymentChannel storage channel = channels[channelId];
        StandardToken token = StandardToken(channel.tokenContract);

        require(token.transfer(channel.sender, channel.value), "Unable to transfer token to channel sender");

        delete channels[channelId];
        emit DidSettle(channelId);
    }

     
     
     
     
     
     
    function canClaim(bytes32 channelId, uint256 payment, address origin, bytes signature) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        bool isReceiver = origin == channel.receiver;
        bytes32 hash = recoveryPaymentDigest(channelId, payment, channel.tokenContract);
        bool isSigned = channel.sender == ECRecovery.recover(hash, signature);

        return isReceiver && isSigned;
    }

     
     
     
     
     
    function claim(bytes32 channelId, uint256 payment, bytes signature) public {
        require(canClaim(channelId, payment, msg.sender, signature), "canClaim returned false");

        PaymentChannel storage channel = channels[channelId];
        StandardToken token = StandardToken(channel.tokenContract);

        if (payment >= channel.value) {
            require(token.transfer(channel.receiver, channel.value), "Unable to transfer token to channel receiver");
        } else {
            require(token.transfer(channel.receiver, payment), "Unable to transfer token to channel receiver");
            uint256 change = channel.value.sub(payment);
            require(token.transfer(channel.sender, change), "Unable to transfer token to channel sender");
        }

        delete channels[channelId];

        emit DidClaim(channelId);
    }

     

     
     
    function isAbsent(bytes32 channelId) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        return channel.sender == 0;
    }

     
     
    function isPresent(bytes32 channelId) public view returns(bool) {
        return !isAbsent(channelId);
    }

     
     
     
    function isSettling(bytes32 channelId) public view returns(bool) {
        PaymentChannel storage channel = channels[channelId];
        return channel.settlingUntil != 0;
    }

     
     
    function isOpen(bytes32 channelId) public view returns(bool) {
        return isPresent(channelId) && !isSettling(channelId);
    }

     

     
     
     
     
    function paymentDigest(bytes32 channelId, uint256 payment, address tokenContract) public view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), channelId, payment, tokenContract));
    }

     
     
     
    function recoveryPaymentDigest(bytes32 channelId, uint256 payment, address tokenContract) internal view returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, paymentDigest(channelId, payment, tokenContract)));
    }
}