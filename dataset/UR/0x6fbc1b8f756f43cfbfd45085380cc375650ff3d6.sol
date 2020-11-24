 

 

pragma solidity ^0.4.24;

 

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract ZethrInterface {
  function transfer(address _from, uint _amount) public;

  function myFrontEndTokens() public view returns (uint);
}

contract ZethrMultiSigWalletInterface {
  mapping(address => bool) public isOwner;
}

contract ZethrSnap {

  struct SnapEntry {
    uint blockNumber;
    uint profit;
  }

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

   
  ZethrMultiSigWalletInterface public multiSigWallet;

   
  ZethrInterface zethr;

   
  address signer;

   
  mapping(address => mapping(uint => bool)) public claimedMap;

   
  SnapEntry[] public snaps;

   
  bool public paused;

   
  uint public allocatedTokens;

  constructor(address _multiSigWalletAddress, address _zethrAddress, address _signer)
  public
  {
    multiSigWallet = ZethrMultiSigWalletInterface(_multiSigWalletAddress);
    zethr = ZethrInterface(_zethrAddress);
    signer = _signer;
    paused = false;
  }

   
  function()
  public payable
  {}

   
  function ownerSetPaused(bool _paused)
  public
  ownerOnly
  {
    paused = _paused;
  }

   
  function walletSetWallet(address _multiSigWalletAddress)
  public
  walletOnly
  {
    multiSigWallet = ZethrMultiSigWalletInterface(_multiSigWalletAddress);
  }

   
  function withdraw()
  public
  {
    (address(multiSigWallet)).transfer(address(this).balance);
  }

   
  function walletSetSigner(address _signer)
  public walletOnly
  {
    signer = _signer;
  }

   
  function walletWithdrawTokens(uint _amount)
  public walletOnly
  {
    zethr.transfer(address(multiSigWallet), _amount);
  }

   
  function getSnapsLength()
  public view
  returns (uint)
  {
    return snaps.length;
  }

   
  function walletCreateSnap(uint _blockNumber, uint _profitToShare)
  public
  walletOnly
  {
    uint index = snaps.length;
    snaps.length++;

    snaps[index].blockNumber = _blockNumber;
    snaps[index].profit = _profitToShare;

     
    uint balance = zethr.myFrontEndTokens();
    balance = balance - allocatedTokens;
    require(balance >= _profitToShare);

     
    allocatedTokens = allocatedTokens + _profitToShare;
  }

   
  function getSnap(uint _snapId)
  public view
  returns (uint blockNumber, uint profit, bool claimed)
  {
    SnapEntry storage entry = snaps[_snapId];
    return (entry.blockNumber, entry.profit, claimedMap[msg.sender][_snapId]);
  }

   
  function claim(uint _snapId, address _payTo, uint _amount, bytes _signatureBytes)
  public
  {
     
    require(!paused);

     
    require(claimedMap[msg.sender][_snapId] == false);
    claimedMap[msg.sender][_snapId] = true;

     
     
    Sig memory sig = toSig(_signatureBytes);
    bytes32 hash = keccak256(abi.encodePacked("SNAP", _snapId, msg.sender, _amount));
    address recoveredSigner = ecrecover(hash, sig.v, sig.r, sig.s);
    require(signer == recoveredSigner);

     
    require(_amount <= allocatedTokens);
    allocatedTokens = allocatedTokens - _amount;

     
    zethr.transfer(_payTo, _amount);
  }

   
  function tokenFallback(address  , uint  , bytes  )
  public view
  returns (bool)
  {
    require(msg.sender == address(zethr), "Tokens must be ZTH");
    return true;
  }

   
  function toSig(bytes b)
  internal pure
  returns (Sig memory sig)
  {
    sig.r = bytes32(toUint(b, 0));
    sig.s = bytes32(toUint(b, 32));
    sig.v = uint8(b[64]);
  }

   
  function toUint(bytes _bytes, uint _start)
  internal pure
  returns (uint256)
  {
    require(_bytes.length >= (_start + 32));
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

   
  modifier walletOnly()
  {
    require(msg.sender == address(multiSigWallet));
    _;
  }

   
  modifier ownerOnly()
  {
    require(msg.sender == address(multiSigWallet) || multiSigWallet.isOwner(msg.sender));
    _;
  }
}