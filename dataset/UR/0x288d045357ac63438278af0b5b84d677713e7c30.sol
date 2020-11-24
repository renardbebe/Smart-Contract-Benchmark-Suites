 

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

 

 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}

 

 
contract Restricted is Ownable {

     
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

     
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

     
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

 

interface IMonethaVoucher {
     
    function totalInSharedPool() external view returns (uint256);

     
    function toWei(uint256 _value) external view returns (uint256);

     
    function fromWei(uint256 _value) external view returns (uint256);

     
    function applyDiscount(address _for, uint256 _vouchers) external returns (uint256 amountVouchers, uint256 amountWei);

     
    function applyPayback(address _for, uint256 _amountWei) external returns (uint256 amountVouchers);

     
    function buyVouchers(uint256 _vouchers) external payable;

     
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

     
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

     
    function purchasedBy(address owner) external view returns (uint256);
}

 

 
contract GenericERC20 {
    function totalSupply() public view returns (uint256);

    function decimals() public view returns(uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);
        
     
    function transfer(address _to, uint256 _value) public;

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

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

 

 
contract MonethaGateway is Pausable, Contactable, Destructible, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.6";

     
    uint public constant FEE_PERMILLE = 15;


    uint public constant PERMILLE_COEFFICIENT = 1000;

     
    address public monethaVault;

     
    address public admin;

     
    IMonethaVoucher public monethaVoucher;

     
    uint public MaxDiscountPermille;

    event PaymentProcessedEther(address merchantWallet, uint merchantIncome, uint monethaIncome);
    event PaymentProcessedToken(address tokenAddress, address merchantWallet, uint merchantIncome, uint monethaIncome);
    event MonethaVoucherChanged(
        address indexed previousMonethaVoucher,
        address indexed newMonethaVoucher
    );
    event MaxDiscountPermilleChanged(uint prevPermilleValue, uint newPermilleValue);

     
    constructor(address _monethaVault, address _admin, IMonethaVoucher _monethaVoucher) public {
        require(_monethaVault != 0x0);
        monethaVault = _monethaVault;

        setAdmin(_admin);
        setMonethaVoucher(_monethaVoucher);
        setMaxDiscountPermille(700);  
    }

     
     
    function acceptPayment(address _merchantWallet,
        uint _monethaFee,
        address _customerAddress,
        uint _vouchersApply,
        uint _paybackPermille)
    external payable onlyMonetha whenNotPaused returns (uint discountWei){
        require(_merchantWallet != 0x0);
        uint price = msg.value;
         
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(price).div(1000));

        discountWei = 0;
        if (monethaVoucher != address(0)) {
            if (_vouchersApply > 0 && MaxDiscountPermille > 0) {
                uint maxDiscountWei = price.mul(MaxDiscountPermille).div(PERMILLE_COEFFICIENT);
                uint maxVouchers = monethaVoucher.fromWei(maxDiscountWei);
                 
                uint vouchersApply = _vouchersApply;
                if (vouchersApply > maxVouchers) {
                    vouchersApply = maxVouchers;
                }

                (, discountWei) = monethaVoucher.applyDiscount(_customerAddress, vouchersApply);
            }

            if (_paybackPermille > 0) {
                uint paybackWei = price.sub(discountWei).mul(_paybackPermille).div(PERMILLE_COEFFICIENT);
                if (paybackWei > 0) {
                    monethaVoucher.applyPayback(_customerAddress, paybackWei);
                }
            }
        }

        uint merchantIncome = price.sub(_monethaFee);

        _merchantWallet.transfer(merchantIncome);
        monethaVault.transfer(_monethaFee);

        emit PaymentProcessedEther(_merchantWallet, merchantIncome, _monethaFee);
    }

     
    function acceptTokenPayment(
        address _merchantWallet,
        uint _monethaFee,
        address _tokenAddress,
        uint _value
    )
    external onlyMonetha whenNotPaused
    {
        require(_merchantWallet != 0x0);

         
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(_value).div(1000));

        uint merchantIncome = _value.sub(_monethaFee);

        GenericERC20(_tokenAddress).transfer(_merchantWallet, merchantIncome);
        GenericERC20(_tokenAddress).transfer(monethaVault, _monethaFee);

        emit PaymentProcessedToken(_tokenAddress, _merchantWallet, merchantIncome, _monethaFee);
    }

     
    function changeMonethaVault(address newVault) external onlyOwner whenNotPaused {
        monethaVault = newVault;
    }

     
    function setMonethaAddress(address _address, bool _isMonethaAddress) public {
        require(msg.sender == admin || msg.sender == owner);

        isMonethaAddress[_address] = _isMonethaAddress;

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }

     
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0));
        admin = _admin;
    }

     
    function setMonethaVoucher(IMonethaVoucher _monethaVoucher) public onlyOwner {
        if (monethaVoucher != _monethaVoucher) {
            emit MonethaVoucherChanged(monethaVoucher, _monethaVoucher);
            monethaVoucher = _monethaVoucher;
        }
    }

     
    function setMaxDiscountPermille(uint _maxDiscountPermille) public onlyOwner {
        require(_maxDiscountPermille <= PERMILLE_COEFFICIENT);
        emit MaxDiscountPermilleChanged(MaxDiscountPermille, _maxDiscountPermille);
        MaxDiscountPermille = _maxDiscountPermille;
    }
}

 

 
contract SafeDestructible is Ownable {
    function destroy() onlyOwner public {
        require(address(this).balance == 0);
        selfdestruct(owner);
    }
}

 

 

