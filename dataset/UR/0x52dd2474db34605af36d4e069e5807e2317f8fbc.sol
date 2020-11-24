 

 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.21;



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.21;




 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

pragma solidity ^0.4.21;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

pragma solidity ^0.4.21;




 
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.4.21;




 
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

 

pragma solidity ^0.4.21;


 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

pragma solidity ^0.4.21;


 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

pragma solidity ^0.4.21;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

pragma solidity ^0.4.21;






 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

pragma solidity ^0.4.23;

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string _a, string _b, string _c) internal pure returns (string) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }

  function uint2str(uint i) internal pure returns (string) {
    if (i == 0) return "0";
    uint j = i;
    uint len;
    while (j != 0){
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0){
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }
    return string(bstr);
  }
}

 

pragma solidity ^0.4.23;






interface ERC721Metadata   {
   
  function name() external view returns (string _name);

   
  function symbol() external view returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}

contract DefinerBasicLoan is ERC721BasicToken, ERC721Metadata {
  using SafeERC20 for ERC20;
  using SafeMath for uint;

  enum States {
    Init,                  
    WaitingForLender,      
    WaitingForBorrower,    
    WaitingForCollateral,  
    WaitingForFunds,       
    Funded,                
    Finished,              
    Closed,                
    Default,               
    Cancelled              
  }

  address public ownerAddress;
  address public borrowerAddress;
  address public lenderAddress;
  string public loanId;
  uint public endTime;   
  uint public nextPaymentDateTime;  
  uint public daysPerInstallment;  
  uint public totalLoanTerm;  
  uint public borrowAmount;  
  uint public collateralAmount;  
  uint public installmentAmount;  
  uint public remainingInstallment;  

  States public currentState = States.Init;

   
  address internal factoryContract;  
  modifier onlyFactoryContract() {
      require(factoryContract == 0 || msg.sender == factoryContract, "not factory contract");
      _;
  }

  modifier atState(States state) {
    require(state == currentState, "Invalid State");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == ownerAddress, "Invalid Owner Address");
    _;
  }

  modifier onlyLender() {
    require(msg.sender == lenderAddress || msg.sender == factoryContract, "Invalid Lender Address");
    _;
  }

  modifier onlyBorrower() {
    require(msg.sender == borrowerAddress || msg.sender == factoryContract, "Invalid Borrower Address");
    _;
  }

  modifier notDefault() {
    require(now < nextPaymentDateTime, "This Contract has not yet default");
    require(now < endTime, "This Contract has not yet default");
    _;
  }

   

  function name() public view returns (string _name)
  {
    return "DeFiner Contract";
  }

  function symbol() public view returns (string _symbol)
  {
    return "DFINC";
  }

  function tokenURI(uint256) public view returns (string)
  {
    return Strings.strConcat(
      "https://api.definer.org/OKh4I2yYpKU8S2af/definer/api/v1.0/opensea/",
      loanId
    );
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_from != address(0));
    require(_to != address(0));

    super.transferFrom(_from, _to, _tokenId);
    lenderAddress = tokenOwner[_tokenId];
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  public
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
    lenderAddress = tokenOwner[_tokenId];
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
  public
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    lenderAddress = tokenOwner[_tokenId];
  }


   
  function transferCollateral() public payable  ;

   
  function checkCollateral() public  ;

   
  function borrowerCancel() public  ;

   
  function lenderCancel() public  ;

   
  function transferFunds() public payable  ;

   
  function checkFunds() public  ;

   
  function borrowerMakePayment() public payable  ;

   
  function borrowerReclaimCollateral() public  ;

   
  function lenderReclaimCollateral() public  ;


   
  function borrowerAcceptLoan() public atState(States.WaitingForBorrower) {
    require(msg.sender != address(0), "Invalid address.");
    borrowerAddress = msg.sender;
    currentState = States.WaitingForCollateral;
  }

   
  function lenderAcceptLoan() public atState(States.WaitingForLender) {
    require(msg.sender != address(0), "Invalid address.");
    lenderAddress = msg.sender;
    currentState = States.WaitingForFunds;
  }

  function transferETHToBorrowerAndStartLoan() internal {
    borrowerAddress.transfer(borrowAmount);
    endTime = now.add(totalLoanTerm.mul(1 days));
    nextPaymentDateTime = now.add(daysPerInstallment.mul(1 days));
    currentState = States.Funded;
  }

  function transferTokenToBorrowerAndStartLoan(StandardToken token) internal {
    require(token.transfer(borrowerAddress, borrowAmount), "Token transfer failed");
    endTime = now.add(totalLoanTerm.mul(1 days));
    nextPaymentDateTime = now.add(daysPerInstallment.mul(1 days));
    currentState = States.Funded;
  }

   
  function checkDefault() public onlyLender atState(States.Funded) returns (bool) {
    if (now > endTime || now > nextPaymentDateTime) {
      currentState = States.Default;
      return true;
    } else {
      return false;
    }
  }

   
  function forceDefault() public onlyOwner {
    currentState = States.Default;
  }

  function getLoanDetails() public view returns (address,address,address,string,uint,uint,uint,uint,uint,uint,uint,uint,uint) {
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    return (
      ownerAddress,
      borrowerAddress,
      lenderAddress,
      loanId,
      endTime,
      nextPaymentDateTime,
      daysPerInstallment,
      totalLoanTerm,
      borrowAmount,
      collateralAmount,
      installmentAmount,
      remainingInstallment,
      uint(currentState)
    );
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ETHLoan is DefinerBasicLoan {

  StandardToken token;
  address public collateralTokenAddress;

   
  function transferCollateral() public payable {
    revert();
  }

  function establishContract() public {

     
    uint amount = token.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient collateral amount");

     
    require(address(this).balance >= borrowAmount, "Insufficient fund amount");

     
    transferETHToBorrowerAndStartLoan();
  }

   
  function checkFunds() onlyLender atState(States.WaitingForFunds) public {
    return establishContract();
  }

   
  function checkCollateral() public onlyBorrower atState(States.WaitingForCollateral) {
    uint amount = token.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient collateral amount");
    currentState = States.WaitingForLender;
  }

   
  function transferFunds() public payable onlyLender atState(States.WaitingForFunds) {
    if (address(this).balance >= borrowAmount) {
      establishContract();
    }
  }

   
  function borrowerMakePayment() public payable onlyBorrower atState(States.Funded) notDefault {
    require(msg.value >= installmentAmount);
    remainingInstallment--;
    lenderAddress.transfer(installmentAmount);
    if (remainingInstallment == 0) {
      currentState = States.Finished;
    } else {
      nextPaymentDateTime = nextPaymentDateTime.add(daysPerInstallment.mul(1 days));
    }
  }

   
  function borrowerReclaimCollateral() public onlyBorrower atState(States.Finished) {
    uint amount = token.balanceOf(address(this));
    token.transfer(borrowerAddress, amount);
    currentState = States.Closed;
  }

   
  function lenderReclaimCollateral() public onlyLender atState(States.Default) {
    uint amount = token.balanceOf(address(this));
    token.transfer(lenderAddress, amount);
    currentState = States.Closed;
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ETHLoanBorrower is ERC20ETHLoan {
  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _collateralTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_collateralTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    collateralTokenAddress = _collateralTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    token = StandardToken(_collateralTokenAddress);
    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;

     
    currentState = States.WaitingForCollateral;
  }

   
  function checkFunds() onlyLender atState(States.WaitingForFunds) public {
    return establishContract();
  }

   
  function checkCollateral() public onlyBorrower atState(States.WaitingForCollateral) {
    uint amount = token.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient collateral amount");
    currentState = States.WaitingForFunds;
  }

   
  function transferFunds() public payable onlyLender atState(States.WaitingForFunds) {
    if (address(this).balance >= borrowAmount) {
      establishContract();
    }
  }

   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    uint amount = token.balanceOf(address(this));
    token.transfer(borrowerAddress, amount);
    currentState = States.Cancelled;
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
     
    revert();
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ETHLoanLender is ERC20ETHLoan {
  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _collateralTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_collateralTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    collateralTokenAddress = _collateralTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    token = StandardToken(_collateralTokenAddress);
    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;

     
    currentState = States.WaitingForFunds;
  }

   
  function checkCollateral() public onlyBorrower atState(States.WaitingForCollateral) {
    return establishContract();
  }

   
  function transferFunds() public payable onlyLender atState(States.WaitingForFunds) {
    if (address(this).balance >= borrowAmount) {
      currentState = States.WaitingForCollateral;
    }
  }


   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    revert();
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
    lenderAddress.transfer(address(this).balance);
    currentState = States.Cancelled;
  }
}

 

pragma solidity ^0.4.23;


 
contract ETHERC20Loan is DefinerBasicLoan {

  StandardToken token;
  address public borrowedTokenAddress;

  function establishContract() public {

     
    uint amount = token.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient collateral amount");

     
    require(address(this).balance >= borrowAmount, "Insufficient fund amount");

     
    transferETHToBorrowerAndStartLoan();
  }

   
  function borrowerMakePayment() public payable onlyBorrower atState(States.Funded) notDefault {
    require(remainingInstallment > 0, "No remaining installments");
    require(installmentAmount > 0, "Installment amount must be non zero");
    token.transfer(lenderAddress, installmentAmount);
    remainingInstallment--;
    if (remainingInstallment == 0) {
      currentState = States.Finished;
    } else {
      nextPaymentDateTime = nextPaymentDateTime.add(daysPerInstallment.mul(1 days));
    }
  }

   
  function borrowerReclaimCollateral() public onlyBorrower atState(States.Finished) {
    borrowerAddress.transfer(address(this).balance);
    currentState = States.Closed;
  }

   
  function lenderReclaimCollateral() public onlyLender atState(States.Default) {
    lenderAddress.transfer(address(this).balance);
    currentState = States.Closed;
  }
}

 

pragma solidity ^0.4.23;


 
contract ETHERC20LoanBorrower is ETHERC20Loan {
  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_borrowedTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    borrowedTokenAddress = _borrowedTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    token = StandardToken(_borrowedTokenAddress);
    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;

    currentState = States.WaitingForCollateral;
  }

   
  function transferCollateral() public payable atState(States.WaitingForCollateral) {
    if (address(this).balance >= collateralAmount) {
      currentState = States.WaitingForFunds;
    }
  }

   
  function checkFunds() public onlyLender atState(States.WaitingForFunds) {
    uint amount = token.balanceOf(address(this));
    require(amount >= borrowAmount, "Insufficient borrowed amount");
    transferTokenToBorrowerAndStartLoan(token);
  }

   
  function checkCollateral() public {
    revert();
  }

   
  function transferFunds() public payable {
    revert();
  }

   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    borrowerAddress.transfer(address(this).balance);
    currentState = States.Cancelled;
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
    revert();
  }
}

 

