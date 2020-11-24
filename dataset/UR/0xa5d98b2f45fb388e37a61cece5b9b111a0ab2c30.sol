 

 

pragma solidity ^0.4.24;


 
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






 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}






contract IToken is ERC20 {
     
     

    function reclaimToken(ERC20Basic _token, address _to) external;

    function setMaxTransferGasPrice(uint newGasPrice) external;

     
    function whitelist(address TAP) external;
    function deWhitelist(address TAP) external;

    function setTransferFeeNumerator(uint newTransferFeeNumerator) external;

     
    function blacklist(address a) external;
    function deBlacklist(address a) external;

     
    function seize(address a) external;

     
    function rebalance(bool deducts, uint tokensAmount) external;

     
    function disableFee(address a) external;
    function enableFee(address a) external;
    function computeFee(uint amount) public view returns(uint);

     
    function renounceOwnership() public;

     
    event Mint(address indexed to, uint amount);
    function mint(address _to, uint _amount) public returns(bool);
     
    function finishMinting() public returns (bool);

     
    event Burn(address indexed burner, uint value);
     
    function burn(uint _value) public;

     
    function pause() public;
    function unpause() public;

     
    function transferOwnership(address newOwner) public;
    function transferSuperownership(address newOwner) external;  

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);
}







 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}






 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}








 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
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



 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}