contract MerchantWallet is Pausable, SafeDestructible, Contactable, Restricted {

    string constant VERSION = "0.5";

     
    address public merchantAccount;

     
    address public merchantFundAddress;

     
    bytes32 public merchantIdHash;

     
    mapping (string=>string) profileMap;

     
    mapping (string=>string) paymentSettingsMap;

     
    mapping (string=>uint32) compositeReputationMap;

     
    uint8 public constant REPUTATION_DECIMALS = 4;

     
    modifier onlyMerchant() {
        require(msg.sender == merchantAccount);
        _;
    }

     
    modifier isEOA(address _fundAddress) {
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_fundAddress)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier onlyMerchantOrMonetha() {
        require(msg.sender == merchantAccount || isMonethaAddress[msg.sender]);
        _;
    }

     
    constructor(address _merchantAccount, string _merchantId, address _fundAddress) public isEOA(_fundAddress) {
        require(_merchantAccount != 0x0);
        require(bytes(_merchantId).length > 0);

        merchantAccount = _merchantAccount;
        merchantIdHash = keccak256(abi.encodePacked(_merchantId));

        merchantFundAddress = _fundAddress;
    }

     
    function () external payable {
    }

     
    function profile(string key) external constant returns (string) {
        return profileMap[key];
    }

     
    function paymentSettings(string key) external constant returns (string) {
        return paymentSettingsMap[key];
    }

     
    function compositeReputation(string key) external constant returns (uint32) {
        return compositeReputationMap[key];
    }

     
    function setProfile(
        string profileKey,
        string profileValue,
        string repKey,
        uint32 repValue
    )
        external onlyOwner
    {
        profileMap[profileKey] = profileValue;

        if (bytes(repKey).length != 0) {
            compositeReputationMap[repKey] = repValue;
        }
    }

     
    function setPaymentSettings(string key, string value) external onlyOwner {
        paymentSettingsMap[key] = value;
    }

     
    function setCompositeReputation(string key, uint32 value) external onlyMonetha {
        compositeReputationMap[key] = value;
    }

     
    function doWithdrawal(address beneficiary, uint amount) private {
        require(beneficiary != 0x0);
        beneficiary.transfer(amount);
    }

     
    function withdrawTo(address beneficiary, uint amount) public onlyMerchant whenNotPaused {
        doWithdrawal(beneficiary, amount);
    }

     
    function withdraw(uint amount) external onlyMerchant {
        withdrawTo(msg.sender, amount);
    }

     
    function withdrawToExchange(address depositAccount, uint amount) external onlyMerchantOrMonetha whenNotPaused {
        doWithdrawal(depositAccount, amount);
    }

     
    function withdrawAllToExchange(address depositAccount, uint min_amount) external onlyMerchantOrMonetha whenNotPaused {
        require (address(this).balance >= min_amount);
        doWithdrawal(depositAccount, address(this).balance);
    }

     
    function withdrawAllTokensToExchange(address _tokenAddress, address _depositAccount, uint _minAmount) external onlyMerchantOrMonetha whenNotPaused {
        require(_tokenAddress != address(0));
        
        uint balance = GenericERC20(_tokenAddress).balanceOf(address(this));
        
        require(balance >= _minAmount);
        
        GenericERC20(_tokenAddress).transfer(_depositAccount, balance);
    }

     
    function changeMerchantAccount(address newAccount) external onlyMerchant whenNotPaused {
        merchantAccount = newAccount;
    }

     
    function changeFundAddress(address newFundAddress) external onlyMerchant isEOA(newFundAddress) {
        merchantFundAddress = newFundAddress;
    }
}

 

