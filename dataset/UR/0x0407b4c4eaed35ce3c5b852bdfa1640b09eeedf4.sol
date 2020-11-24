 

 

pragma solidity 0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
 contract ERC865Basic is ERC20 {
     function _transferPreSigned(
         bytes _signature,
         address _from,
         address _to,
         uint256 _value,
         uint256 _fee,
         uint256 _nonce
     )
        internal;

     event TransferPreSigned(
         address indexed delegate,
         address indexed from,
         address indexed to,
         uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 

 contract ERC865BasicToken is ERC865Basic, StandardToken {
     
    address internal feeAccount;
    mapping(bytes => bool) internal signatures;

     
    function _transferPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal
    {
         
        require(_to != address(0));
        require(signatures[_signature] == false);

         
        bytes32 hashedTx = _transferPreSignedHashing(_to, _value, _fee, _nonce);

         
        address from = _recover(hashedTx, _signature);
        require(from == _from);
        uint256 total = _value.add(_fee);
        require(total <= balances[from]);

         
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[feeAccount] = balances[feeAccount].add(_fee);

         
        signatures[_signature] = true;

         
        emit TransferPreSigned(msg.sender, from, _to, _value);
        emit TransferPreSigned(msg.sender, from, feeAccount, _fee);
        
         
        emit Transfer(from, _to, _value);
        emit Transfer(from, feeAccount, _fee);
    }

     
    function _transferPreSignedHashing(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal pure
        returns (bytes32)
    {
         
        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _fee,_nonce));

         
        return _prefix(hash);
    }

     
    function _prefix(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

     
    function _recover(bytes32 _hash, bytes _sig) internal pure returns (address) {
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
}

 

 
contract TaxedToken is ERC865BasicToken {
     
    uint8 public taxRate;

     
    function transfer(
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(msg.sender, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        emit Transfer(msg.sender, feeAccount, fee);

        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(_from, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, feeAccount, fee);

        return true;
    }
}

 

 
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

 

 
contract Authorizable is Ownable {
    using SafeMath for uint256;

    address[] public authorized;
    mapping(address => bool) internal authorizedIndex;
    uint8 public numAuthorized;

     
    constructor() public {
        authorized.length = 2;
        authorized[1] = msg.sender;
        authorizedIndex[msg.sender] = true;
        numAuthorized = 1;
    }

     
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

     
    function addAuthorized(address _account) public onlyOwner {
        if (authorizedIndex[_account] == false) {
        	authorizedIndex[_account] = true;
        	authorized.length++;
        	authorized[authorized.length.sub(1)] = _account;
        	numAuthorized++;
        }
    }

     
    function isAuthorized(address _account) public constant returns (bool) {
        if (authorizedIndex[_account] == true) {
        	return true;
        }

        return false;
    }

     
    function removeAuthorized(address _account) public onlyOwner {
        require(isAuthorized(_account)); 
        authorizedIndex[_account] = false;
        numAuthorized--;
    }
}

 

 

contract BlockWRKToken is TaxedToken, Authorizable {
     
    string public name = "BlockWRK";
    string public symbol = "WRK";
    uint8 public decimals = 4;
    uint256 public INITIAL_SUPPLY;

     
    address public distributionPoolWallet;
    address public inAppPurchaseWallet;
    address public reservedTokenWallet;
    uint256 public premineDistributionPool;
    uint256 public premineReserved;

     
    uint256 internal decimalValue = 10000;

    constructor() public {
        feeAccount = 0xeCced56A201d1A6D1Da31A060868F96ACdba99B3;
        distributionPoolWallet = 0xAB3Edd46E9D52e1b3131757e1Ed87FA885f48019;
        inAppPurchaseWallet = 0x97eae8151487e054112E27D8c2eE5f17B3C6A83c;
        reservedTokenWallet = 0xd6E4E287a4aE2E9d8BF7f0323f440acC0d5AD301;
        premineDistributionPool = decimalValue.mul(5600000000);
        premineReserved = decimalValue.mul(2000000000);
        INITIAL_SUPPLY = premineDistributionPool.add(premineReserved);
        balances[distributionPoolWallet] = premineDistributionPool;
        emit Transfer(address(this), distributionPoolWallet, premineDistributionPool);
        balances[reservedTokenWallet] = premineReserved;
        emit Transfer(address(this), reservedTokenWallet, premineReserved);
        totalSupply_ = INITIAL_SUPPLY;
        taxRate = 2;
    }

     
    function inAppTokenDistribution(
        address _to,
        uint256 _value
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[distributionPoolWallet]);
        require(_to != address(0));

        balances[distributionPoolWallet] = balances[distributionPoolWallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(distributionPoolWallet, _to, _value);
    }

     
    function inAppTokenPurchase(
        address _to,
        uint256 _value,
        uint256 _fee
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[inAppPurchaseWallet]);
        require(_to != address(0));

        balances[inAppPurchaseWallet] = balances[inAppPurchaseWallet].sub(_value);
        uint256 netAmount = _value.sub(_fee);
        balances[_to] = balances[_to].add(netAmount);
        emit Transfer(inAppPurchaseWallet, _to, netAmount);
        balances[feeAccount] = balances[feeAccount].add(_fee);
        emit Transfer(inAppPurchaseWallet, feeAccount, _fee);
    }

     
    function setTaxRate(uint8 _newRate) public onlyOwner {
        taxRate = _newRate;
    }

     
    function setFeeAccount(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        feeAccount = _newAddress;
    }

     
    function setInAppPurchaseWallet(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        inAppPurchaseWallet = _newAddress;
    }

     
    function transactionHandler(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        onlyAuthorized
    {
        _transferPreSigned(_signature, _from, _to, _value, _fee, _nonce);
    }
}

 

 
 contract BlockWRKICO is BlockWRKToken {
     
    address public salesWallet;
    uint256 public cap;
    uint256 public closingTime;
    uint256 public currentTierRate;
    uint256 public openingTime;
    uint256 public weiRaised;

     
     uint256 internal availableInCurrentTier;
     uint256 internal availableInSale;
     uint256 internal totalPremineVolume;
     uint256 internal totalSaleVolume;
     uint256 internal totalTokenVolume;
     uint256 internal tier1Rate;
     uint256 internal tier2Rate;
     uint256 internal tier3Rate;
     uint256 internal tier4Rate;
     uint256 internal tier5Rate;
     uint256 internal tier6Rate;
     uint256 internal tier7Rate;
     uint256 internal tier8Rate;
     uint256 internal tier9Rate;
     uint256 internal tier10Rate;
     uint256 internal tier1Volume;
     uint256 internal tier2Volume;
     uint256 internal tier3Volume;
     uint256 internal tier4Volume;
     uint256 internal tier5Volume;
     uint256 internal tier6Volume;
     uint256 internal tier7Volume;
     uint256 internal tier8Volume;
     uint256 internal tier9Volume;
     uint256 internal tier10Volume;

     constructor() public {
         cap = 9999999999999999999999999999999999999999999999;
         salesWallet = 0xA0E021fC3538ed52F9a3D79249ff1D3A67f91C42;
         openingTime = 1557856800;
         closingTime = 1589479200;

         totalPremineVolume = 76000000000000;
         totalSaleVolume = 43000000000000;
         totalTokenVolume = 119000000000000;
         availableInSale = totalSaleVolume;
         tier1Rate = 100000;
         tier2Rate = 10000;
         tier3Rate = 2000;
         tier4Rate = 1250;
         tier5Rate = 625;
         tier6Rate = 312;
         tier7Rate = 156;
         tier8Rate = 117;
         tier9Rate = 104;
         tier10Rate = 100;
         tier1Volume = totalPremineVolume.add(1000000000000);
         tier2Volume = tier1Volume.add(2000000000000);
         tier3Volume = tier2Volume.add(5000000000000);
         tier4Volume = tier3Volume.add(5000000000000);
         tier5Volume = tier4Volume.add(5000000000000);
         tier6Volume = tier5Volume.add(5000000000000);
         tier7Volume = tier6Volume.add(5000000000000);
         tier8Volume = tier7Volume.add(5000000000000);
         tier9Volume = tier8Volume.add(5000000000000);
         tier10Volume = tier9Volume.add(5000000000000);
     }

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
     event CloseoutSale(address indexed wallet, uint256 amount);



     
     
     

     
    function () external payable {
      buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
      uint256 weiAmount = msg.value;
      _preValidatePurchase(_beneficiary, weiAmount);

       
      uint256 tokens = _calculateTokens(weiAmount);

       
      weiRaised = weiRaised.add(weiAmount);

       
      _processPurchase(_beneficiary, tokens);
      _forwardFunds();
      emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

     
    function capReached() public view returns (bool) {
      return weiRaised >= cap;
    }

      
     function hasClosed() public view returns (bool) {
          
         return block.timestamp > closingTime;
     }



     
     
     

     
    function _calculateTokens(uint256 _amountWei) internal returns (uint256) {
         
        uint256 tokenAmountPending;

         
        uint256 tokenAmountToIssue;

         
         
        uint256 tokensRemainingInTier = _getRemainingTokens(totalSupply_);

         
        uint256 newTokens = _getTokenAmount(_amountWei);

         
        bool nextTier = true;
        while (nextTier) {
            if (newTokens > tokensRemainingInTier) {
                 
                tokenAmountPending = tokensRemainingInTier;
                uint256 newTotal = totalSupply_.add(tokenAmountPending);

                 
                tokenAmountToIssue = tokenAmountToIssue.add(tokenAmountPending);

                 
                uint256 pendingAmountWei = tokenAmountPending.div(currentTierRate);
                uint256 remainingWei = _amountWei.sub(pendingAmountWei);

                 
                tokensRemainingInTier = _getRemainingTokens(newTotal);
                newTokens = _getTokenAmount(remainingWei);
            } else {
                tokenAmountToIssue = tokenAmountToIssue.add(newTokens);
                nextTier = false;
                _setAvailableInCurrentTier(tokensRemainingInTier, newTokens);
                _setAvailableInSale(newTokens);
            }
        }

         
        return tokenAmountToIssue;
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        totalSupply_ = totalSupply_.add(_tokenAmount);
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    }

     
    function _forwardFunds() internal {
        salesWallet.transfer(msg.value);
    }

     
    function _getRemainingTokens(uint256 _tokensSold) internal returns (uint256) {
         
        uint256 remaining;
        if (_tokensSold < tier5Volume) {
            if (_tokensSold < tier3Volume) {
                if (_tokensSold < tier1Volume) {
                    _setCurrentTierRate(tier1Rate);
                    remaining = tier1Volume.sub(_tokensSold);
                } else if (_tokensSold < tier2Volume) {
                    _setCurrentTierRate(tier2Rate);
                    remaining = tier2Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier3Rate);
                    remaining = tier3Volume.sub(_tokensSold);
                }
            } else {
                if (_tokensSold < tier4Volume) {
                    _setCurrentTierRate(tier4Rate);
                    remaining = tier4Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier5Rate);
                    remaining = tier5Volume.sub(_tokensSold);
                }
            }
        } else {
            if (_tokensSold < tier8Volume) {
                if (_tokensSold < tier6Volume) {
                    _setCurrentTierRate(tier6Rate);
                    remaining = tier6Volume.sub(_tokensSold);
                } else if (_tokensSold < tier7Volume) {
                    _setCurrentTierRate(tier7Rate);
                    remaining = tier7Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier8Rate);
                    remaining = tier8Volume.sub(_tokensSold);
                }
            } else {
                if (_tokensSold < tier9Volume) {
                    _setCurrentTierRate(tier9Rate);
                    remaining = tier9Volume.sub(_tokensSold);
                } else {
                    _setCurrentTierRate(tier10Rate);
                    remaining = tier10Volume.sub(_tokensSold);
                }
            }
        }

        return remaining;
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(currentTierRate).mul(decimalValue).div(1 ether);
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= cap);
         
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _setAvailableInCurrentTier(uint256 _tierPreviousRemaining, uint256 _newIssue) internal {
        availableInCurrentTier = _tierPreviousRemaining.sub(_newIssue);
    }

     
    function _setAvailableInSale(uint256 _newIssue) internal {
        availableInSale = totalSaleVolume.sub(_newIssue);
    }

     
    function _setCurrentTierRate(uint256 _rate) internal {
        currentTierRate = _rate;
    }

     
    function tokensRemainingInSale() public view returns (uint256) {
        return availableInSale;
    }

     
    function tokensRemainingInTier() public view returns (uint256) {
        return availableInCurrentTier;
    }

     
     function transferRemainingTokens() public onlyOwner {
          
         require(hasClosed());

          
         require(availableInSale > 0);

          
         balances[distributionPoolWallet] = balances[distributionPoolWallet].add(availableInSale);
         emit CloseoutSale(distributionPoolWallet, availableInSale);
     }
}