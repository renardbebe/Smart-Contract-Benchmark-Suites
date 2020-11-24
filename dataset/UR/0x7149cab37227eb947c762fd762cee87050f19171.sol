 

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

contract AtomicTokenSwap {
    struct Swap {
        uint expiration;
        address initiator;
        address participant;
        address token;
        uint256 value;
        bool exists;
    }

     
    mapping(address => mapping(bytes20 => Swap)) public swaps;
    
     
    function initiate(uint _expiration, bytes20 _hash, address _participant, address _token, uint256 _value) public {
        Swap storage s = swaps[_participant][_hash];
        
         
         
        require(s.exists == false);

         
        ERC20 token = ERC20(_token);
        require(token.allowance(msg.sender, this) == _value);
        token.transferFrom(msg.sender, this, _value);

         
        swaps[_participant][_hash] = Swap(_expiration, msg.sender, _participant, _token, _value, true);
    }
    
    function redeem(bytes32 _secret) public {
         
         
        bytes20 hash = ripemd160(_secret);
        Swap storage s = swaps[msg.sender][hash];
        
         
        require(msg.sender == s.participant);
         
        require(now < s.expiration);
         
        require(s.exists);
         
        s.exists = false;
        ERC20 token = ERC20(s.token);
        token.transfer(msg.sender, s.value);
    }
    
    function refund(bytes20 _hash, address _participant) public {
        Swap storage s = swaps[_participant][_hash];
        require(now > s.expiration);
        require(msg.sender == s.initiator);
         
        require(s.exists);

        s.exists = false;
        ERC20 token = ERC20(s.token);
        token.transfer(msg.sender, s.value);
    }
}