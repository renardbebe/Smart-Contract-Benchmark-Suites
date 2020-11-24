 

pragma solidity ^0.4.25;


 
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

   
  function recover(bytes32 _hash, bytes _sig)
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

    event UserStake(address userUportAddress, address userMetamaskAddress, uint amountStaked);
    event UserRecoupStake(address userUportAddress, address userMetamaskAddress, uint amountStaked);

     
    event debugBytes32(bytes32 _msg);
    event debugBytes(bytes _msg);
    event debugString(string _msg);
    event debugAddress(address _address);

     
    address public grantSigner;

     
    uint public finishDate;

     
    mapping (address => address) public userStakedAddress;

     
    mapping (address => uint256) public stakedAmount;


    constructor(address _grantSigner, uint _finishDate) public {
        grantSigner = _grantSigner;
        finishDate = _finishDate;
    }

     

     
    function stake(address _userUportAddress, uint _expiryDate, bytes _signature) public payable whenNotPaused {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userUportAddress, msg.value, _expiryDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);

        require(signer == grantSigner, "Signature is not valid");
        require(block.timestamp < _expiryDate, "Grant is expired");
        require(userStakedAddress[_userUportAddress] == 0, "User has already staked!");

        userStakedAddress[_userUportAddress] = msg.sender;
        stakedAmount[_userUportAddress] = msg.value;

        emit UserStake(_userUportAddress, msg.sender, msg.value);
    }

     
    function recoupStake(address _userUportAddress, uint _expiryDate, bytes _signature) public whenNotPaused {
        bytes32 hashMessage = keccak256(abi.encodePacked(_userUportAddress, _expiryDate));
        address signer = hashMessage.toEthSignedMessageHash().recover(_signature);

        require(signer == grantSigner, "Signature is not valid");
        require(block.timestamp < _expiryDate, "Grant is expired");
        require(userStakedAddress[_userUportAddress] != 0, "User has not staked!");

        address stakedBy = userStakedAddress[_userUportAddress];
        uint256 amount = stakedAmount[_userUportAddress];
        userStakedAddress[_userUportAddress] = address(0x0);
        stakedAmount[_userUportAddress] = 0;

        stakedBy.transfer(amount);

        emit UserRecoupStake(_userUportAddress, stakedBy, amount);
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