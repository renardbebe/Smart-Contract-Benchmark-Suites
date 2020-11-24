 

pragma solidity 0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor(address _owner) public {
        owner = _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



contract DetailedERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}



 
contract Validator {
    address public validator;

    event NewValidatorSet(address indexed previousOwner, address indexed newValidator);

     
    constructor() public {
        validator = msg.sender;
    }

     
    modifier onlyValidator() {
        require(msg.sender == validator);
        _;
    }

     
    function setNewValidator(address newValidator) public onlyValidator {
        require(newValidator != address(0));
        emit NewValidatorSet(validator, newValidator);
        validator = newValidator;
    }
}













 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

    constructor(address _owner) 
        public 
        Ownable(_owner) 
    {

    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}







contract Whitelist is Ownable {
    mapping(address => bool) internal investorMap;

     
    event Approved(address indexed investor);

     
    event Disapproved(address indexed investor);

    constructor(address _owner) 
        public 
        Ownable(_owner) 
    {
        
    }

     
    function isInvestorApproved(address _investor) external view returns (bool) {
        require(_investor != address(0));
        return investorMap[_investor];
    }

     
    function approveInvestor(address toApprove) external onlyOwner {
        investorMap[toApprove] = true;
        emit Approved(toApprove);
    }

     
    function approveInvestorsInBulk(address[] toApprove) external onlyOwner {
        for (uint i = 0; i < toApprove.length; i++) {
            investorMap[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

     
    function disapproveInvestor(address toDisapprove) external onlyOwner {
        delete investorMap[toDisapprove];
        emit Disapproved(toDisapprove);
    }

     
    function disapproveInvestorsInBulk(address[] toDisapprove) external onlyOwner {
        for (uint i = 0; i < toDisapprove.length; i++) {
            delete investorMap[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }
}




 
contract CompliantTokenSwitch is Validator, DetailedERC20, MintableToken {
    Whitelist public whiteListingContract;

    struct TransactionStruct {
        address from;
        address to;
        uint256 value;
        uint256 fee;
        address spender;
    }

    mapping (uint => TransactionStruct) public pendingTransactions;
    mapping (address => mapping (address => uint256)) public pendingApprovalAmount;
    uint256 public currentNonce = 0;
    uint256 public transferFee;
    address public feeRecipient;
    bool public tokenSwitch;

    modifier checkIsInvestorApproved(address _account) {
        require(whiteListingContract.isInvestorApproved(_account));
        _;
    }

    modifier checkIsAddressValid(address _account) {
        require(_account != address(0));
        _;
    }

    modifier checkIsValueValid(uint256 _value) {
        require(_value > 0);
        _;
    }

     
    event TransferRejected(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 indexed nonce,
        uint256 reason
    );

     
    event TransferWithFee(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fee
    );

     
    event RecordedPendingTransaction(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 fee,
        address indexed spender,
        uint256 nonce
    );

     
    event TokenSwitchActivated();

     
    event TokenSwitchDeactivated();

     
    event WhiteListingContractSet(address indexed _whiteListingContract);

     
    event FeeSet(uint256 indexed previousFee, uint256 indexed newFee);

     
    event FeeRecipientSet(address indexed previousRecipient, address indexed newRecipient);

     
    constructor(
        address _owner,
        string _name, 
        string _symbol, 
        uint8 _decimals,
        address whitelistAddress,
        address recipient,
        uint256 fee
    )
        public
        MintableToken(_owner)
        DetailedERC20(_name, _symbol, _decimals)
        Validator()
    {
        setWhitelistContract(whitelistAddress);
        setFeeRecipient(recipient);
        setFee(fee);
    }

     
    function setWhitelistContract(address whitelistAddress)
        public
        onlyValidator
        checkIsAddressValid(whitelistAddress)
    {
        whiteListingContract = Whitelist(whitelistAddress);
        emit WhiteListingContractSet(whiteListingContract);
    }

     
    function setFee(uint256 fee)
        public
        onlyValidator
    {
        emit FeeSet(transferFee, fee);
        transferFee = fee;
    }

     
    function setFeeRecipient(address recipient)
        public
        onlyValidator
        checkIsAddressValid(recipient)
    {
        emit FeeRecipientSet(feeRecipient, recipient);
        feeRecipient = recipient;
    }

     
    function activateTokenSwitch() public onlyValidator {
        tokenSwitch = true;
        emit TokenSwitchActivated();
    }

      
    function deactivateTokenSwitch() public onlyValidator {
        tokenSwitch = false;
        emit TokenSwitchDeactivated();
    }

     
    function updateName(string _name) public onlyOwner {
        require(bytes(_name).length != 0);
        name = _name;
    }

     
    function updateSymbol(string _symbol) public onlyOwner {
        require(bytes(_symbol).length != 0);
        symbol = _symbol;
    }

     
    function transfer(address _to, uint256 _value)
        public
        checkIsInvestorApproved(msg.sender)
        checkIsInvestorApproved(_to)
        checkIsValueValid(_value)
        returns (bool)
    {
        if (tokenSwitch) {
            super.transfer(_to, _value);
        } else {
            uint256 pendingAmount = pendingApprovalAmount[msg.sender][address(0)];
            uint256 fee = 0;

            if (msg.sender == feeRecipient) {
                require(_value.add(pendingAmount) <= balances[msg.sender]);
                pendingApprovalAmount[msg.sender][address(0)] = pendingAmount.add(_value);
            } else {
                fee = transferFee;
                require(_value.add(pendingAmount).add(transferFee) <= balances[msg.sender]);
                pendingApprovalAmount[msg.sender][address(0)] = pendingAmount.add(_value).add(transferFee);
            }

            pendingTransactions[currentNonce] = TransactionStruct(
                msg.sender,
                _to,
                _value,
                fee,
                address(0)
            );

            emit RecordedPendingTransaction(msg.sender, _to, _value, fee, address(0), currentNonce);
            currentNonce++;
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public 
        checkIsInvestorApproved(_from)
        checkIsInvestorApproved(_to)
        checkIsValueValid(_value)
        returns (bool)
    {
        if (tokenSwitch) {
            super.transferFrom(_from, _to, _value);
        } else {
            uint256 allowedTransferAmount = allowed[_from][msg.sender];
            uint256 pendingAmount = pendingApprovalAmount[_from][msg.sender];
            uint256 fee = 0;
            
            if (_from == feeRecipient) {
                require(_value.add(pendingAmount) <= balances[_from]);
                require(_value.add(pendingAmount) <= allowedTransferAmount);
                pendingApprovalAmount[_from][msg.sender] = pendingAmount.add(_value);
            } else {
                fee = transferFee;
                require(_value.add(pendingAmount).add(transferFee) <= balances[_from]);
                require(_value.add(pendingAmount).add(transferFee) <= allowedTransferAmount);
                pendingApprovalAmount[_from][msg.sender] = pendingAmount.add(_value).add(transferFee);
            }

            pendingTransactions[currentNonce] = TransactionStruct(
                _from,
                _to,
                _value,
                fee,
                msg.sender
            );

            emit RecordedPendingTransaction(_from, _to, _value, fee, msg.sender, currentNonce);
            currentNonce++;
        }

        return true;
    }

     
    function approveTransfer(uint256 nonce)
        external 
        onlyValidator
    {   
        require(_approveTransfer(nonce));
    }    

     
    function rejectTransfer(uint256 nonce, uint256 reason)
        external 
        onlyValidator
    {        
        _rejectTransfer(nonce, reason);
    }

     
    function bulkApproveTransfers(uint256[] nonces)
        external 
        onlyValidator
        returns (bool)
    {
        for (uint i = 0; i < nonces.length; i++) {
            require(_approveTransfer(nonces[i]));
        }
    }

     
    function bulkRejectTransfers(uint256[] nonces, uint256[] reasons)
        external 
        onlyValidator
    {
        require(nonces.length == reasons.length);
        for (uint i = 0; i < nonces.length; i++) {
            _rejectTransfer(nonces[i], reasons[i]);
        }
    }

     
    function _approveTransfer(uint256 nonce)
        private
        checkIsInvestorApproved(pendingTransactions[nonce].from)
        checkIsInvestorApproved(pendingTransactions[nonce].to)
        returns (bool)
    {   
        address from = pendingTransactions[nonce].from;
        address to = pendingTransactions[nonce].to;
        address spender = pendingTransactions[nonce].spender;
        uint256 value = pendingTransactions[nonce].value;
        uint256 fee = pendingTransactions[nonce].fee;

        delete pendingTransactions[nonce];

        if (fee == 0) {

            balances[from] = balances[from].sub(value);
            balances[to] = balances[to].add(value);

            if (spender != address(0)) {
                allowed[from][spender] = allowed[from][spender].sub(value);
            }

            pendingApprovalAmount[from][spender] = pendingApprovalAmount[from][spender].sub(value);

            emit Transfer(
                from,
                to,
                value
            );

        } else {

            balances[from] = balances[from].sub(value.add(fee));
            balances[to] = balances[to].add(value);
            balances[feeRecipient] = balances[feeRecipient].add(fee);

            if (spender != address(0)) {
                allowed[from][spender] = allowed[from][spender].sub(value).sub(fee);
            }

            pendingApprovalAmount[from][spender] = pendingApprovalAmount[from][spender].sub(value).sub(fee);
            
            emit TransferWithFee(
                from,
                to,
                value,
                fee
            );

        }

        return true;
    }    

     
    function _rejectTransfer(uint256 nonce, uint256 reason)
        private
        checkIsAddressValid(pendingTransactions[nonce].from)
    {        
        address from = pendingTransactions[nonce].from;
        address spender = pendingTransactions[nonce].spender;
        uint256 value = pendingTransactions[nonce].value;

        if (pendingTransactions[nonce].fee == 0) {
            pendingApprovalAmount[from][spender] = pendingApprovalAmount[from][spender]
                .sub(value);
        } else {
            pendingApprovalAmount[from][spender] = pendingApprovalAmount[from][spender]
                .sub(value).sub(pendingTransactions[nonce].fee);
        }
        
        emit TransferRejected(
            from,
            pendingTransactions[nonce].to,
            value,
            nonce,
            reason
        );
        
        delete pendingTransactions[nonce];
    }
}