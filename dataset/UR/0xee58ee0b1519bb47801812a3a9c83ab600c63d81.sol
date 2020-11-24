 

pragma solidity ^0.4.18;

 

 
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 

 
contract Destructible is Ownable {

    function Destructible() public payable { }

     
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
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
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 

 
contract Contactable is Ownable {

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
        contactInformation = info;
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

        MonethaAddressSet(_address, _isMonethaAddress);
    }
}

 


 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function decimals() public view returns(uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

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
    
    string constant VERSION = "0.4";

     
    uint public constant FEE_PERMILLE = 15;
    
     
    address public monethaVault;

     
    address public admin;

    event PaymentProcessedEther(address merchantWallet, uint merchantIncome, uint monethaIncome);
    event PaymentProcessedToken(address tokenAddress, address merchantWallet, uint merchantIncome, uint monethaIncome);

     
    function MonethaGateway(address _monethaVault, address _admin) public {
        require(_monethaVault != 0x0);
        monethaVault = _monethaVault;
        
        setAdmin(_admin);
    }
    
     
    function acceptPayment(address _merchantWallet, uint _monethaFee) external payable onlyMonetha whenNotPaused {
        require(_merchantWallet != 0x0);
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(msg.value).div(1000));  
        
        uint merchantIncome = msg.value.sub(_monethaFee);

        _merchantWallet.transfer(merchantIncome);
        monethaVault.transfer(_monethaFee);

        PaymentProcessedEther(_merchantWallet, merchantIncome, _monethaFee);
    }

    function acceptTokenPayment(address _merchantWallet, uint _monethaFee, address _tokenAddress, uint _value) external onlyMonetha whenNotPaused {
        require(_merchantWallet != 0x0);

         
        require(_monethaFee >= 0 && _monethaFee <= FEE_PERMILLE.mul(_value).div(1000));

        uint merchantIncome = _value.sub(_monethaFee);
        
        ERC20(_tokenAddress).transfer(_merchantWallet, merchantIncome);
        ERC20(_tokenAddress).transfer(monethaVault, _monethaFee);
        
        PaymentProcessedToken(_tokenAddress, _merchantWallet, merchantIncome, _monethaFee);
    }

     
    function changeMonethaVault(address newVault) external onlyOwner whenNotPaused {
        monethaVault = newVault;
    }

     
    function setMonethaAddress(address _address, bool _isMonethaAddress) public {
        require(msg.sender == admin || msg.sender == owner);

        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }

     
    function setAdmin(address _admin) public onlyOwner {
        require(_admin != 0x0);
        admin = _admin;
    }
}

 

 
contract SafeDestructible is Ownable {
    function destroy() onlyOwner public {
        require(this.balance == 0);
        selfdestruct(owner);
    }
}

 

 

contract MerchantWallet is Pausable, SafeDestructible, Contactable, Restricted {

    string constant VERSION = "0.4";

     
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

     
    function MerchantWallet(address _merchantAccount, string _merchantId, address _fundAddress) public isEOA(_fundAddress) {
        require(_merchantAccount != 0x0);
        require(bytes(_merchantId).length > 0);

        merchantAccount = _merchantAccount;
        merchantIdHash = keccak256(_merchantId);

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
    ) external onlyOwner
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

     
    function changeMerchantAccount(address newAccount) external onlyMerchant whenNotPaused {
        merchantAccount = newAccount;
    }

     
    function changeFundAddress(address newFundAddress) external onlyMerchant isEOA(newFundAddress) {
        merchantFundAddress = newFundAddress;
    }
}

 

contract PrivatePaymentProcessor is Pausable, Destructible, Contactable, Restricted {

    using SafeMath for uint256;

    string constant VERSION = "0.4";

     
    event OrderPaidInEther(
        uint indexed _orderId,
        address indexed _originAddress,
        uint _price,
        uint _monethaFee
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
    }

    mapping (uint=>Withdraw) public withdrawals;

     
    function PrivatePaymentProcessor(
        string _merchantId,
        MonethaGateway _monethaGateway,
        MerchantWallet _merchantWallet
    ) public
    {
        require(bytes(_merchantId).length > 0);

        merchantIdHash = keccak256(_merchantId);

        setMonethaGateway(_monethaGateway);
        setMerchantWallet(_merchantWallet);
    }

     
    function payForOrder(
        uint _orderId,
        address _originAddress,
        uint _monethaFee
    ) external payable whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(msg.value > 0);

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        if (fundAddress != address(0)) {
            monethaGateway.acceptPayment.value(msg.value)(fundAddress, _monethaFee);
        } else {
            monethaGateway.acceptPayment.value(msg.value)(merchantWallet, _monethaFee);
        }

         
        emit OrderPaidInEther(_orderId, _originAddress, msg.value, _monethaFee);
    }

     
    function payForOrderInTokens(
        uint _orderId,
        address _originAddress,
        uint _monethaFee,
        address _tokenAddress,
        uint _orderValue
    ) external whenNotPaused
    {
        require(_orderId > 0);
        require(_originAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));

        address fundAddress;
        fundAddress = merchantWallet.merchantFundAddress();

        ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);
        
        ERC20(_tokenAddress).transfer(address(monethaGateway), _orderValue);

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
    ) external payable onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(msg.value > 0);
        require(WithdrawState.Null == withdrawals[_orderId].state);

         
        withdrawals[_orderId] = Withdraw({
            state: WithdrawState.Pending,
            amount: msg.value,
            clientAddress: _clientAddress
            });

         
        PaymentRefunding(_orderId, _clientAddress, msg.value, _refundReason);
    }

     
    function refundTokenPayment(
        uint _orderId,
        address _clientAddress,
        string _refundReason,
        uint _orderValue,
        address _tokenAddress
    ) external onlyMonetha whenNotPaused
    {
        require(_orderId > 0);
        require(_clientAddress != 0x0);
        require(_orderValue > 0);
        require(_tokenAddress != address(0));
        require(WithdrawState.Null == withdrawals[_orderId].state);

        ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _orderValue);
        
         
        withdrawals[_orderId] = Withdraw({
            state: WithdrawState.Pending,
            amount: _orderValue,
            clientAddress: _clientAddress
            });

         
        PaymentRefunding(_orderId, _clientAddress, _orderValue, _refundReason);
    }

     
    function withdrawRefund(uint _orderId)
    external whenNotPaused
    {
        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

         
        withdraw.state = WithdrawState.Withdrawn;

         
        clientAddress.transfer(amount);

         
        PaymentWithdrawn(_orderId, clientAddress, amount);
    }

     
    function withdrawTokenRefund(uint _orderId, address _tokenAddress)
    external whenNotPaused
    {
        require(_tokenAddress != address(0));

        Withdraw storage withdraw = withdrawals[_orderId];
        require(WithdrawState.Pending == withdraw.state);

        address clientAddress = withdraw.clientAddress;
        uint amount = withdraw.amount;

         
        withdraw.state = WithdrawState.Withdrawn;

         
        ERC20(_tokenAddress).transfer(clientAddress, amount);

         
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