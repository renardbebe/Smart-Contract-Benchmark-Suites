 

pragma solidity ^0.4.24;

 



 

library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
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
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}



 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}




 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}



contract Subscription {
    using ECDSA for bytes32;
    using SafeMath for uint256;

     
    address public author;

     
     
    address public requiredToAddress;
    address public requiredTokenAddress;
    uint256 public requiredTokenAmount;
    uint256 public requiredPeriodSeconds;
    uint256 public requiredGasPrice;

     
     
     
    mapping(bytes32 => uint256) public nextValidTimestamp;

     
     
     
    mapping(address => uint256) public extraNonce;

    event ExecuteSubscription(
        address indexed from,  
        address indexed to,  
        address tokenAddress,  
        uint256 tokenAmount,  
        uint256 periodSeconds,  
        uint256 gasPrice,  
        uint256 nonce  
    );

    constructor(
        address _toAddress,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _periodSeconds,
        uint256 _gasPrice
    ) public {
        requiredToAddress=_toAddress;
        requiredTokenAddress=_tokenAddress;
        requiredTokenAmount=_tokenAmount;
        requiredPeriodSeconds=_periodSeconds;
        requiredGasPrice=_gasPrice;
        author=msg.sender;
    }

     
     
     
     
    function isSubscriptionActive(
        bytes32 subscriptionHash,
        uint256 gracePeriodSeconds
    )
        external
        view
        returns (bool)
    {
        if(nextValidTimestamp[subscriptionHash]==uint256(-1)){
          return false;
        }
        return (block.timestamp <=
                nextValidTimestamp[subscriptionHash].add(gracePeriodSeconds)
        );
    }

     
     
    function getSubscriptionHash(
        address from,  
        address to,  
        address tokenAddress,  
        uint256 tokenAmount,  
        uint256 periodSeconds,  
        uint256 gasPrice,  
        uint256 nonce  
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                byte(0x19),
                byte(0),
                address(this),
                from,
                to,
                tokenAddress,
                tokenAmount,
                periodSeconds,
                gasPrice,
                nonce
        ));
    }

     
    function getSubscriptionSigner(
        bytes32 subscriptionHash,  
        bytes signature  
    )
        public
        pure
        returns (address)
    {
        return subscriptionHash.toEthSignedMessageHash().recover(signature);
    }

     
     
    function isSubscriptionReady(
        address from,  
        address to,  
        address tokenAddress,  
        uint256 tokenAmount,  
        uint256 periodSeconds,  
        uint256 gasPrice,  
        uint256 nonce, 
        bytes signature  
    )
        external
        view
        returns (bool)
    {
        bytes32 subscriptionHash = getSubscriptionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasPrice, nonce
        );
        address signer = getSubscriptionSigner(subscriptionHash, signature);
        uint256 allowance = ERC20(tokenAddress).allowance(from, address(this));
        uint256 balance = ERC20(tokenAddress).balanceOf(from);

        return (
            ( requiredToAddress == address(0) || to == requiredToAddress ) &&
            ( requiredTokenAddress == address(0) || tokenAddress == requiredTokenAddress ) &&
            ( requiredTokenAmount == 0 || tokenAmount == requiredTokenAmount ) &&
            ( requiredPeriodSeconds == 0 || periodSeconds == requiredPeriodSeconds ) &&
            ( requiredGasPrice == 0 || gasPrice == requiredGasPrice ) &&
            signer == from &&
            from != to &&
            block.timestamp >= nextValidTimestamp[subscriptionHash] &&
            allowance >= tokenAmount.add(gasPrice) &&
            balance >= tokenAmount.add(gasPrice)
        );
    }

     
     
     
    function cancelSubscription(
        address from,  
        address to,  
        address tokenAddress,  
        uint256 tokenAmount,  
        uint256 periodSeconds,  
        uint256 gasPrice,  
        uint256 nonce,  
        bytes signature  
    )
        external
        returns (bool success)
    {
        bytes32 subscriptionHash = getSubscriptionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasPrice, nonce
        );
        address signer = getSubscriptionSigner(subscriptionHash, signature);

         
        require(signer == from, "Invalid Signature for subscription cancellation");

         
        require(from == msg.sender, 'msg.sender is not the subscriber');

         
         
        nextValidTimestamp[subscriptionHash]=uint256(-1);

        return true;
    }

     
     
    function executeSubscription(
        address from,  
        address to,  
        address tokenAddress,  
        uint256 tokenAmount,  
        uint256 periodSeconds,  
        uint256 gasPrice,  
        uint256 nonce,  
        bytes signature  
    )
        public
        returns (bool success)
    {
         
         
        bytes32 subscriptionHash = getSubscriptionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasPrice, nonce
        );
        address signer = getSubscriptionSigner(subscriptionHash, signature);

         
        require(to != from, "Can not send to the from address");
         
        require(signer == from, "Invalid Signature");
         
        require(
            block.timestamp >= nextValidTimestamp[subscriptionHash],
            "Subscription is not ready"
        );

         
         
        require( requiredToAddress == address(0) || to == requiredToAddress );
        require( requiredTokenAddress == address(0) || tokenAddress == requiredTokenAddress );
        require( requiredTokenAmount == 0 || tokenAmount == requiredTokenAmount );
        require( requiredPeriodSeconds == 0 || periodSeconds == requiredPeriodSeconds );
        require( requiredGasPrice == 0 || gasPrice == requiredGasPrice );

         
        nextValidTimestamp[subscriptionHash] = block.timestamp.add(periodSeconds);

         
        if(nonce > extraNonce[from]){
          extraNonce[from] = nonce;
        }

         
        uint256 startingBalance = ERC20(tokenAddress).balanceOf(to);
        ERC20(tokenAddress).transferFrom(from,to,tokenAmount);
        require(
          (startingBalance+tokenAmount) == ERC20(tokenAddress).balanceOf(to),
          "ERC20 Balance did not change correctly"
        );


        require(
            checkSuccess(),
            "Subscription::executeSubscription TransferFrom failed"
        );

        emit ExecuteSubscription(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasPrice, nonce
        );

         
         
         
        if (gasPrice > 0) {
             
             
             
             
             
             
             
             
            ERC20(tokenAddress).transferFrom(from, msg.sender, gasPrice);
            require(
                checkSuccess(),
                "Subscription::executeSubscription Failed to pay gas as from account"
            );
        }

        return true;
    }

     
     
     
     
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
        uint256 returnValue = 0;

         
        assembly {
             
            switch returndatasize

             
            case 0x0 {
                returnValue := 1
            }

             
            case 0x20 {
                 
                returndatacopy(0x0, 0x0, 0x20)

                 
                returnValue := mload(0x0)
            }

             
            default { }
        }

        return returnValue != 0;
    }

     
     
    function endContract()
        external
    {
      require(msg.sender==author);
      selfdestruct(author);
    }

     
    function () public payable {
       revert ();
    }
}