contract PrivatePaymentProcessor is Pausable, Destructible, Contactable, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.6";

     
    uint public constant PAYBACK_PERMILLE = 2;  

     
    event OrderPaidInEther(
        uint indexed _orderId,
        address indexed _originAddress,
        uint _price,
        uint _monethaFee,
        uint _discount
    );

    event OrderPaidInToken(
        uint indexed _orderId,
        address indexed _originAddress,
        address indexed _tokenAddress,
        uint _price,
        uint _monethaFee
    );

     
    event PaymentsProcessed(
        address indexed _merchantAddress,
        uint _amount,
        uint _fee
    );

     
    event PaymentRefunding(
        uint indexed _orderId,
        address indexed _clientAddress,
        uint _amount,
        string _refundReason
    );

     
    event PaymentWithdrawn(
        uint indexed _orderId,
        address indexed _clientAddress,
        uint amount
    );

     
    MonethaGateway public monethaGateway;

     
    MerchantWallet public merchantWallet;

     
    bytes32 public merchantIdHash;

    enum WithdrawState {Null, Pending, Withdrawn}

    struct Withdraw {
        WithdrawState state;
        uint amount;
        address clientAddress;
        address tokenAddress;
    }

    mapping(uint => Withdraw) public withdrawals;

     
    constructor(
        string _merchantId,
        MonethaGateway _monethaGateway,
        MerchantWallet _merchantWallet
    )
    public
    {
        require(bytes(_merchantId).length > 0);

        merchantIdHash = keccak256(abi.encodePacked(_merchantId));

        setMonethaGateway(_monethaGateway);
        setMerchantWallet(_merchantWallet);
    }

     
    function payForOrder(
        uint _orderId,
        address _originAddress,
        uint _monethaFee,
        uint _vouchersApply
    )
    external payable whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(msg.value > 0);

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        uint discountWei = 0;
        if (fundAddress != address(0)) {
            discountWei = monethaGateway.acceptPayment.value(msg.value)(
                fundAddress,
                _monethaFee,
                _originAddress,
                _vouchersApply,
                PAYBACK_PERMILLE);
        } else {
            discountWei = monethaGateway.acceptPayment.value(msg.value)(
                merchantWallet,
                _monethaFee,
                _originAddress,
                _vouchersApply,
                PAYBACK_PERMILLE);
        }

         
        emit OrderPaidInEther(_orderId, _originAddress, msg.value, _monethaFee, discountWei);
    }

     
    function payForOrderInTokens(
        uint _orderId,
        address _originAddress,
        uint _monethaFee,
        address _tokenAddress,
        uint _orderValue
    )
    external whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        GenericERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);

        GenericERC20(_tokenAddress).transfer(address(monethaGateway), _orderValue);

        if (fundAddress != address(0)) {
            monethaGateway.acceptTokenPayment(fundAddress, _monethaFee, _tokenAddress, _orderValue);
        } else {
            monethaGateway.acceptTokenPayment(merchantWallet, _monethaFee, _tokenAddress, _orderValue);
        }

         
        emit OrderPaidInToken(_orderId, _originAddress, _tokenAddress, _orderValue, _monethaFee);
    }

     
    function refundPayment(
        uint _orderId,
        address _clientAddress,
        string _refundReason
    )
    external payable onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(msg.value > 0);
        require(WithdrawState.Null == withdrawals[_orderId].state);

         
        withdrawals[_orderId] = Withdraw({
            state : WithdrawState.Pending,
            amount : msg.value,
            clientAddress : _clientAddress,
            tokenAddress: address(0)
            });

         
        emit PaymentRefunding(_orderId, _clientAddress, msg.value, _refundReason);
    }

     
    function refundTokenPayment(
        uint _orderId,
        address _clientAddress,
        string _refundReason,
        uint _orderValue,
        address _tokenAddress
    )
    external onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));
        require(WithdrawState.Null == withdrawals[_orderId].state);

        GenericERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);

         
        withdrawals[_orderId] = Withdraw({
            state : WithdrawState.Pending,
            amount : _orderValue,
            clientAddress : _clientAddress,
            tokenAddress : _tokenAddress
            });

         
        emit PaymentRefunding(_orderId, _clientAddress, _orderValue, _refundReason);
    }

     
    function withdrawRefund(uint _orderId)
    external whenNotPaused
    {
        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);
        require(withdraw.tokenAddress == address(0));

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

         
        withdraw.state = WithdrawState.Withdrawn;

         
        clientAddress.transfer(amount);

         
        emit PaymentWithdrawn(_orderId, clientAddress, amount);
    }

     
    function withdrawTokenRefund(uint _orderId, address _tokenAddress)
    external whenNotPaused
    {
        require(_tokenAddress != address(0));

        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);
        require(withdraw.tokenAddress == _tokenAddress);

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

         
        withdraw.state = WithdrawState.Withdrawn;

         
        GenericERC20(_tokenAddress).transfer(clientAddress, amount);

         
        emit PaymentWithdrawn(_orderId, clientAddress, amount);
    }

     
    function setMonethaGateway(MonethaGateway _newGateway) public onlyOwner {
        require(address(_newGateway) != 0x0);

        monethaGateway = _newGateway;
    }

     
    function setMerchantWallet(MerchantWallet _newWallet) public onlyOwner {
        require(address(_newWallet) != 0x0);
        require(_newWallet.merchantIdHash() == merchantIdHash);

        merchantWallet = _newWallet;
    }
}