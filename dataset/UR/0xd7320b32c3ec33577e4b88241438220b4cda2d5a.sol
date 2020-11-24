 

pragma solidity 0.4.24;

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

contract CanReclaimToken is Ownable {
  

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

}

contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    require(owner.send(address(this).balance));
  }
}

contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
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

contract CertificateRedeemer is Claimable, HasNoTokens, HasNoEther {
     
    mapping(address => bool) public signers;

     
     
     
    mapping(bytes32 => uint256) public nonces;

    address public token;
    address public tokenHolder;

    event TokenHolderChanged(address oldTokenHolder, address newTokenHolder);
    event CertificateRedeemed(string accountId, uint256 amount, address recipient, uint256 nonce, address signer);
    event SignerAdded(address signer);
    event SignerRemoved(address signer);
    event AccountNonceChanged(uint256 oldNonce, uint256 newNone);

    constructor(address _token, address _tokenHolder)
    public
    {
        token = _token;
        tokenHolder = _tokenHolder;
    }

    function redeemWithdrawalCertificate(string accountId, uint256 amount, address recipient, bytes signature)
      external
      returns (bool)
    {
         
        bytes32 accountHash = hashAccountId(accountId);
        uint256 nonce = nonces[accountHash]++;
        
         
        bytes32 unsignedMessage = generateWithdrawalHash(accountId, amount, recipient, nonce);

         
         
         
         
        address signer = recoverSigner(unsignedMessage, signature);

         
        require(signers[signer]);

         
        emit CertificateRedeemed(accountId, amount, recipient, nonce, signer);

         
        require(ERC20(token).transferFrom(tokenHolder, recipient, amount));

        return true;
    }

     

     
    function generateWithdrawalHash(string accountId, uint256 amount, address recipient, uint256 nonce)
     view
     public
    returns (bytes32)
    {
        bytes memory message = abi.encodePacked(address(this), 'withdraw', accountId, amount, recipient, nonce);
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


    function recoverSigner(bytes32 _hash, bytes _signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (_signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
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
    
    function setNonce(string accountId, uint256 newNonce) 
      public
      onlyOwner
    {
        bytes32 accountHash = hashAccountId(accountId);
        uint256 oldNonce = nonces[accountHash];
        require(newNonce > oldNonce);
        
        nonces[accountHash] = newNonce;
        
        emit AccountNonceChanged(oldNonce, newNonce);
    }
}