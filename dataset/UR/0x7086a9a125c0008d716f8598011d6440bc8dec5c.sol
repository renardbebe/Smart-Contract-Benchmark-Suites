 

pragma solidity 0.5.9;

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract ERC677Receiver {
     
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool success);
}

 
contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

 
contract Token {

    using SafeMath for uint256;

     

    string public name;

    string public symbol;

    uint8 public constant decimals = 0;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

     
    address public creator;

     
    constructor() public {
         
        creator = msg.sender;
    }

     
    function initToken(
        string calldata _name,
        string calldata _symbol,
        uint256 _totalSupply,
        address tokenOwner
    ) external {

         
        require(msg.sender == creator, "Only creator can initialize token contract");

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[tokenOwner] = totalSupply;

        emit Transfer(address(0), tokenOwner, totalSupply);

    }

     

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed spender, uint256 value);

     

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes indexed _extraData);

     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
         
         

        require(_to != address(0), "_to was 0x0 address");

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender], "Sender not authorized");

         
        require(_value <= balanceOf[_from], "Account doesn't have required amount");

         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, _to, _value);

        return true;
    }  

    function transfer(address _to, uint256 _value) public returns (bool success){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transfer(address _to, uint _value, bytes calldata _data) external returns (bool success){
        if (transfer(_to, _value)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit DataSentToAnotherContract(msg.sender, _to, _data);
            return true;
        }
        return false;
    }

     
    function transferAndCall(address _to, uint256 _value, bytes memory _extraData) public returns (bool success){
        if (transferFrom(msg.sender, _to, _value)) {
            ERC677Receiver receiver = ERC677Receiver(_to);
            if (receiver.onTokenTransfer(msg.sender, _value, _extraData)) {
                emit DataSentToAnotherContract(msg.sender, _to, _extraData);
                return true;
            }
        }
        return false;
    }

     
    function transferAllAndCall(address _to, bytes calldata _extraData) external returns (bool){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _currentValue, uint256 _value) external returns (bool success){
        require(
            allowance[msg.sender][_spender] == _currentValue,
            "Current value in contract is different than provided current value"
        );
        return approve(_spender, _value);
    }

}

 
contract BurnableToken is Token {

     
    event TokensBurned(address indexed from, uint256 value, address by);

     
    function burnTokensFrom(address _from, uint256 _value) public returns (bool success){

        require(msg.sender == _from || _value <= allowance[_from][msg.sender], "Sender not authorized");
        require(_value <= balanceOf[_from], "Account doesn't have required amount");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

         
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, address(0), _value);
        emit TokensBurned(_from, _value, msg.sender);

        return true;
    }

    function burnTokens(uint256 _value) external returns (bool success){
        return burnTokensFrom(msg.sender, _value);
    }

}

 
contract CryptonomicaVerification {

     
    function revokedOn(address _address) external view returns (uint unixTime);

     
    function keyCertificateValidUntil(address _address) external view returns (uint unixTime);
}

 
contract ManagedContract {

     
    CryptonomicaVerification public cryptonomicaVerification;

     
    mapping(address => bool) isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can do that");
        _;
    }

     
    event CryptonomicaVerificationContractAddressChanged(address from, address to, address indexed by);

     
    function changeCryptonomicaVerificationContractAddress(address _newAddress) public onlyAdmin returns (bool success) {

        emit CryptonomicaVerificationContractAddressChanged(address(cryptonomicaVerification), _newAddress, msg.sender);

        cryptonomicaVerification = CryptonomicaVerification(_newAddress);

        return true;
    }

     
    event AdminAdded(
        address indexed added,
        address indexed addedBy
    );

     
    function addAdmin(address _newAdmin) public onlyAdmin returns (bool success){

        require(
            cryptonomicaVerification.keyCertificateValidUntil(_newAdmin) > now,
            "New admin has to be verified on Cryptonomica.net"
        );

         
        require(
            cryptonomicaVerification.revokedOn(_newAdmin) == 0,
            "Verification for this address was revoked, can not add"
        );

        isAdmin[_newAdmin] = true;

        emit AdminAdded(_newAdmin, msg.sender);

        return true;
    }

     
    event AdminRemoved(
        address indexed removed,
        address indexed removedBy
    );

     
    function removeAdmin(address _oldAdmin) external onlyAdmin returns (bool){

        require(msg.sender != _oldAdmin, "Admin can not remove himself");

        isAdmin[_oldAdmin] = false;

        emit AdminRemoved(_oldAdmin, msg.sender);

        return true;
    }

     

     
    address payable public withdrawalAddress;

     
    bool public withdrawalAddressFixed = false;

     
    event WithdrawalAddressChanged(address indexed from, address indexed to, address indexed changedBy);

     
    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyAdmin returns (bool success) {

        require(!withdrawalAddressFixed, "Withdrawal address already fixed");
        require(_withdrawalAddress != address(0), "Wrong address: 0x0");
        require(_withdrawalAddress != address(this), "Wrong address: contract itself");

        emit WithdrawalAddressChanged(withdrawalAddress, _withdrawalAddress, msg.sender);

        withdrawalAddress = _withdrawalAddress;

        return true;
    }

     
    event WithdrawalAddressFixed(address indexed withdrawalAddressFixedAs, address indexed fixedBy);

     
    function fixWithdrawalAddress(address _withdrawalAddress) external onlyAdmin returns (bool success) {

         
        require(!withdrawalAddressFixed, "Can't change, address fixed");

         
        require(withdrawalAddress == _withdrawalAddress, "Wrong address in argument");

        withdrawalAddressFixed = true;

        emit WithdrawalAddressFixed(withdrawalAddress, msg.sender);

        return true;
    }

     
    event Withdrawal(
        address indexed to,
        uint sumInWei,
        address indexed by,
        bool indexed success
    );

     
    function withdrawAllToWithdrawalAddress() external returns (bool success) {

         
         
         
         

        uint sum = address(this).balance;

        if (!withdrawalAddress.send(sum)) { 

            emit Withdrawal(withdrawalAddress, sum, msg.sender, false);

            return false;
        }

        emit Withdrawal(withdrawalAddress, sum, msg.sender, true);

        return true;
    }

}

 
contract ManagedContractWithPaidService is ManagedContract {

    uint256 public price;

     
    event PriceChanged(uint256 from, uint256 to, address indexed by);

     
    function changePrice(uint256 _newPrice) public onlyAdmin returns (bool success){
        emit PriceChanged(price, _newPrice, msg.sender);
        price = _newPrice;
        return true;
    }

}

 
contract BillsOfExchange is BurnableToken {

     

     
    uint256 public billsOfExchangeContractNumber;

     
    string public drawerName;

     
    address public drawerRepresentedBy;

     
    string public linkToSignersAuthorityToRepresentTheDrawer;

     
    string public drawee;

     
    address public draweeSignerAddress;

     
    string  public linkToSignersAuthorityToRepresentTheDrawee;

     
    string public description;
    string public order;
    string public disputeResolutionAgreement;
    CryptonomicaVerification public cryptonomicaVerification;

     
    string public timeOfPayment;

     
    uint256 public issuedOnUnixTime;
    string public placeWhereTheBillIsIssued;  

     
     
    string public placeWherePaymentIsToBeMade;

     
     
    string public currency;  

    uint256 public sumToBePaidForEveryToken;  

     
    uint256 public disputeResolutionAgreementSignaturesCounter;

     
    struct Signature {
        address signatoryAddress;
        string signatoryName;
    }

    mapping(uint256 => Signature) public disputeResolutionAgreementSignatures;

     
    event disputeResolutionAgreementSigned(
        uint256 indexed signatureNumber,
        string signedBy,
        address indexed representedBy,
        uint256 signedOn
    );

     
    function signDisputeResolutionAgreementFor(
        address _signatoryAddress,
        string memory _signatoryName
    ) public returns (bool success){

        require(
            msg.sender == _signatoryAddress ||
            msg.sender == creator,
            "Not authorized to sign dispute resolution agreement"
        );

         

        require(
            cryptonomicaVerification.keyCertificateValidUntil(_signatoryAddress) > now,
            "Signer has to be verified on Cryptonomica.net"
        );

         
        require(
            cryptonomicaVerification.revokedOn(_signatoryAddress) == 0,
            "Verification for this address was revoked, can not sign"
        );

        disputeResolutionAgreementSignaturesCounter++;

        disputeResolutionAgreementSignatures[disputeResolutionAgreementSignaturesCounter].signatoryAddress = _signatoryAddress;
        disputeResolutionAgreementSignatures[disputeResolutionAgreementSignaturesCounter].signatoryName = _signatoryName;

        emit disputeResolutionAgreementSigned(disputeResolutionAgreementSignaturesCounter, _signatoryName, msg.sender, now);

        return true;
    }

    function signDisputeResolutionAgreement(string calldata _signatoryName) external returns (bool success){
        return signDisputeResolutionAgreementFor(msg.sender, _signatoryName);
    }

     
    function initBillsOfExchange(
        uint256 _billsOfExchangeContractNumber,
        string calldata _currency,
        uint256 _sumToBePaidForEveryToken,
        string calldata _drawerName,
        address _drawerRepresentedBy,
        string calldata _linkToSignersAuthorityToRepresentTheDrawer,
        string calldata _drawee,
        address _draweeSignerAddress
    ) external {

        require(msg.sender == creator, "Only contract creator can call 'initBillsOfExchange' function");

        billsOfExchangeContractNumber = _billsOfExchangeContractNumber;

         
         
        currency = _currency;

        sumToBePaidForEveryToken = _sumToBePaidForEveryToken;

         
        drawerName = _drawerName;
        drawerRepresentedBy = _drawerRepresentedBy;
        linkToSignersAuthorityToRepresentTheDrawer = _linkToSignersAuthorityToRepresentTheDrawer;

         
         
        drawee = _drawee;
        draweeSignerAddress = _draweeSignerAddress;

    }

     
    function setPlacesAndTime(
        string calldata _timeOfPayment,
        string calldata _placeWhereTheBillIsIssued,
        string calldata _placeWherePaymentIsToBeMade
    ) external {

        require(msg.sender == creator, "Only contract creator can call 'setPlacesAndTime' function");

         
         

        issuedOnUnixTime = now;
        timeOfPayment = _timeOfPayment;

        placeWhereTheBillIsIssued = _placeWhereTheBillIsIssued;
        placeWherePaymentIsToBeMade = _placeWherePaymentIsToBeMade;

    }

     
    function setLegal(
        string calldata _description,
        string calldata _order,
        string calldata _disputeResolutionAgreement,
        address _cryptonomicaVerificationAddress

    ) external {

        require(msg.sender == creator, "Only contract creator can call 'setLegal' function");

         
         

        description = _description;
        order = _order;
        disputeResolutionAgreement = _disputeResolutionAgreement;
        cryptonomicaVerification = CryptonomicaVerification(_cryptonomicaVerificationAddress);

    }

    uint256 public acceptedOnUnixTime;

     
    event Acceptance(
        uint256 acceptedOnUnixTime,
        string drawee,
        address draweeRepresentedBy
    );

     
    function accept(string calldata _linkToSignersAuthorityToRepresentTheDrawee) external returns (bool success) {

         
        require(
            msg.sender == draweeSignerAddress ||
            msg.sender == creator,
            "Not authorized to accept"
        );

        signDisputeResolutionAgreementFor(draweeSignerAddress, drawee);

        linkToSignersAuthorityToRepresentTheDrawee = _linkToSignersAuthorityToRepresentTheDrawee;

        acceptedOnUnixTime = now;

        emit Acceptance(acceptedOnUnixTime, drawee, msg.sender);

        return true;
    }

}

 
 
