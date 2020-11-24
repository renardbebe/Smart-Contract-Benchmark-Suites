 

pragma solidity ^0.4.23;

 

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract TakeBack is Ownable{

     
    address public tokenAdd;

    address public supervisor;

    uint256 public networkId;

    mapping (address => uint256) public userToNonce;

     
    event TakedBack(address indexed _user, uint indexed _nonce, uint256 _value);
     
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);


    constructor(address _token, address _supervisor, uint256 _networkId) public {
        tokenAdd = _token;
        supervisor = _supervisor;
        networkId = _networkId;
    }

     
     
     
     
    function takeBack(uint256 _nonce, uint256 _value, bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) public {
        address _user = msg.sender;

         
        require(userToNonce[_user] == _nonce);

         
        require(supervisor == verify(_hashmessage, _v, _r, _s));

         
        require(keccak256(abi.encodePacked(_user,_nonce,_value,networkId)) == _hashmessage);

         
        ERC20 token = ERC20(tokenAdd);
        token.transfer(_user, _value);

         
        userToNonce[_user]  += 1;
        emit TakedBack(_user, _nonce, _value);
    }

    function verify(bytes32 _hashmessage, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19EvolutionLand Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hashmessage));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    function changeSupervisor(address _newSupervisor) public onlyOwner {
        supervisor = _newSupervisor;
    }
}