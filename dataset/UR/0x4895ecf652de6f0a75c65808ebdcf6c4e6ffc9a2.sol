 

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

 

 
contract MerchantDealsHistory is Contactable, Restricted {

    string constant VERSION = "0.3";

     
    bytes32 public merchantIdHash;
    
     
    event DealCompleted(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        bool successful,
        uint dealHash
    );

     
    event DealCancelationReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string cancelReason
    );

     
    event DealRefundReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string refundReason
    );

     
    constructor(string _merchantId) public {
        require(bytes(_merchantId).length > 0);
        merchantIdHash = keccak256(abi.encodePacked(_merchantId));
    }

     
    function recordDeal(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        bool _isSuccess,
        uint _dealHash)
        external onlyMonetha
    {
        emit DealCompleted(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _isSuccess,
            _dealHash
        );
    }

     
    function recordDealCancelReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _cancelReason)
        external onlyMonetha
    {
        emit DealCancelationReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _cancelReason
        );
    }

 
    function recordDealRefundReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _refundReason)
        external onlyMonetha
    {
        emit DealRefundReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _refundReason
        );
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

 

 


contract PaymentProcessor is Pausable, Destructible, Contactable, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.7";

     
    uint public constant FEE_PERMILLE = 15;

     
    uint public constant PAYBACK_PERMILLE = 2;  

    uint public constant PERMILLE_COEFFICIENT = 1000;

     
    MonethaGateway public monethaGateway;

     
    MerchantDealsHistory public merchantHistory;

     
    MerchantWallet public merchantWallet;

     
    bytes32 public merchantIdHash;

    enum State {Null, Created, Paid, Finalized, Refunding, Refunded, Cancelled}

    struct Order {
        State state;
        uint price;
        uint fee;
        address paymentAcceptor;
        address originAddress;
        address tokenAddress;
        uint vouchersApply;
        uint discount;
    }

    mapping(uint => Order) public orders;

     
    modifier atState(uint _orderId, State _state) {
        require(_state == orders[_orderId].state);
        _;
    }

     
    modifier transition(uint _orderId, State _state) {
        _;
        orders[_orderId].state = _state;
    }

     
    constructor(
        string _merchantId,
        MerchantDealsHistory _merchantHistory,
        MonethaGateway _monethaGateway,
        MerchantWallet _merchantWallet
    )
    public
    {
        require(bytes(_merchantId).length > 0);

        merchantIdHash = keccak256(abi.encodePacked(_merchantId));

        setMonethaGateway(_monethaGateway);
        setMerchantWallet(_merchantWallet);
        setMerchantDealsHistory(_merchantHistory);
    }

     
    function addOrder(
        uint _orderId,
        uint _price,
        address _paymentAcceptor,
        address _originAddress,
        uint _fee,
        address _tokenAddress,
        uint _vouchersApply
    ) external whenNotPaused atState(_orderId, State.Null)
    {
        require(_orderId > 0);
        require(_price > 0);
        require(_fee >= 0 && _fee <= FEE_PERMILLE.mul(_price).div(PERMILLE_COEFFICIENT));
         
        require(_paymentAcceptor != address(0));
        require(_originAddress != address(0));
        require(orders[_orderId].price == 0 && orders[_orderId].fee == 0);

        orders[_orderId] = Order({
            state : State.Created,
            price : _price,
            fee : _fee,
            paymentAcceptor : _paymentAcceptor,
            originAddress : _originAddress,
            tokenAddress : _tokenAddress,
            vouchersApply : _vouchersApply,
            discount: 0
            });
    }

     
    function securePay(uint _orderId)
    external payable whenNotPaused
    atState(_orderId, State.Created) transition(_orderId, State.Paid)
    {
        Order storage order = orders[_orderId];

        require(order.tokenAddress == address(0));
        require(msg.sender == order.paymentAcceptor);
        require(msg.value == order.price);
    }

     
    function secureTokenPay(uint _orderId)
    external whenNotPaused
    atState(_orderId, State.Created) transition(_orderId, State.Paid)
    {
        Order storage order = orders[_orderId];

        require(msg.sender == order.paymentAcceptor);
        require(order.tokenAddress != address(0));

        GenericERC20(order.tokenAddress).transferFrom(msg.sender, address(this), order.price);
    }

     
    function cancelOrder(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _cancelReason
    )
    external onlyMonetha whenNotPaused
    atState(_orderId, State.Created) transition(_orderId, State.Cancelled)
    {
        require(bytes(_cancelReason).length > 0);

        Order storage order = orders[_orderId];

        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            false,
            _dealHash
        );

        merchantHistory.recordDealCancelReason(
            _orderId,
            order.originAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _cancelReason
        );
    }

     
    function refundPayment(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _refundReason
    )
    external onlyMonetha whenNotPaused
    atState(_orderId, State.Paid) transition(_orderId, State.Refunding)
    {
        require(bytes(_refundReason).length > 0);

        Order storage order = orders[_orderId];

        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            false,
            _dealHash
        );

        merchantHistory.recordDealRefundReason(
            _orderId,
            order.originAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _refundReason
        );
    }

     
    function withdrawRefund(uint _orderId)
    external whenNotPaused
    atState(_orderId, State.Refunding) transition(_orderId, State.Refunded)
    {
        Order storage order = orders[_orderId];
        require(order.tokenAddress == address(0));

        order.originAddress.transfer(order.price.sub(order.discount));
    }

     
    function withdrawTokenRefund(uint _orderId)
    external whenNotPaused
    atState(_orderId, State.Refunding) transition(_orderId, State.Refunded)
    {
        require(orders[_orderId].tokenAddress != address(0));

        GenericERC20(orders[_orderId].tokenAddress).transfer(orders[_orderId].originAddress, orders[_orderId].price);
    }

     
    function processPayment(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash
    )
    external onlyMonetha whenNotPaused
    atState(_orderId, State.Paid) transition(_orderId, State.Finalized)
    {
        Order storage order = orders[_orderId];
        address fundAddress = merchantWallet.merchantFundAddress();

        if (order.tokenAddress != address(0)) {
            if (fundAddress != address(0)) {
                GenericERC20(order.tokenAddress).transfer(address(monethaGateway), order.price);
                monethaGateway.acceptTokenPayment(fundAddress, order.fee, order.tokenAddress, order.price);
            } else {
                GenericERC20(order.tokenAddress).transfer(address(monethaGateway), order.price);
                monethaGateway.acceptTokenPayment(merchantWallet, order.fee, order.tokenAddress, order.price);
            }
        } else {
            uint discountWei = 0;
            if (fundAddress != address(0)) {
                discountWei = monethaGateway.acceptPayment.value(order.price)(
                    fundAddress,
                    order.fee,
                    order.originAddress,
                    order.vouchersApply,
                    PAYBACK_PERMILLE);
            } else {
                discountWei = monethaGateway.acceptPayment.value(order.price)(
                    merchantWallet,
                    order.fee,
                    order.originAddress,
                    order.vouchersApply,
                    PAYBACK_PERMILLE);
            }

            if (discountWei > 0) {
                order.discount = discountWei;
            }
        }

        updateDealConditions(
            _orderId,
            _clientReputation,
            _merchantReputation,
            true,
            _dealHash
        );
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

     
    function setMerchantDealsHistory(MerchantDealsHistory _merchantHistory) public onlyOwner {
        require(address(_merchantHistory) != 0x0);
        require(_merchantHistory.merchantIdHash() == merchantIdHash);

        merchantHistory = _merchantHistory;
    }

     
    function updateDealConditions(
        uint _orderId,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        bool _isSuccess,
        uint _dealHash
    )
    internal
    {
        merchantHistory.recordDeal(
            _orderId,
            orders[_orderId].originAddress,
            _clientReputation,
            _merchantReputation,
            _isSuccess,
            _dealHash
        );

         
        merchantWallet.setCompositeReputation("total", _merchantReputation);
    }
}