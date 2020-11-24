 

pragma solidity ^0.4.13;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract AddressList is Claimable {
    string public name;
    mapping (address => bool) public onList;

    function AddressList(string _name, bool nullValue) public {
        name = _name;
        onList[0x0] = nullValue;
    }
    event ChangeWhiteList(address indexed to, bool onList);

     
     
    function changeList(address _to, bool _onList) onlyOwner public {
        require(_to != 0x0);
        if (onList[_to] != _onList) {
            onList[_to] = _onList;
            ChangeWhiteList(_to, _onList);
        }
    }
}

contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

contract TimeLockedController is HasNoEther, HasNoTokens, Claimable {
    using SafeMath for uint256;

     
     
    uint public constant blocksDelay = 24*60*60/15;

    struct MintOperation {
        address to;
        uint256 amount;
        address admin;
        uint deferBlock;
    }

    struct TransferOwnershipOperation {
        address newOwner;
        address admin;
        uint deferBlock;
    }

    struct ChangeBurnBoundsOperation {
        uint newMin;
        uint newMax;
        address admin;
        uint deferBlock;
    }

    struct ChangeInsuranceFeesOperation {
        uint80 _transferFeeNumerator;
        uint80 _transferFeeDenominator;
        uint80 _mintFeeNumerator;
        uint80 _mintFeeDenominator;
        uint256 _mintFeeFlat;
        uint80 _burnFeeNumerator;
        uint80 _burnFeeDenominator;
        uint256 _burnFeeFlat;
        address admin;
        uint deferBlock;
    }

    struct ChangeInsurerOperation {
        address newInsurer;
        address admin;
        uint deferBlock;
    }

    address public admin;
    TrueUSD public child;
    AddressList public canBurnWhiteList;
    AddressList public canReceiveMintWhitelist;
    AddressList public blackList;
    MintOperation[] public mintOperations;
    TransferOwnershipOperation public transferOwnershipOperation;
    ChangeBurnBoundsOperation public changeBurnBoundsOperation;
    ChangeInsuranceFeesOperation public changeInsuranceFeesOperation;
    ChangeInsurerOperation public changeInsurerOperation;

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    function computeDeferBlock() private view returns (uint) {
        if (msg.sender == owner) {
            return block.number;
        } else {
            return block.number.add(blocksDelay);
        }
    }

     
    function TimeLockedController(address _child, address _canBurnWhiteList, address _canReceiveMintWhitelist, address _blackList) public {
        child = TrueUSD(_child);
        canBurnWhiteList = AddressList(_canBurnWhiteList);
        canReceiveMintWhitelist = AddressList(_canReceiveMintWhitelist);
        blackList = AddressList(_blackList);
    }

    event MintOperationEvent(address indexed _to, uint256 amount, uint deferBlock, uint opIndex);
    event TransferOwnershipOperationEvent(address newOwner, uint deferBlock);
    event ChangeBurnBoundsOperationEvent(uint newMin, uint newMax, uint deferBlock);
    event ChangeInsuranceFeesOperationEvent(uint80 _transferFeeNumerator,
                                            uint80 _transferFeeDenominator,
                                            uint80 _mintFeeNumerator,
                                            uint80 _mintFeeDenominator,
                                            uint256 _mintFeeFlat,
                                            uint80 _burnFeeNumerator,
                                            uint80 _burnFeeDenominator,
                                            uint256 _burnFeeFlat,
                                            uint deferBlock);
    event ChangeInsurerOperationEvent(address newInsurer, uint deferBlock);
    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

     
    function requestMint(address _to, uint256 _amount) public onlyAdminOrOwner {
        uint deferBlock = computeDeferBlock();
        MintOperation memory op = MintOperation(_to, _amount, admin, deferBlock);
        MintOperationEvent(_to, _amount, deferBlock, mintOperations.length);
        mintOperations.push(op);
    }

     
     
    function requestTransferChildrenOwnership(address newOwner) public onlyAdminOrOwner {
        uint deferBlock = computeDeferBlock();
        transferOwnershipOperation = TransferOwnershipOperation(newOwner, admin, deferBlock);
        TransferOwnershipOperationEvent(newOwner, deferBlock);
    }

     
     
    function requestChangeBurnBounds(uint newMin, uint newMax) public onlyAdminOrOwner {
        uint deferBlock = computeDeferBlock();
        changeBurnBoundsOperation = ChangeBurnBoundsOperation(newMin, newMax, admin, deferBlock);
        ChangeBurnBoundsOperationEvent(newMin, newMax, deferBlock);
    }

     
    function requestChangeInsuranceFees(uint80 _transferFeeNumerator,
                                        uint80 _transferFeeDenominator,
                                        uint80 _mintFeeNumerator,
                                        uint80 _mintFeeDenominator,
                                        uint256 _mintFeeFlat,
                                        uint80 _burnFeeNumerator,
                                        uint80 _burnFeeDenominator,
                                        uint256 _burnFeeFlat) public onlyAdminOrOwner {
        uint deferBlock = computeDeferBlock();
        changeInsuranceFeesOperation = ChangeInsuranceFeesOperation(_transferFeeNumerator,
                                                                    _transferFeeDenominator,
                                                                    _mintFeeNumerator,
                                                                    _mintFeeDenominator,
                                                                    _mintFeeFlat,
                                                                    _burnFeeNumerator,
                                                                    _burnFeeDenominator,
                                                                    _burnFeeFlat,
                                                                    admin,
                                                                    deferBlock);
        ChangeInsuranceFeesOperationEvent(_transferFeeNumerator,
                                          _transferFeeDenominator,
                                          _mintFeeNumerator,
                                          _mintFeeDenominator,
                                          _mintFeeFlat,
                                          _burnFeeNumerator,
                                          _burnFeeDenominator,
                                          _burnFeeFlat,
                                          deferBlock);
    }

     
    function requestChangeInsurer(address newInsurer) public onlyAdminOrOwner {
        uint deferBlock = computeDeferBlock();
        changeInsurerOperation = ChangeInsurerOperation(newInsurer, admin, deferBlock);
        ChangeInsurerOperationEvent(newInsurer, deferBlock);
    }

     
     
    function finalizeMint(uint index) public onlyAdminOrOwner {
        MintOperation memory op = mintOperations[index];
        require(op.admin == admin);  
        require(op.deferBlock <= block.number);  
        address to = op.to;
        uint256 amount = op.amount;
        delete mintOperations[index];
        child.mint(to, amount);
    }

     
    function finalizeTransferChildrenOwnership() public onlyAdminOrOwner {
        require(transferOwnershipOperation.admin == admin);
        require(transferOwnershipOperation.deferBlock <= block.number);
        address newOwner = transferOwnershipOperation.newOwner;
        delete transferOwnershipOperation;
        child.transferOwnership(newOwner);
        canBurnWhiteList.transferOwnership(newOwner);
        canReceiveMintWhitelist.transferOwnership(newOwner);
        blackList.transferOwnership(newOwner);
    }

     
    function finalizeChangeBurnBounds() public onlyAdminOrOwner {
        require(changeBurnBoundsOperation.admin == admin);
        require(changeBurnBoundsOperation.deferBlock <= block.number);
        uint newMin = changeBurnBoundsOperation.newMin;
        uint newMax = changeBurnBoundsOperation.newMax;
        delete changeBurnBoundsOperation;
        child.changeBurnBounds(newMin, newMax);
    }

     
    function finalizeChangeInsuranceFees() public onlyAdminOrOwner {
        require(changeInsuranceFeesOperation.admin == admin);
        require(changeInsuranceFeesOperation.deferBlock <= block.number);
        uint80 _transferFeeNumerator = changeInsuranceFeesOperation._transferFeeNumerator;
        uint80 _transferFeeDenominator = changeInsuranceFeesOperation._transferFeeDenominator;
        uint80 _mintFeeNumerator = changeInsuranceFeesOperation._mintFeeNumerator;
        uint80 _mintFeeDenominator = changeInsuranceFeesOperation._mintFeeDenominator;
        uint256 _mintFeeFlat = changeInsuranceFeesOperation._mintFeeFlat;
        uint80 _burnFeeNumerator = changeInsuranceFeesOperation._burnFeeNumerator;
        uint80 _burnFeeDenominator = changeInsuranceFeesOperation._burnFeeDenominator;
        uint256 _burnFeeFlat = changeInsuranceFeesOperation._burnFeeFlat;
        delete changeInsuranceFeesOperation;
        child.changeInsuranceFees(_transferFeeNumerator,
                                  _transferFeeDenominator,
                                  _mintFeeNumerator,
                                  _mintFeeDenominator,
                                  _mintFeeFlat,
                                  _burnFeeNumerator,
                                  _burnFeeDenominator,
                                  _burnFeeFlat);
    }

     
    function finalizeChangeInsurer() public onlyAdminOrOwner {
        require(changeInsurerOperation.admin == admin);
        require(changeInsurerOperation.deferBlock <= block.number);
        address newInsurer = changeInsurerOperation.newInsurer;
        delete changeInsurerOperation;
        child.changeInsurer(newInsurer);
    }

     
    function transferAdminship(address newAdmin) public onlyOwner {
        AdminshipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

     
    function updateList(address list, address entry, bool flag) public onlyAdminOrOwner {
        AddressList(list).changeList(entry, flag);
    }

    function issueClaimOwnership(address _other) public onlyAdminOrOwner {
        Claimable other = Claimable(_other);
        other.claimOwnership();
    }
}

contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract TrueUSD is PausableToken, BurnableToken, NoOwner, Claimable {
    string public constant name = "TrueUSD";
    string public constant symbol = "TUSD";
    uint8 public constant decimals = 18;

    AddressList public canReceiveMintWhitelist;
    AddressList public canBurnWhiteList;
    AddressList public blackList;
    uint256 public burnMin = 10000 * 10**uint256(decimals);
    uint256 public burnMax = 20000000 * 10**uint256(decimals);

    uint80 public transferFeeNumerator = 7;
    uint80 public transferFeeDenominator = 10000;
    uint80 public mintFeeNumerator = 0;
    uint80 public mintFeeDenominator = 10000;
    uint256 public mintFeeFlat = 0;
    uint80 public burnFeeNumerator = 0;
    uint80 public burnFeeDenominator = 10000;
    uint256 public burnFeeFlat = 0;
    address public insurer;

    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);

    function TrueUSD(address _canMintWhiteList, address _canBurnWhiteList, address _blackList) public {
        totalSupply_ = 0;
        canReceiveMintWhitelist = AddressList(_canMintWhiteList);
        canBurnWhiteList = AddressList(_canBurnWhiteList);
        blackList = AddressList(_blackList);
        insurer = msg.sender;
    }

     
     
    function burn(uint256 _value) public {
        require(canBurnWhiteList.onList(msg.sender));
        require(_value >= burnMin);
        require(_value <= burnMax);
        uint256 fee = payInsuranceFee(msg.sender, _value, burnFeeNumerator, burnFeeDenominator, burnFeeFlat);
        uint256 remaining = _value.sub(fee);
        super.burn(remaining);
    }

     
     
    function mint(address _to, uint256 _amount) onlyOwner public {
        require(canReceiveMintWhitelist.onList(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        payInsuranceFee(_to, _amount, mintFeeNumerator, mintFeeDenominator, mintFeeFlat);
    }

     
     
     
     
     
     
    function changeBurnBounds(uint newMin, uint newMax) onlyOwner public {
        require(newMin <= newMax);
        burnMin = newMin;
        burnMax = newMax;
        ChangeBurnBoundsEvent(newMin, newMax);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(!blackList.onList(msg.sender));
        require(!blackList.onList(to));
        bool result = super.transfer(to, value);
        payInsuranceFee(to, value, transferFeeNumerator, transferFeeDenominator, 0);
        return result;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!blackList.onList(from));
        require(!blackList.onList(to));
        bool result = super.transferFrom(from, to, value);
        payInsuranceFee(to, value, transferFeeNumerator, transferFeeDenominator, 0);
        return result;
    }

    function payInsuranceFee(address payer, uint256 value, uint80 numerator, uint80 denominator, uint256 flatRate) private returns (uint256) {
        uint256 insuranceFee = value.mul(numerator).div(denominator).add(flatRate);
        if (insuranceFee > 0) {
            transferFromWithoutAllowance(payer, insurer, insuranceFee);
        }
        return insuranceFee;
    }

     
    function transferFromWithoutAllowance(address from, address _to, uint256 _value) private {
        assert(_to != address(0));
        assert(_value <= balances[from]);
        balances[from] = balances[from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(from, _to, _value);
    }

    function changeInsuranceFees(uint80 _transferFeeNumerator,
                                 uint80 _transferFeeDenominator,
                                 uint80 _mintFeeNumerator,
                                 uint80 _mintFeeDenominator,
                                 uint256 _mintFeeFlat,
                                 uint80 _burnFeeNumerator,
                                 uint80 _burnFeeDenominator,
                                 uint256 _burnFeeFlat) public onlyOwner {
        require(_transferFeeDenominator != 0);
        require(_mintFeeDenominator != 0);
        require(_burnFeeDenominator != 0);
        transferFeeNumerator = _transferFeeNumerator;
        transferFeeDenominator = _transferFeeDenominator;
        mintFeeNumerator = _mintFeeNumerator;
        mintFeeDenominator = _mintFeeDenominator;
        mintFeeFlat = _mintFeeFlat;
        burnFeeNumerator = _burnFeeNumerator;
        burnFeeDenominator = _burnFeeDenominator;
        burnFeeFlat = _burnFeeFlat;
    }

    function changeInsurer(address newInsurer) public onlyOwner {
        require(newInsurer != address(0));
        insurer = newInsurer;
    }
}