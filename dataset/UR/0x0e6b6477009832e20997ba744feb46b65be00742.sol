 

pragma solidity 0.4.24;

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
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

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RedemptionCertificate is Claimable {
    using ECRecovery for bytes32;

     
    mapping(address => bool) public signers;

     
     
     
    mapping(bytes32 => uint256) public nonces;

    address public token;
    address public tokenHolder;

    event TokenHolderChanged(address oldTokenHolder, address newTokenHolder);
    event CertificateRedeemed(string accountId, uint256 amount, address recipient);
    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    constructor(address _token, address _tokenHolder)
    public
    {
        token = _token;
        tokenHolder = _tokenHolder;
    }


     
    modifier onlyValidSignatureOnce(string accountId, bytes32 hash, bytes signature) {
        address signedBy = hash.recover(signature);
        require(signers[signedBy]);
        _;
        nonces[hashAccountId(accountId)]++;
    }


     
    function withdraw(string accountId, uint256 amount, address recipient, bytes signature)
    onlyValidSignatureOnce(
        accountId,
        generateWithdrawalHash(accountId, amount, recipient),
        signature)
    public
    returns (bool)
    {
        require(ERC20(token).transferFrom(tokenHolder, recipient, amount));
        emit CertificateRedeemed(accountId, amount, recipient);
        return true;
    }




     

     
    function generateWithdrawalHash(string accountId, uint256 amount, address recipient)
     view
     public
    returns (bytes32)
    {
        bytes32 accountHash = hashAccountId(accountId);
        bytes memory message = abi.encodePacked(address(this), recipient, amount, nonces[accountHash]);
        bytes32 messageHash = keccak256(message);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

     
    function hashAccountId(string accountId)
    pure
    internal
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(accountId));
    }






     

    function updateTokenHolder(address newTokenHolder)
     onlyOwner
      external
    {
        address oldTokenHolder = tokenHolder;
        tokenHolder = newTokenHolder;
        emit TokenHolderChanged(oldTokenHolder, newTokenHolder);
    }

    function addSigner(address signer)
     onlyOwner
     external
    {
        signers[signer] = true;
        emit SignerAdded(signer);
    }

    function removeSigner(address signer)
     onlyOwner
     external
    {
        signers[signer] = false;
        emit SignerRemoved(signer);
    }
}