pragma solidity ^0.4.23;


 
contract ETHERC20LoanLender is ETHERC20Loan {

  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_borrowedTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    borrowedTokenAddress = _borrowedTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    token = StandardToken(_borrowedTokenAddress);
    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;

    currentState = States.WaitingForFunds;
  }

   
  function transferCollateral() public payable atState(States.WaitingForCollateral) {
    require(address(this).balance >= collateralAmount, "Insufficient ETH collateral amount");
    transferTokenToBorrowerAndStartLoan(token);
  }

   
  function checkFunds() public onlyLender atState(States.WaitingForFunds) {
    uint amount = token.balanceOf(address(this));
    require(amount >= borrowAmount, "Insufficient fund amount");
    currentState = States.WaitingForCollateral;
  }

   
  function checkCollateral() public {
    revert();
  }

   
  function transferFunds() public payable {
    revert();
  }

   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    revert();
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
    uint amount = token.balanceOf(address(this));
    token.transfer(lenderAddress, amount);
    currentState = States.Cancelled;
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ERC20Loan is DefinerBasicLoan {

  StandardToken collateralToken;
  StandardToken borrowedToken;
  address public collateralTokenAddress;
  address public borrowedTokenAddress;

   
  function borrowerMakePayment() public payable onlyBorrower atState(States.Funded) notDefault {
    require(remainingInstallment > 0, "No remaining installments");
    require(installmentAmount > 0, "Installment amount must be non zero");
    borrowedToken.transfer(lenderAddress, installmentAmount);
    remainingInstallment--;
    if (remainingInstallment == 0) {
      currentState = States.Finished;
    } else {
      nextPaymentDateTime = nextPaymentDateTime.add(daysPerInstallment.mul(1 days));
    }
  }

   
  function borrowerReclaimCollateral() public onlyBorrower atState(States.Finished) {
    uint amount = collateralToken.balanceOf(address(this));
    collateralToken.transfer(borrowerAddress, amount);
    currentState = States.Closed;
  }

   
  function lenderReclaimCollateral() public onlyLender atState(States.Default) {
    uint amount = collateralToken.balanceOf(address(this));
    collateralToken.transfer(lenderAddress, amount);
    currentState = States.Closed;
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ERC20LoanBorrower is ERC20ERC20Loan {

  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _collateralTokenAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_collateralTokenAddress != _borrowedTokenAddress);
    require(_collateralTokenAddress != address(0), "Invalid token address");
    require(_borrowedTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    collateralTokenAddress = _collateralTokenAddress;
    borrowedTokenAddress = _borrowedTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    collateralToken = StandardToken(_collateralTokenAddress);
    borrowedToken = StandardToken(_borrowedTokenAddress);

    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;
    currentState = States.WaitingForCollateral;
  }

   
  function transferCollateral() public payable {
    revert();
  }

   
  function transferFunds() public payable {
    revert();
  }

   
  function checkFunds() public onlyLender atState(States.WaitingForFunds) {
    uint amount = borrowedToken.balanceOf(address(this));
    require(amount >= borrowAmount, "Insufficient borrowed amount");
    transferTokenToBorrowerAndStartLoan(borrowedToken);
  }

   
  function checkCollateral() public onlyBorrower atState(States.WaitingForCollateral) {
    uint amount = collateralToken.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient Collateral Token amount");
    currentState = States.WaitingForFunds;
  }

   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    uint amount = collateralToken.balanceOf(address(this));
    collateralToken.transfer(borrowerAddress, amount);
    currentState = States.Cancelled;
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
    revert();
  }
}

 