contract BillsOfExchangeFactory is ManagedContractWithPaidService {

     

     
    string public description = "Every token (ERC20) in this smart contract is a bill of exchange in blank - payable to bearer (bearer is the owner of the Ethereum address witch holds the tokens, or the person he/she represents), but not to order - that means no endorsement possible and the token holder can only transfer the token (bill of exchange in blank) itself.";
     
    string public order = "Pay to bearer (tokenholder), but not to order, the sum defined for every token in currency defined in 'currency' (according to ISO 4217 standard; or XAU for for one troy ounce of gold, XBT or BTC for Bitcoin, ETH for Ether, DASH for Dash, ZEC for Zcash, XRP for Ripple, XMR for Monero, xEUR for xEuro)";
    string public disputeResolutionAgreement =
    "Any dispute, controversy or claim arising out of or relating to this bill(s) of exchange, including invalidity thereof and payments based on this bill(s), shall be settled by arbitration in accordance with the Cryptonomica Arbitration Rules (https://github.com/Cryptonomica/arbitration-rules) in the version in effect at the time of the filing of the claim. In the case of the Ethereum blockchain fork, the blockchain that has the highest hashrate is considered valid, and all others are not considered a valid registry; bill payment settles bill even if valid blockchain (hashrate) changes after the payment. All Ethereum test networks are not valid registries.";

     
    constructor() public {

        isAdmin[msg.sender] = true;

        changePrice(0.15 ether);

         
         
         
        require(changeCryptonomicaVerificationContractAddress(0x846942953c3b2A898F10DF1e32763A823bf6b27f));

        require(setWithdrawalAddress(msg.sender));
    }

     
    uint256 public billsOfExchangeContractsCounter;

     
    mapping(uint256 => address) public billsOfExchangeContractsLedger;

     
    function createBillsOfExchange(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        string memory _currency,
        uint256 _sumToBePaidForEveryToken,
        string memory _drawerName,
     
        string memory _linkToSignersAuthorityToRepresentTheDrawer,
        string memory _drawee,
        address _draweeSignerAddress,
        string memory _timeOfPayment,
        string memory _placeWhereTheBillIsIssued,
        string memory _placeWherePaymentIsToBeMade
    ) public payable returns (address newBillsOfExchangeContractAddress) {

        require(msg.value >= price, "Payment sent was lower than the price for creating Bills of Exchange");

        BillsOfExchange billsOfExchange = new BillsOfExchange();
        billsOfExchangeContractsCounter++;
        billsOfExchangeContractsLedger[billsOfExchangeContractsCounter] = address(billsOfExchange);

        billsOfExchange.initToken(
            _name,  
            _symbol,  
            _totalSupply,
            msg.sender  
        );

        billsOfExchange.initBillsOfExchange(
            billsOfExchangeContractsCounter,
            _currency,
            _sumToBePaidForEveryToken,
            _drawerName,
            msg.sender,
            _linkToSignersAuthorityToRepresentTheDrawer,
            _drawee,
            _draweeSignerAddress
        );

        billsOfExchange.setPlacesAndTime(
            _timeOfPayment,
            _placeWhereTheBillIsIssued,
            _placeWherePaymentIsToBeMade
        );

        billsOfExchange.setLegal(
            description,
            order,
            disputeResolutionAgreement,
            address(cryptonomicaVerification)
        );

         
        billsOfExchange.signDisputeResolutionAgreementFor(msg.sender, _drawerName);

        return address(billsOfExchange);
    }

     
    function createAndAcceptBillsOfExchange(
        string memory _name,  
        string memory _symbol,
        uint256 _totalSupply,
        string memory _currency,
        uint256 _sumToBePaidForEveryToken,
        string memory _drawerName,
     
        string memory _linkToSignersAuthorityToRepresentTheDrawer,
     
     
        string memory _timeOfPayment,
        string memory _placeWhereTheBillIsIssued,
        string memory _placeWherePaymentIsToBeMade

    ) public payable returns (address newBillsOfExchangeContractAddress) { 

        require(msg.value >= price, "Payment sent was lower than the price for creating Bills of Exchange");

        BillsOfExchange billsOfExchange = new BillsOfExchange();
        billsOfExchangeContractsCounter++;
        billsOfExchangeContractsLedger[billsOfExchangeContractsCounter] = address(billsOfExchange);

        billsOfExchange.initToken(
            _name,  
            _symbol,  
            _totalSupply,
            msg.sender  
        );

        billsOfExchange.initBillsOfExchange(
            billsOfExchangeContractsCounter,
            _currency,
            _sumToBePaidForEveryToken,
            _drawerName,
            msg.sender,
            _linkToSignersAuthorityToRepresentTheDrawer,
            _drawerName,  
            msg.sender  
        );

        billsOfExchange.setPlacesAndTime(
            _timeOfPayment,
            _placeWhereTheBillIsIssued,
            _placeWherePaymentIsToBeMade
        );

        billsOfExchange.setLegal(
            description,
            order,
            disputeResolutionAgreement,
            address(cryptonomicaVerification)
        );

         

        billsOfExchange.accept(_linkToSignersAuthorityToRepresentTheDrawer);

        return address(billsOfExchange);

    }

}