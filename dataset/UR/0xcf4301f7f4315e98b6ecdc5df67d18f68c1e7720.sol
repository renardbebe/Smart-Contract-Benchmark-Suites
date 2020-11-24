 

pragma solidity ^0.5.11;

 

 
contract Ownable {
  address payable public owner;


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

   
  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
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


 

library ECRecovery {

   
  function recover(bytes32 _hash, bytes memory _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (_sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(_hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}

 

 

contract ETHDenverStaking is Ownable, Pausable {

    using ECRecovery for bytes32;

    event UserStake(address userFortmaticAddress, address walletAddress, uint amountStaked);
    event UserRecoupStake(address userFortmaticAddress, address walletAddress, uint amountStaked);

     
    event debugBytes32(bytes32 _msg);
    event debugBytes(bytes _msg);
    event debugString(string _msg);
    event debugAddress(address _address);

     
    address public grantSigner;

     
    uint public finishDate;

     
    mapping (address => address payable) public userStakedAddress;

     
    mapping (address => uint) public stakedAmount;


    constructor(address _grantSigner, uint _finishDate) public {
        require(_grantSigner != address(0x0));
        require(_finishDate > block.timestamp);
        grantSigner = _grantSigner;
        finishDate = _finishDate;
    }

     

     
    function stake(address _userFortmaticAddress, uint _expiryDate, bytes memory _signature) public payable whenNotPaused {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userFortmaticAddress, msg.value, _expiryDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);

        require(signer == grantSigner, "Signature is not valid");
        require(block.timestamp < _expiryDate, "Grant is expired");
        require(userStakedAddress[_userFortmaticAddress] == address(0x0), "User has already staked!");

        userStakedAddress[_userFortmaticAddress] = msg.sender;
        stakedAmount[_userFortmaticAddress] = msg.value;

        emit UserStake(_userFortmaticAddress, msg.sender, msg.value);
    }

     
    function recoupStake(address _userFortmaticAddress, uint _expiryDate, bytes memory _signature) public whenNotPaused {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userFortmaticAddress, _expiryDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);

        require(signer == grantSigner, "Signature is not valid");
        require(block.timestamp < _expiryDate, "Grant is expired");
        require(userStakedAddress[_userFortmaticAddress] != address(0x0), "User has not staked!");

        address payable stakedBy = userStakedAddress[_userFortmaticAddress];
        uint amount = stakedAmount[_userFortmaticAddress];
        userStakedAddress[_userFortmaticAddress] = address(0x0);
        stakedAmount[_userFortmaticAddress] = 0;

        stakedBy.transfer(amount);

        emit UserRecoupStake(_userFortmaticAddress, stakedBy, amount);
    }

     

    function setGrantSigner(address _signer) public onlyOwner {
        require(_signer != address(0x0), "address is null");
        grantSigner = _signer;
    }

    function sweepStakes() public onlyOwner {
        require(block.timestamp > finishDate, "EthDenver is not over yet!");
        owner.transfer(address(this).balance);
    }

}