pragma solidity ^0.4.23;


 
contract ERC20ERC20LoanLender is ERC20ERC20Loan {

  function init (
    address _ownerAddress,
    address _borrowerAddress,
    address _lenderAddress,
    address _collateralTokenAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId
  ) public onlyFactoryContract {
    require(_collateralTokenAddress != _borrowedTokenAddress);
    require(_collateralTokenAddress != address(0), "Invalid token address");
    require(_borrowedTokenAddress != address(0), "Invalid token address");
    require(_borrowerAddress != address(0), "Invalid lender address");
    require(_lenderAddress != address(0), "Invalid lender address");
    require(_remainingInstallment > 0, "Invalid number of installments");
    require(_borrowAmount > 0, "Borrow amount must not be 0");
    require(_paybackAmount > 0, "Payback amount must not be 0");
    require(_collateralAmount > 0, "Collateral amount must not be 0");
    super._mint(_lenderAddress, 1);
    factoryContract = msg.sender;
    ownerAddress = _ownerAddress;
    loanId = _loanId;
    collateralTokenAddress = _collateralTokenAddress;
    borrowedTokenAddress = _borrowedTokenAddress;
    borrowAmount = _borrowAmount;
    collateralAmount = _collateralAmount;
    totalLoanTerm = _remainingInstallment * _daysPerInstallment;
    daysPerInstallment = _daysPerInstallment;
    remainingInstallment = _remainingInstallment;
    installmentAmount = _paybackAmount / _remainingInstallment;
    collateralToken = StandardToken(_collateralTokenAddress);
    borrowedToken = StandardToken(_borrowedTokenAddress);

    borrowerAddress = _borrowerAddress;
    lenderAddress = _lenderAddress;
    currentState = States.WaitingForFunds;
  }

   
  function transferCollateral() public payable {
    revert();
  }

   
  function transferFunds() public payable {
    revert();
  }

   
  function checkFunds() public onlyLender atState(States.WaitingForFunds) {
    uint amount = borrowedToken.balanceOf(address(this));
    require(amount >= borrowAmount, "Insufficient fund amount");
    currentState = States.WaitingForCollateral;
  }

   
  function checkCollateral() public onlyBorrower atState(States.WaitingForCollateral) {
    uint amount = collateralToken.balanceOf(address(this));
    require(amount >= collateralAmount, "Insufficient Collateral Token amount");
    transferTokenToBorrowerAndStartLoan(borrowedToken);
  }

   
  function borrowerCancel() public onlyBorrower atState(States.WaitingForFunds) {
    revert();
  }

   
  function lenderCancel() public onlyLender atState(States.WaitingForCollateral) {
    uint amount = borrowedToken.balanceOf(address(this));
    borrowedToken.transfer(lenderAddress, amount);
    currentState = States.Cancelled;
  }
}

 