contract Token is IToken, PausableToken, BurnableToken, MintableToken, DetailedERC20 {
    using SafeMath for uint;
    using SafeERC20 for ERC20Basic;

     
    uint public scaleFactor = 10 ** 18;
    mapping(address => uint) internal lastScalingFactor;

     
    uint constant internal MAX_REBALANCE_PERCENT = 5;

     
     
    uint public maxTransferGasPrice = uint(-1);
    event TransferGasPrice(uint oldGasPrice, uint newGasPrice);

     
     
    uint public transferFeeNumerator = 0;
    uint constant internal MAX_NUM_DISABLED_FEES = 100;
    uint constant internal MAX_FEE_PERCENT = 5;
    uint constant internal TRANSFER_FEE_DENOMINATOR = 10 ** 18;
    mapping(address => bool) public avoidsFees;
    address[] public avoidsFeesArray;
    event TransferFeeNumerator(uint oldNumerator, uint newNumerator);
    event TransferFeeDisabled(address indexed account);
    event TransferFeeEnabled(address indexed account);
    event TransferFee(
        address indexed to,
        AccountClassification
        fromAccountClassification,
        uint amount
    );

     
    mapping(address => bool) public TAPwhiteListed;
    event TAPWhiteListed(address indexed TAP);
    event TAPDeWhiteListed(address indexed TAP);

     
    mapping(address => bool) public transferBlacklisted;
    event TransferBlacklisted(address indexed account);
    event TransferDeBlacklisted(address indexed account);

     
    event FundsSeized(
        address indexed account,
        AccountClassification fromAccountClassification,
        uint amount
    );

     
    enum AccountClassification {Zero, Owner, Superowner, TAP, Other}  
     
    bool public blockOtherAccounts;
    event TransferExtd(
        address indexed from,
        AccountClassification fromAccountClassification,
        address indexed to,
        AccountClassification toAccountClassification,
        uint amount
    );
    event BlockOtherAccounts(bool isEnabled);

     
    event Rebalance(
        bool deducts,
        uint amount,
        uint oldScaleFactor,
        uint newScaleFactor,
        uint oldTotalSupply,
        uint newTotalSupply
    );

     
    address public superowner;
    event SuperownershipTransferred(address indexed previousOwner,
      address indexed newOwner);
    mapping(address => bool) public usedOwners;

    constructor(
      string name,
      string symbol,
      uint8 decimals,
      address _superowner
    )
    public DetailedERC20(name, symbol, decimals)
    {
        require(_superowner != address(0), "superowner is not the zero address");
        superowner = _superowner;
        usedOwners[owner] = true;
        usedOwners[superowner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender),  "sender is owner or superowner");
        _;
    }

    modifier hasMintPermission() {
        require(isOwner(msg.sender),  "sender is owner or superowner");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "account is not the zero address");
        _;
    }

    modifier limitGasPrice() {
        require(tx.gasprice <= maxTransferGasPrice, "gasprice is less than its upper bound");
        _;
    }

     
    function reclaimToken(ERC20Basic _token, address _to) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(_to, balance);
    }

     
    function setMaxTransferGasPrice(uint newGasPrice) external onlyOwner {
        require(newGasPrice != 0, "gas price limit cannot be null");
        emit TransferGasPrice(maxTransferGasPrice, newGasPrice);
        maxTransferGasPrice = newGasPrice;
    }

     
    function whitelist(address TAP) external nonZeroAddress(TAP) onlyOwner {
        require(!isOwner(TAP), "TAP is not owner or superowner");
        require(!TAPwhiteListed[TAP], "TAP cannot be whitlisted");
        emit TAPWhiteListed(TAP);
        TAPwhiteListed[TAP] = true;
    }

     
    function deWhitelist(address TAP) external nonZeroAddress(TAP) onlyOwner {
        require(TAPwhiteListed[TAP], "TAP is whitlisted");
        emit TAPDeWhiteListed(TAP);
        TAPwhiteListed[TAP] = false;
    }

     
    function setTransferFeeNumerator(uint newTransferFeeNumerator) external onlyOwner {
        require(newTransferFeeNumerator <= TRANSFER_FEE_DENOMINATOR.mul(MAX_FEE_PERCENT).div(100),
            "transfer fee numerator is less than its upper bound");
        emit TransferFeeNumerator(transferFeeNumerator, newTransferFeeNumerator);
        transferFeeNumerator = newTransferFeeNumerator;
    }

     
    function blacklist(address account) external nonZeroAddress(account) onlyOwner {
        require(!transferBlacklisted[account], "account is not blacklisted");
        emit TransferBlacklisted(account);
        transferBlacklisted[account] = true;
    }

     
    function deBlacklist(address account) external nonZeroAddress(account) onlyOwner {
        require(transferBlacklisted[account], "account is blacklisted");
        emit TransferDeBlacklisted(account);
        transferBlacklisted[account] = false;
    }

     
    function seize(address account) external nonZeroAddress(account) onlyOwner {
        require(transferBlacklisted[account], "account has been blacklisted");
        updateBalanceAndScaling(account);
        uint balance = balanceOf(account);
        emit FundsSeized(account, getAccountClassification(account), balance);
        super._burn(account, balance);
    }

     
    function disableFee(address account) external nonZeroAddress(account) onlyOwner {
        require(!avoidsFees[account], "account has fees");
        require(avoidsFeesArray.length < MAX_NUM_DISABLED_FEES, "array is not full");
        emit TransferFeeDisabled(account);
        avoidsFees[account] = true;
        avoidsFeesArray.push(account);
    }

     
    function enableFee(address account) external nonZeroAddress(account) onlyOwner {
        require(avoidsFees[account], "account avoids fees");
        emit TransferFeeEnabled(account);
        avoidsFees[account] = false;
        uint len = avoidsFeesArray.length;
        assert(len != 0);
        for (uint i = 0; i < len; i++) {
            if (avoidsFeesArray[i] == account) {
                avoidsFeesArray[i] = avoidsFeesArray[len.sub(1)];
                avoidsFeesArray.length--;
                return;
            }
        }
        assert(false);
    }

     
    function rebalance(bool deducts, uint tokensAmount) external onlyOwner {
        uint oldTotalSupply = totalSupply();
        uint oldScaleFactor = scaleFactor;

        require(
            tokensAmount <= oldTotalSupply.mul(MAX_REBALANCE_PERCENT).div(100),
            "tokensAmount is within limits"
        );

         
        uint newScaleFactor;
        if (deducts) {
            newScaleFactor = oldScaleFactor.mul(
                oldTotalSupply.sub(tokensAmount)).div(oldTotalSupply
            );
        } else {
            newScaleFactor = oldScaleFactor.mul(
                oldTotalSupply.add(tokensAmount)).div(oldTotalSupply
            );
        }
         
        scaleFactor = newScaleFactor;

         
        uint newTotalSupply = oldTotalSupply.mul(scaleFactor).div(oldScaleFactor);
        totalSupply_ = newTotalSupply;

        emit Rebalance(
            deducts,
            tokensAmount,
            oldScaleFactor,
            newScaleFactor,
            oldTotalSupply,
            newTotalSupply
        );

        if (deducts) {
            require(newTotalSupply < oldTotalSupply, "totalSupply shrinks");
             
            assert(oldTotalSupply.sub(tokensAmount.mul(9).div(10)) >= newTotalSupply);
            assert(oldTotalSupply.sub(tokensAmount.mul(11).div(10)) <= newTotalSupply);
        } else {
           require(newTotalSupply > oldTotalSupply, "totalSupply grows");
            
           assert(oldTotalSupply.add(tokensAmount.mul(9).div(10)) <= newTotalSupply);
           assert(oldTotalSupply.add(tokensAmount.mul(11).div(10)) >= newTotalSupply);
        }
    }

     
    function transferSuperownership(
        address _newSuperowner
    )
    external nonZeroAddress(_newSuperowner)
    {
        require(msg.sender == superowner, "only superowner");
        require(!usedOwners[_newSuperowner], "owner was not used before");
        usedOwners[_newSuperowner] = true;
        uint value = balanceOf(superowner);
        if (value > 0) {
            super._burn(superowner, value);
            emit TransferExtd(
                superowner,
                AccountClassification.Superowner,
                address(0),
                AccountClassification.Zero,
                value
            );
        }
        emit SuperownershipTransferred(superowner, _newSuperowner);
        superowner = _newSuperowner;
    }

     
    function balanceOf(address account) public view returns (uint) {
        uint amount = balances[account];
        uint oldScaleFactor = lastScalingFactor[account];
        if (oldScaleFactor == 0) {
            return 0;
        } else if (oldScaleFactor == scaleFactor) {
            return amount;
        } else {
            return amount.mul(scaleFactor).div(oldScaleFactor);
        }
    }

     
    function computeFee(uint amount) public view returns (uint) {
        return amount.mul(transferFeeNumerator).div(TRANSFER_FEE_DENOMINATOR);
    }

     
    function totalSupply() public view returns(uint) {
        uint inventory = balanceOf(owner);
        if (owner != superowner) {
            inventory = inventory.add(balanceOf(superowner));
        }
        return (super.totalSupply().sub(inventory));
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(!usedOwners[_newOwner], "owner was not used before");
        usedOwners[_newOwner] = true;
        uint value = balanceOf(owner);
        if (value > 0) {
            super._burn(owner, value);
            emit TransferExtd(
                owner,
                AccountClassification.Owner,
                address(0),
                AccountClassification.Zero,
                value
            );
        }
        super.transferOwnership(_newOwner);
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public whenNotPaused returns (bool)
    {
        updateBalanceAndScaling(msg.sender);
        updateBalanceAndScaling(_spender);
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public whenNotPaused returns (bool)
    {
        updateBalanceAndScaling(msg.sender);
        updateBalanceAndScaling(_spender);
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
    function transfer(
        address _to,
        uint _value
    )
    public whenNotPaused limitGasPrice returns (bool)
    {
        require(!transferBlacklisted[msg.sender], "sender is not blacklisted");
        require(!transferBlacklisted[_to], "to address is not blacklisted");
        require(!blockOtherAccounts ||
            (getAccountClassification(msg.sender) != AccountClassification.Other &&
            getAccountClassification(_to) != AccountClassification.Other),
            "addresses are not blocked");

        emit TransferExtd(
            msg.sender,
            getAccountClassification(msg.sender),
            _to,
            getAccountClassification(_to),
            _value
        );

        updateBalanceAndScaling(msg.sender);

        if (_to == address(0)) {
             
            super.burn(_value);
            return true;
        }

        updateBalanceAndScaling(_to);

        require(super.transfer(_to, _value), "transfer succeeds");

        if (!avoidsFees[msg.sender] && !avoidsFees[_to]) {
            computeAndBurnFee(_to, _value);
        }

        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint _value
    )
    public whenNotPaused limitGasPrice returns (bool)
    {
        require(!transferBlacklisted[msg.sender], "sender is not blacklisted");
        require(!transferBlacklisted[_from], "from address is not blacklisted");
        require(!transferBlacklisted[_to], "to address is not blacklisted");
        require(!blockOtherAccounts ||
            (getAccountClassification(_from) != AccountClassification.Other &&
            getAccountClassification(_to) != AccountClassification.Other),
            "addresses are not blocked");

        emit TransferExtd(
            _from,
            getAccountClassification(_from),
            _to,
            getAccountClassification(_to),
            _value
        );

        updateBalanceAndScaling(_from);

        if (_to == address(0)) {
             
            super.transferFrom(_from, msg.sender, _value);
            super.burn(_value);
            return true;
        }

        updateBalanceAndScaling(_to);

        require(super.transferFrom(_from, _to, _value), "transfer succeeds");

        if (!avoidsFees[msg.sender] && !avoidsFees[_from] && !avoidsFees[_to]) {
            computeAndBurnFee(_to, _value);
        }

        return true;
    }

     
    function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
        updateBalanceAndScaling(_spender);
        return super.approve(_spender, _value);
    }

     
    function mint(address _to, uint _amount) public returns(bool) {
        require(!transferBlacklisted[_to], "to address is not blacklisted");
        require(!blockOtherAccounts || getAccountClassification(_to) != AccountClassification.Other,
            "to address is not blocked");
        updateBalanceAndScaling(_to);
        emit TransferExtd(
            address(0),
            AccountClassification.Zero,
            _to,
            getAccountClassification(_to),
            _amount
        );
        return super.mint(_to, _amount);
    }

     
    function toggleBlockOtherAccounts() public onlyOwner {
        blockOtherAccounts = !blockOtherAccounts;
        emit BlockOtherAccounts(blockOtherAccounts);
    }

     
    function getAccountClassification(
        address account
    )
    internal view returns(AccountClassification)
    {
        if (account == address(0)) {
            return AccountClassification.Zero;
        } else if (account == owner) {
            return AccountClassification.Owner;
        } else if (account == superowner) {
            return AccountClassification.Superowner;
        } else if (TAPwhiteListed[account]) {
            return AccountClassification.TAP;
        } else {
            return AccountClassification.Other;
        }
    }

     
    function isOwner(address account) internal view returns (bool) {
        return account == owner || account == superowner;
    }

     
    function updateBalanceAndScaling(address account) internal {
        uint oldBalance = balances[account];
        uint newBalance = balanceOf(account);
        if (lastScalingFactor[account] != scaleFactor) {
            lastScalingFactor[account] = scaleFactor;
        }
        if (oldBalance != newBalance) {
            balances[account] = newBalance;
        }
    }

     
    function computeAndBurnFee(address _to, uint _value) internal {
        uint fee = computeFee(_value);
        if (fee > 0) {
            _burn(_to, fee);
            emit TransferFee(_to, getAccountClassification(_to), fee);
        }
    }

     
    function finishMinting() public returns (bool) {
        require(false, "is disabled");
        return false;
    }

     
    function burn(uint  ) public {
         
        require(false, "is disabled");
    }

     
    function renounceOwnership() public {
        require(false, "is disabled");
    }
}