pragma solidity ^0.4.23;







library Library {
  struct contractAddress {
    address value;
    bool exists;
  }
}

contract CloneFactory {
  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[20 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

contract DefinerLoanFactory is CloneFactory {

  using Library for Library.contractAddress;

  address public owner = msg.sender;
  address public ERC20ETHLoanBorrowerMasterContractAddress;
  address public ERC20ETHLoanLenderMasterContractAddress;

  address public ETHERC20LoanBorrowerMasterContractAddress;
  address public ETHERC20LoanLenderMasterContractAddress;

  address public ERC20ERC20LoanBorrowerMasterContractAddress;
  address public ERC20ERC20LoanLenderMasterContractAddress;

  mapping(address => address[]) contractMap;
  mapping(string => Library.contractAddress) contractById;

  modifier onlyOwner() {
    require(msg.sender == owner, "Invalid Owner Address");
    _;
  }

  constructor (
    address _ERC20ETHLoanBorrowerMasterContractAddress,
    address _ERC20ETHLoanLenderMasterContractAddress,
    address _ETHERC20LoanBorrowerMasterContractAddress,
    address _ETHERC20LoanLenderMasterContractAddress,
    address _ERC20ERC20LoanBorrowerMasterContractAddress,
    address _ERC20ERC20LoanLenderMasterContractAddress
  ) public {
    owner = msg.sender;
    ERC20ETHLoanBorrowerMasterContractAddress = _ERC20ETHLoanBorrowerMasterContractAddress;
    ERC20ETHLoanLenderMasterContractAddress = _ERC20ETHLoanLenderMasterContractAddress;
    ETHERC20LoanBorrowerMasterContractAddress = _ETHERC20LoanBorrowerMasterContractAddress;
    ETHERC20LoanLenderMasterContractAddress = _ETHERC20LoanLenderMasterContractAddress;
    ERC20ERC20LoanBorrowerMasterContractAddress = _ERC20ERC20LoanBorrowerMasterContractAddress;
    ERC20ERC20LoanLenderMasterContractAddress = _ERC20ERC20LoanLenderMasterContractAddress;
  }

  function getUserContracts(address userAddress) public view returns (address[]) {
    return contractMap[userAddress];
  }

  function getContractByLoanId(string _loanId) public view returns (address) {
    return contractById[_loanId].value;
  }

  function createERC20ETHLoanBorrowerClone(
    address _collateralTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _lenderAddress
  ) public payable returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ERC20ETHLoanBorrowerMasterContractAddress);
    ERC20ETHLoanBorrower(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : msg.sender,
      _lenderAddress : _lenderAddress,
      _collateralTokenAddress : _collateralTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});

    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }


  function createERC20ETHLoanLenderClone(
    address _collateralTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _borrowerAddress
  ) public payable returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ERC20ETHLoanLenderMasterContractAddress);
    ERC20ETHLoanLender(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : _borrowerAddress,
      _lenderAddress : msg.sender,
      _collateralTokenAddress : _collateralTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});

    if (msg.value > 0) {
      ERC20ETHLoanLender(clone).transferFunds.value(msg.value)();
    }
    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }

  function createETHERC20LoanBorrowerClone(
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _lenderAddress
  ) public payable returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ETHERC20LoanBorrowerMasterContractAddress);
    ETHERC20LoanBorrower(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : msg.sender,
      _lenderAddress : _lenderAddress,
      _borrowedTokenAddress : _borrowedTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});

    if (msg.value >= _collateralAmount) {
      ETHERC20LoanBorrower(clone).transferCollateral.value(msg.value)();
    }

    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }

  function createETHERC20LoanLenderClone(
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _borrowerAddress
  ) public payable returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ETHERC20LoanLenderMasterContractAddress);
    ETHERC20LoanLender(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : _borrowerAddress,
      _lenderAddress : msg.sender,
      _borrowedTokenAddress : _borrowedTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});

    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }

  function createERC20ERC20LoanBorrowerClone(
    address _collateralTokenAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _lenderAddress
  ) public returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ERC20ERC20LoanBorrowerMasterContractAddress);
    ERC20ERC20LoanBorrower(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : msg.sender,
      _lenderAddress : _lenderAddress,
      _collateralTokenAddress : _collateralTokenAddress,
      _borrowedTokenAddress : _borrowedTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});
    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }

  function createERC20ERC20LoanLenderClone(
    address _collateralTokenAddress,
    address _borrowedTokenAddress,
    uint _borrowAmount,
    uint _paybackAmount,
    uint _collateralAmount,
    uint _daysPerInstallment,
    uint _remainingInstallment,
    string _loanId,
    address _borrowerAddress
  ) public returns (address) {
    require(!contractById[_loanId].exists, "contract already exists");

    address clone = createClone(ERC20ERC20LoanLenderMasterContractAddress);
    ERC20ERC20LoanLender(clone).init({
      _ownerAddress : owner,
      _borrowerAddress : _borrowerAddress,
      _lenderAddress : msg.sender,
      _collateralTokenAddress : _collateralTokenAddress,
      _borrowedTokenAddress : _borrowedTokenAddress,
      _borrowAmount : _borrowAmount,
      _paybackAmount : _paybackAmount,
      _collateralAmount : _collateralAmount,
      _daysPerInstallment : _daysPerInstallment,
      _remainingInstallment : _remainingInstallment,
      _loanId : _loanId});
    contractMap[msg.sender].push(clone);
    contractById[_loanId] = Library.contractAddress(clone, true);
    return clone;
  }

  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}