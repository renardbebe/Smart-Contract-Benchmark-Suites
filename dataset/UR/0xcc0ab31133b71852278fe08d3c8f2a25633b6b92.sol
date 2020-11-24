 

pragma solidity ^0.5.7;

 
 

interface ERC20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

     
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Only the contract's owner can invoke this function");
        _;
    }

      
    function _setOwner(address _newOwner) internal {
        _owner = _newOwner;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address _newOwner) external onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "New owner cannot be address(0)");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract ReentrancyGuard {
    
    bool public locked = false;

    modifier reentrancyGuard() {
        require(!locked, "Reentrant call detected!");
        locked = true;
        _;
        locked = false;
    }
}


contract Proxiable {
     
    event Upgraded(address indexed implementation);

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {  
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
        emit Upgraded(newAddress);
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
} 
 



 
contract MessageSigned {

    constructor() internal {}

     
    function _recoverAddress(bytes32 _signHash, bytes memory _messageSignature)
        internal
        pure
        returns(address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v,r,s) = signatureSplit(_messageSignature);
        return ecrecover(_signHash, v, r, s);
    }

     
    function _getSignHash(bytes32 _hash) internal pure returns (bytes32 signHash) {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

     
    function signatureSplit(bytes memory _signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(_signature.length == 65, "Bad signature length");
         
         
         
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
             
             
             
             
             
            v := and(mload(add(_signature, 65)), 0xff)
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Bad signature version");
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes memory _data) public;
}
 
 





contract SafeTransfer {
    function _safeTransfer(ERC20Token _token, address _to, uint256 _value) internal returns (bool result) {
        _token.transfer(_to, _value);
        assembly {
        switch returndatasize()
            case 0 {
            result := not(0)
            }
            case 32 {
            returndatacopy(0, 0, 32)
            result := mload(0)
            }
            default {
            revert(0, 0)
            }
        }
        require(result, "Unsuccessful token transfer");
    }

    function _safeTransferFrom(
        ERC20Token _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool result)
    {
        _token.transferFrom(_from, _to, _value);
        assembly {
        switch returndatasize()
            case 0 {
            result := not(0)
            }
            case 32 {
            returndatacopy(0, 0, 32)
            result := mload(0)
            }
            default {
            revert(0, 0)
            }
        }
        require(result, "Unsuccessful token transfer");
    }
}  
 








 
contract License is Ownable, ApproveAndCallFallBack, SafeTransfer, Proxiable {
    uint256 public price;

    ERC20Token token;
    address burnAddress;

    struct LicenseDetails {
        uint price;
        uint creationTime;
    }

    address[] public licenseOwners;
    mapping(address => uint) public idxLicenseOwners;
    mapping(address => LicenseDetails) public licenseDetails;

    event Bought(address buyer, uint256 price);
    event PriceChanged(uint256 _price);

    bool internal _initialized;

     
    constructor(address _tokenAddress, uint256 _price, address _burnAddress) public {
        init(_tokenAddress, _price, _burnAddress);
    }

     
    function init(
        address _tokenAddress,
        uint256 _price,
        address _burnAddress
    ) public {
        assert(_initialized == false);

        _initialized = true;

        price = _price;
        token = ERC20Token(_tokenAddress);
        burnAddress = _burnAddress;

        _setOwner(msg.sender);
    }

    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

     
    function isLicenseOwner(address _address) public view returns (bool) {
        return licenseDetails[_address].price != 0 && licenseDetails[_address].creationTime != 0;
    }

     
    function buy() external returns(uint) {
        uint id = _buyFrom(msg.sender);
        return id;
    }

     
    function _buyFrom(address _licenseOwner) internal returns(uint) {
        require(licenseDetails[_licenseOwner].creationTime == 0, "License already bought");

        licenseDetails[_licenseOwner] = LicenseDetails({
            price: price,
            creationTime: block.timestamp
        });

        uint idx = licenseOwners.push(_licenseOwner);
        idxLicenseOwners[_licenseOwner] = idx;

        emit Bought(_licenseOwner, price);

        require(_safeTransferFrom(token, _licenseOwner, burnAddress, price), "Unsuccessful token transfer");

        return idx;
    }

     
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceChanged(_price);
    }

     
    function getNumLicenseOwners() external view returns (uint256) {
        return licenseOwners.length;
    }

     
    function receiveApproval(address _from, uint256 _amount, address _token, bytes memory _data) public {
        require(_amount == price, "Wrong value");
        require(_token == address(token), "Wrong token");
        require(_token == address(msg.sender), "Wrong call");
        require(_data.length == 4, "Wrong data length");

        require(_abiDecodeBuy(_data) == bytes4(0xa6f2ae3a), "Wrong method selector"); //bytes4(keccak256("buy()"))

        _buyFrom(_from);
    }

     
    function _abiDecodeBuy(bytes memory _data) internal pure returns(bytes4 sig) {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
        }
    }
}


contract IEscrow {

  enum EscrowStatus {CREATED, FUNDED, PAID, RELEASED, CANCELED}

  struct EscrowTransaction {
      uint256 offerId;
      address token;
      uint256 tokenAmount;
      uint256 expirationTime;
      uint256 sellerRating;
      uint256 buyerRating;
      uint256 fiatAmount;
      address payable buyer;
      address payable seller;
      address payable arbitrator;
      EscrowStatus status;
  }

  function createEscrow_relayed(
        address payable _sender,
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount,
        string calldata _contactData,
        string calldata _location,
        string calldata _username
    ) external returns(uint escrowId);

  function pay(uint _escrowId) external;

  function pay_relayed(address _sender, uint _escrowId) external;

  function cancel(uint _escrowId) external;

  function cancel_relayed(address _sender, uint _escrowId) external;

  function openCase(uint  _escrowId, uint8 _motive) external;

  function openCase_relayed(address _sender, uint256 _escrowId, uint8 _motive) external;

  function rateTransaction(uint _escrowId, uint _rate) external;

  function rateTransaction_relayed(address _sender, uint _escrowId, uint _rate) external;

  function getBasicTradeData(uint _escrowId) external view returns(address payable buyer, address payable seller, address token, uint tokenAmount);

}







 
contract Pausable is Ownable {

    event Paused();
    event Unpaused();

    bool public paused;

    constructor () internal {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract must be unpaused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract must be paused");
        _;
    }

     
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

     
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }
}



 




 
contract ArbitrationLicense is License {

    enum RequestStatus {NONE,AWAIT,ACCEPTED,REJECTED,CLOSED}

    struct Request{
        address seller;
        address arbitrator;
        RequestStatus status;
        uint date;
    }

	struct ArbitratorLicenseDetails {
        uint id;
        bool acceptAny; 
    }

    mapping(address => ArbitratorLicenseDetails) public arbitratorlicenseDetails;
    mapping(address => mapping(address => bool)) public permissions;
    mapping(address => mapping(address => bool)) public blacklist;
    mapping(bytes32 => Request) public requests;

    event ArbitratorRequested(bytes32 id, address indexed seller, address indexed arbitrator);

    event RequestAccepted(bytes32 id, address indexed arbitrator, address indexed seller);
    event RequestRejected(bytes32 id, address indexed arbitrator, address indexed seller);
    event RequestCanceled(bytes32 id, address indexed arbitrator, address indexed seller);
    event BlacklistSeller(address indexed arbitrator, address indexed seller);
    event UnBlacklistSeller(address indexed arbitrator, address indexed seller);

     
    constructor(address _tokenAddress, uint256 _price, address _burnAddress)
      License(_tokenAddress, _price, _burnAddress)
      public {}

     
    function buy() external returns(uint) {
        return _buy(msg.sender, false);
    }

     
    function buy(bool _acceptAny) external returns(uint) {
        return _buy(msg.sender, _acceptAny);
    }

     
    function _buy(address _sender, bool _acceptAny) internal returns (uint id) {
        id = _buyFrom(_sender);
        arbitratorlicenseDetails[_sender].id = id;
        arbitratorlicenseDetails[_sender].acceptAny = _acceptAny;
    }

     
    function changeAcceptAny(bool _acceptAny) public {
        require(isLicenseOwner(msg.sender), "Message sender should have a valid arbitrator license");
        require(arbitratorlicenseDetails[msg.sender].acceptAny != _acceptAny,
                "Message sender should pass parameter different from the current one");

        arbitratorlicenseDetails[msg.sender].acceptAny = _acceptAny;
    }

     
    function requestArbitrator(address _arbitrator) public {
       require(isLicenseOwner(_arbitrator), "Arbitrator should have a valid license");
       require(!arbitratorlicenseDetails[_arbitrator].acceptAny, "Arbitrator already accepts all cases");

       bytes32 _id = keccak256(abi.encodePacked(_arbitrator, msg.sender));
       RequestStatus _status = requests[_id].status;
       require(_status != RequestStatus.AWAIT && _status != RequestStatus.ACCEPTED, "Invalid request status");

       if(_status == RequestStatus.REJECTED || _status == RequestStatus.CLOSED){
           require(requests[_id].date + 3 days < block.timestamp,
            "Must wait 3 days before requesting the arbitrator again");
       }

       requests[_id] = Request({
            seller: msg.sender,
            arbitrator: _arbitrator,
            status: RequestStatus.AWAIT,
            date: block.timestamp
       });

       emit ArbitratorRequested(_id, msg.sender, _arbitrator);
    }

     
    function getId(address _arbitrator, address _account) external pure returns(bytes32){
        return keccak256(abi.encodePacked(_arbitrator,_account));
    }

     
    function acceptRequest(bytes32 _id) public {
        require(isLicenseOwner(msg.sender), "Arbitrator should have a valid license");
        require(requests[_id].status == RequestStatus.AWAIT, "This request is not pending");
        require(!arbitratorlicenseDetails[msg.sender].acceptAny, "Arbitrator already accepts all cases");
        require(requests[_id].arbitrator == msg.sender, "Invalid arbitrator");

        requests[_id].status = RequestStatus.ACCEPTED;

        address _seller = requests[_id].seller;
        permissions[msg.sender][_seller] = true;

        emit RequestAccepted(_id, msg.sender, requests[_id].seller);
    }

     
    function rejectRequest(bytes32 _id) public {
        require(isLicenseOwner(msg.sender), "Arbitrator should have a valid license");
        require(requests[_id].status == RequestStatus.AWAIT || requests[_id].status == RequestStatus.ACCEPTED,
            "Invalid request status");
        require(!arbitratorlicenseDetails[msg.sender].acceptAny, "Arbitrator accepts all cases");
        require(requests[_id].arbitrator == msg.sender, "Invalid arbitrator");

        requests[_id].status = RequestStatus.REJECTED;
        requests[_id].date = block.timestamp;

        address _seller = requests[_id].seller;
        permissions[msg.sender][_seller] = false;

        emit RequestRejected(_id, msg.sender, requests[_id].seller);
    }

     
    function cancelRequest(bytes32 _id) public {
        require(requests[_id].seller == msg.sender,  "This request id does not belong to the message sender");
        require(requests[_id].status == RequestStatus.AWAIT || requests[_id].status == RequestStatus.ACCEPTED, "Invalid request status");

        address arbitrator = requests[_id].arbitrator;

        requests[_id].status = RequestStatus.CLOSED;
        requests[_id].date = block.timestamp;

        address _arbitrator = requests[_id].arbitrator;
        permissions[_arbitrator][msg.sender] = false;

        emit RequestCanceled(_id, arbitrator, requests[_id].seller);
    }

     
    function blacklistSeller(address _seller) public {
        require(isLicenseOwner(msg.sender), "Arbitrator should have a valid license");

        blacklist[msg.sender][_seller] = true;

        emit BlacklistSeller(msg.sender, _seller);
    }

     
    function unBlacklistSeller(address _seller) public {
        require(isLicenseOwner(msg.sender), "Arbitrator should have a valid license");

        blacklist[msg.sender][_seller] = false;

        emit UnBlacklistSeller(msg.sender, _seller);
    }

     
    function isAllowed(address _seller, address _arbitrator) public view returns(bool) {
        return (arbitratorlicenseDetails[_arbitrator].acceptAny && !blacklist[_arbitrator][_seller]) || permissions[_arbitrator][_seller];
    }

     
    function receiveApproval(address _from, uint256 _amount, address _token, bytes memory _data) public {
        require(_amount == price, "Wrong value");
        require(_token == address(token), "Wrong token");
        require(_token == address(msg.sender), "Wrong call");
        require(_data.length == 4, "Wrong data length");

        require(_abiDecodeBuy(_data) == bytes4(0xa6f2ae3a), "Wrong method selector"); //bytes4(keccak256("buy()"))

        _buy(_from, false);
    }
}











contract SecuredFunctions is Ownable {

    mapping(address => bool) public allowedContracts;

     
    modifier onlyAllowedContracts {
        require(allowedContracts[msg.sender] || msg.sender == address(this), "Only allowed contracts can invoke this function");
        _;
    }

     
    function setAllowedContract (
        address _contract,
        bool _allowed
    ) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }
}








contract Stakable is Ownable, SafeTransfer {

    uint public basePrice = 0.01 ether;

    address payable public burnAddress;

    struct Stake {
        uint amount;
        address payable owner;
        address token;
    }

    mapping(uint => Stake) public stakes;
    mapping(address => uint) public stakeCounter;

    event BurnAddressChanged(address sender, address prevBurnAddress, address newBurnAddress);
    event BasePriceChanged(address sender, uint prevPrice, uint newPrice);

    event Staked(uint indexed itemId, address indexed owner, uint amount);
    event Unstaked(uint indexed itemId, address indexed owner, uint amount);
    event Slashed(uint indexed itemId, address indexed owner, address indexed slasher, uint amount);

    constructor(address payable _burnAddress) public {
        burnAddress = _burnAddress;
    }

     
    function setBurnAddress(address payable _burnAddress) external onlyOwner {
        emit BurnAddressChanged(msg.sender, burnAddress, _burnAddress);
        burnAddress = _burnAddress;
    }

     
    function setBasePrice(uint _basePrice) external onlyOwner {
        emit BasePriceChanged(msg.sender, basePrice, _basePrice);
        basePrice = _basePrice;
    }

    function _stake(uint _itemId, address payable _owner, address _tokenAddress) internal {
        require(stakes[_itemId].owner == address(0), "Already has/had a stake");

        stakeCounter[_owner]++;

        uint stakeAmount = basePrice * stakeCounter[_owner] * stakeCounter[_owner];  

         
        _tokenAddress = address(0);
        require(msg.value == stakeAmount, "ETH amount is required");

         
         

        stakes[_itemId].amount = stakeAmount;
        stakes[_itemId].owner = _owner;
        stakes[_itemId].token = _tokenAddress;

        emit Staked(_itemId,  _owner, stakeAmount);
    }

    function getAmountToStake(address _owner) public view returns(uint){
        uint stakeCnt = stakeCounter[_owner] + 1;
        return basePrice * stakeCnt * stakeCnt;  
    }

    function _unstake(uint _itemId) internal {
        Stake storage s = stakes[_itemId];

        if (s.amount == 0) return;  

        uint amount = s.amount;
        s.amount = 0;

        assert(stakeCounter[s.owner] > 0);
        stakeCounter[s.owner]--;

        if (s.token == address(0)) {
            (bool success, ) = s.owner.call.value(amount)("");
            require(success, "Transfer failed.");
        } else {
            require(_safeTransfer(ERC20Token(s.token), s.owner, amount), "Couldn't transfer funds");
        }

        emit Unstaked(_itemId, s.owner, amount);
    }

    function _slash(uint _itemId) internal {
        Stake storage s = stakes[_itemId];

         
        if (s.amount == 0) return;

        uint amount = s.amount;
        s.amount = 0;

        if (s.token == address(0)) {
            (bool success, ) = burnAddress.call.value(amount)("");
            require(success, "Transfer failed.");
        } else {
            require(_safeTransfer(ERC20Token(s.token), burnAddress, amount), "Couldn't transfer funds");
        }

        emit Slashed(_itemId, s.owner, msg.sender, amount);
    }

    function _refundStake(uint _itemId) internal {
        Stake storage s = stakes[_itemId];

        if (s.amount == 0) return;

        uint amount = s.amount;
        s.amount = 0;

        stakeCounter[s.owner]--;

        if (amount != 0) {
            if (s.token == address(0)) {
                (bool success, ) = s.owner.call.value(amount)("");
                require(success, "Transfer failed.");
            } else {
                require(_safeTransfer(ERC20Token(s.token), s.owner, amount), "Couldn't transfer funds");
            }
        }
    }

}



 
contract MetadataStore is Stakable, MessageSigned, SecuredFunctions, Proxiable {

    struct User {
        string contactData;
        string location;
        string username;
    }

    struct Offer {
        int16 margin;
        uint[] paymentMethods;
        uint limitL;
        uint limitU;
        address asset;
        string currency;
        address payable owner;
        address payable arbitrator;
        bool deleted;
    }

    License public sellingLicenses;
    ArbitrationLicense public arbitrationLicenses;

    mapping(address => User) public users;
    mapping(address => uint) public user_nonce;

    Offer[] public offers;
    mapping(address => uint256[]) public addressToOffers;
    mapping(address => mapping (uint256 => bool)) public offerWhitelist;

    bool internal _initialized;

    event OfferAdded(
        address owner,
        uint256 offerId,
        address asset,
        string location,
        string currency,
        string username,
        uint[] paymentMethods,
        uint limitL,
        uint limitU,
        int16 margin
    );

    event OfferRemoved(address owner, uint256 offerId);

     
    constructor(address _sellingLicenses, address _arbitrationLicenses, address payable _burnAddress) public
        Stakable(_burnAddress)
    {
        init(_sellingLicenses, _arbitrationLicenses);
    }

     
    function init(
        address _sellingLicenses,
        address _arbitrationLicenses
    ) public {
        assert(_initialized == false);

        _initialized = true;

        sellingLicenses = License(_sellingLicenses);
        arbitrationLicenses = ArbitrationLicense(_arbitrationLicenses);

        basePrice = 0.01 ether;


        _setOwner(msg.sender);
    }

    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

    event LicensesChanged(address sender, address oldSellingLicenses, address newSellingLicenses, address oldArbitrationLicenses, address newArbitrationLicenses);

     
    function setLicenses(
        address _sellingLicenses,
        address _arbitrationLicenses
    ) public onlyOwner {
        emit LicensesChanged(msg.sender, address(sellingLicenses), address(_sellingLicenses), address(arbitrationLicenses), (_arbitrationLicenses));

        sellingLicenses = License(_sellingLicenses);
        arbitrationLicenses = ArbitrationLicense(_arbitrationLicenses);
    }

     
    function _dataHash(string memory _username, string memory _contactData, uint _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _username, _contactData, _nonce));
    }

     
    function getDataHash(string calldata _username, string calldata _contactData) external view returns (bytes32) {
        return _dataHash(_username, _contactData, user_nonce[msg.sender]);
    }

     
    function _getSigner(
        string memory _username,
        string memory _contactData,
        uint _nonce,
        bytes memory _signature
    ) internal view returns(address) {
        bytes32 signHash = _getSignHash(_dataHash(_username, _contactData, _nonce));
        return _recoverAddress(signHash, _signature);
    }

     
    function getMessageSigner(
        string calldata _username,
        string calldata _contactData,
        uint _nonce,
        bytes calldata _signature
    ) external view returns(address) {
        return _getSigner(_username, _contactData, _nonce, _signature);
    }

     
    function _addOrUpdateUser(
        address _user,
        string memory _contactData,
        string memory _location,
        string memory _username
    ) internal {
        User storage u = users[_user];
        u.contactData = _contactData;
        u.location = _location;
        u.username = _username;
    }

     
    function addOrUpdateUser(
        bytes calldata _signature,
        string calldata _contactData,
        string calldata _location,
        string calldata _username,
        uint _nonce
    ) external returns(address payable _user) {
        _user = address(uint160(_getSigner(_username, _contactData, _nonce, _signature)));

        require(_nonce == user_nonce[_user], "Invalid nonce");

        user_nonce[_user]++;
        _addOrUpdateUser(_user, _contactData, _location, _username);

        return _user;
    }

     
    function addOrUpdateUser(
        string calldata _contactData,
        string calldata _location,
        string calldata _username
    ) external {
        _addOrUpdateUser(msg.sender, _contactData, _location, _username);
    }

     
    function addOrUpdateUser(
        address _sender,
        string calldata _contactData,
        string calldata _location,
        string calldata _username
    ) external onlyAllowedContracts {
        _addOrUpdateUser(_sender, _contactData, _location, _username);
    }

     
    function addOffer(
        address _asset,
        string memory _contactData,
        string memory _location,
        string memory _currency,
        string memory _username,
        uint[] memory _paymentMethods,
        uint _limitL,
        uint _limitU,
        int16 _margin,
        address payable _arbitrator
    ) public payable {
         
         

        require(arbitrationLicenses.isAllowed(msg.sender, _arbitrator), "Arbitrator does not allow this transaction");

        require(_limitL <= _limitU, "Invalid limits");
        require(msg.sender != _arbitrator, "Cannot arbitrate own offers");

        _addOrUpdateUser(
            msg.sender,
            _contactData,
            _location,
            _username
        );

        Offer memory newOffer = Offer(
            _margin,
            _paymentMethods,
            _limitL,
            _limitU,
            _asset,
            _currency,
            msg.sender,
            _arbitrator,
            false
        );

        uint256 offerId = offers.push(newOffer) - 1;
        offerWhitelist[msg.sender][offerId] = true;
        addressToOffers[msg.sender].push(offerId);

        emit OfferAdded(
            msg.sender,
            offerId,
            _asset,
            _location,
            _currency,
            _username,
            _paymentMethods,
            _limitL,
            _limitU,
            _margin);

        _stake(offerId, msg.sender, _asset);
    }

     
    function removeOffer(uint256 _offerId) external {
        require(offerWhitelist[msg.sender][_offerId], "Offer does not exist");

        offers[_offerId].deleted = true;
        offerWhitelist[msg.sender][_offerId] = false;
        emit OfferRemoved(msg.sender, _offerId);

        _unstake(_offerId);
    }

     
    function offer(uint256 _id) external view returns (
        address asset,
        string memory currency,
        int16 margin,
        uint[] memory paymentMethods,
        uint limitL,
        uint limitH,
        address payable owner,
        address payable arbitrator,
        bool deleted
    ) {
        Offer memory theOffer = offers[_id];

         
        address payable offerArbitrator = theOffer.arbitrator;
        if(!arbitrationLicenses.isAllowed(theOffer.owner, offerArbitrator)){
            offerArbitrator = address(0);
        }

        return (
            theOffer.asset,
            theOffer.currency,
            theOffer.margin,
            theOffer.paymentMethods,
            theOffer.limitL,
            theOffer.limitU,
            theOffer.owner,
            offerArbitrator,
            theOffer.deleted
        );
    }

     
    function getOfferOwner(uint256 _id) external view returns (address payable) {
        return (offers[_id].owner);
    }

     
    function getAsset(uint256 _id) external view returns (address) {
        return (offers[_id].asset);
    }

     
    function getArbitrator(uint256 _id) external view returns (address payable) {
        return (offers[_id].arbitrator);
    }

     
    function offersSize() external view returns (uint256) {
        return offers.length;
    }

     
    function getOfferIds(address _address) external view returns (uint256[] memory) {
        return addressToOffers[_address];
    }

     
    function slashStake(uint _offerId) external onlyAllowedContracts {
        _slash(_offerId);
    }

     
    function refundStake(uint _offerId) external onlyAllowedContracts {
        _refundStake(_offerId);
    }
}








 
contract Fees is Ownable, ReentrancyGuard, SafeTransfer {
    address payable public feeDestination;
    uint public feeMilliPercent;
    mapping(address => uint) public feeTokenBalances;
    mapping(uint => bool) public feePaid;

    event FeeDestinationChanged(address payable);
    event FeeMilliPercentChanged(uint amount);
    event FeesWithdrawn(uint amount, address token);

     
    constructor(address payable _feeDestination, uint _feeMilliPercent) public {
        feeDestination = _feeDestination;
        feeMilliPercent = _feeMilliPercent;
    }

     
    function setFeeDestinationAddress(address payable _addr) external onlyOwner {
        feeDestination = _addr;
        emit FeeDestinationChanged(_addr);
    }

     
    function setFeeAmount(uint _feeMilliPercent) external onlyOwner {
        feeMilliPercent = _feeMilliPercent;
        emit FeeMilliPercentChanged(_feeMilliPercent);
    }

     
    function _releaseFee(address payable _arbitrator, uint _value, address _tokenAddress, bool _isDispute) internal reentrancyGuard {
        uint _milliPercentToArbitrator;
        if (_isDispute) {
            _milliPercentToArbitrator = 100000;  
        } else {
            _milliPercentToArbitrator = 10000;  
        }

        uint feeAmount = _getValueOffMillipercent(_value, feeMilliPercent);
        uint arbitratorValue = _getValueOffMillipercent(feeAmount, _milliPercentToArbitrator);
        uint destinationValue = feeAmount - arbitratorValue;

        if (_tokenAddress != address(0)) {
            ERC20Token tokenToPay = ERC20Token(_tokenAddress);
            require(_safeTransfer(tokenToPay, _arbitrator, arbitratorValue), "Unsuccessful token transfer - arbitrator");
            if (destinationValue > 0) {
                require(_safeTransfer(tokenToPay, feeDestination, destinationValue), "Unsuccessful token transfer - destination");
            }
        } else {
             
            (bool success, ) = _arbitrator.call.value(arbitratorValue)("");
            require(success, "Transfer failed.");

            if (destinationValue > 0) {
                 
                (bool success, ) = feeDestination.call.value(destinationValue)("");
                require(success, "Transfer failed.");

            }
        }
    }

     
    function _getValueOffMillipercent(uint _value, uint _milliPercent) internal pure returns(uint) {
         
         
        return (_value * _milliPercent) / (100 * 1000);
    }

     
    function _payFee(address _from, uint _id, uint _value, address _tokenAddress) internal {
        if (feePaid[_id]) return;

        feePaid[_id] = true;
        uint feeAmount = _getValueOffMillipercent(_value, feeMilliPercent);
        feeTokenBalances[_tokenAddress] += feeAmount;

        if (_tokenAddress != address(0)) {
            require(msg.value == 0, "Cannot send ETH with token address different from 0");

            ERC20Token tokenToPay = ERC20Token(_tokenAddress);
            require(_safeTransferFrom(tokenToPay, _from, address(this), feeAmount + _value), "Unsuccessful token transfer");
        } else {
            require(msg.value == (_value + feeAmount), "ETH amount is required");
        }
    }
}

 




 
contract Arbitrable {

    enum ArbitrationResult {UNSOLVED, BUYER, SELLER}
    enum ArbitrationMotive {NONE, UNRESPONSIVE, PAYMENT_ISSUE, OTHER}


    ArbitrationLicense public arbitratorLicenses;

    mapping(uint => ArbitrationCase) public arbitrationCases;

    address public fallbackArbitrator;

    struct ArbitrationCase {
        bool open;
        address openBy;
        address arbitrator;
        uint arbitratorTimeout;
        ArbitrationResult result;
        ArbitrationMotive motive;
    }

    event ArbitratorChanged(address arbitrator);
    event ArbitrationCanceled(uint escrowId);
    event ArbitrationRequired(uint escrowId, uint timeout);
    event ArbitrationResolved(uint escrowId, ArbitrationResult result, address arbitrator);

     
    constructor(address _arbitratorLicenses, address _fallbackArbitrator) public {
        arbitratorLicenses = ArbitrationLicense(_arbitratorLicenses);
        fallbackArbitrator = _fallbackArbitrator;
    }

     
    function _solveDispute(uint _escrowId, bool _releaseFunds, address _arbitrator) internal;

     
    function _getArbitrator(uint _escrowId) internal view returns(address);

     
    function isDisputed(uint _escrowId) public view returns (bool) {
        return _isDisputed(_escrowId);
    }

    function _isDisputed(uint _escrowId) internal view returns (bool) {
        return arbitrationCases[_escrowId].open || arbitrationCases[_escrowId].result != ArbitrationResult.UNSOLVED;
    }

     
    function hadDispute(uint _escrowId) public view returns (bool) {
        return arbitrationCases[_escrowId].result != ArbitrationResult.UNSOLVED;
    }

     
    function cancelArbitration(uint _escrowId) external {
        require(arbitrationCases[_escrowId].openBy == msg.sender, "Arbitration can only be canceled by the opener");
        require(arbitrationCases[_escrowId].result == ArbitrationResult.UNSOLVED && arbitrationCases[_escrowId].open,
                "Arbitration already solved or not open");

        delete arbitrationCases[_escrowId];

        emit ArbitrationCanceled(_escrowId);
    }

     
    function _openDispute(uint _escrowId, address _openBy, uint8 _motive) internal {
        require(arbitrationCases[_escrowId].result == ArbitrationResult.UNSOLVED && !arbitrationCases[_escrowId].open,
                "Arbitration already solved or has been opened before");

        address arbitratorAddress = _getArbitrator(_escrowId);

        require(arbitratorAddress != address(0), "Arbitrator is required");

        uint timeout = block.timestamp + 5 days;

        arbitrationCases[_escrowId] = ArbitrationCase({
            open: true,
            openBy: _openBy,
            arbitrator: arbitratorAddress,
            arbitratorTimeout: timeout,
            result: ArbitrationResult.UNSOLVED,
            motive: ArbitrationMotive(_motive)
        });

        emit ArbitrationRequired(_escrowId, timeout);
    }

     
    function setArbitrationResult(uint _escrowId, ArbitrationResult _result) external {
        require(arbitrationCases[_escrowId].open && arbitrationCases[_escrowId].result == ArbitrationResult.UNSOLVED,
                "Case must be open and unsolved");
        require(_result != ArbitrationResult.UNSOLVED, "Arbitration does not have result");
        require(arbitratorLicenses.isLicenseOwner(msg.sender), "Only arbitrators can invoke this function");

        if (block.timestamp > arbitrationCases[_escrowId].arbitratorTimeout) {
            require(arbitrationCases[_escrowId].arbitrator == msg.sender || msg.sender == fallbackArbitrator, "Invalid escrow arbitrator");
        } else {
            require(arbitrationCases[_escrowId].arbitrator == msg.sender, "Invalid escrow arbitrator");
        }

        arbitrationCases[_escrowId].open = false;
        arbitrationCases[_escrowId].result = _result;

        emit ArbitrationResolved(_escrowId, _result, msg.sender);

        if(_result == ArbitrationResult.BUYER){
            _solveDispute(_escrowId, true, msg.sender);
        } else {
            _solveDispute(_escrowId, false, msg.sender);
        }
    }
}




 
contract Escrow is IEscrow, Pausable, MessageSigned, Fees, Arbitrable, Proxiable {

    EscrowTransaction[] public transactions;

    address public relayer;
    MetadataStore public metadataStore;

    event Created(uint indexed offerId, address indexed seller, address indexed buyer, uint escrowId);
    event Funded(uint indexed escrowId, address indexed buyer, uint expirationTime, uint amount);
    event Paid(uint indexed escrowId, address indexed seller);
    event Released(uint indexed escrowId, address indexed seller, address indexed buyer, bool isDispute);
    event Canceled(uint indexed escrowId, address indexed seller, address indexed buyer, bool isDispute);
    
    event Rating(uint indexed offerId, address indexed participant, uint indexed escrowId, uint rating, bool ratingSeller);

    bool internal _initialized;

     
    constructor(
        address _relayer,
        address _fallbackArbitrator,
        address _arbitratorLicenses,
        address _metadataStore,
        address payable _feeDestination,
        uint _feeMilliPercent)
        Fees(_feeDestination, _feeMilliPercent)
        Arbitrable(_arbitratorLicenses, _fallbackArbitrator)
        public {
        _initialized = true;
        relayer = _relayer;
        metadataStore = MetadataStore(_metadataStore);
    }

     
    function init(
        address _fallbackArbitrator,
        address _relayer,
        address _arbitratorLicenses,
        address _metadataStore,
        address payable _feeDestination,
        uint _feeMilliPercent
    ) external {
        assert(_initialized == false);

        _initialized = true;

        fallbackArbitrator = _fallbackArbitrator;
        arbitratorLicenses = ArbitrationLicense(_arbitratorLicenses);
        metadataStore = MetadataStore(_metadataStore);
        relayer = _relayer;
        feeDestination = _feeDestination;
        feeMilliPercent = _feeMilliPercent;
        paused = false;
        _setOwner(msg.sender);
    }

    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

     
    function setRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
    }

     
    function setFallbackArbitrator(address _fallbackArbitrator) external onlyOwner {
        fallbackArbitrator = _fallbackArbitrator;
    }

     
    function setArbitratorLicense(address _arbitratorLicenses) external onlyOwner {
        arbitratorLicenses = ArbitrationLicense(_arbitratorLicenses);
    }

     
    function setMetadataStore(address _metadataStore) external onlyOwner {
        metadataStore = MetadataStore(_metadataStore);
    }

     
    function _createTransaction(
        address payable _buyer,
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount
    ) internal whenNotPaused returns(uint escrowId)
    {
        address payable seller;
        address payable arbitrator;
        bool deleted;
        address token;

        (token, , , , , , seller, arbitrator, deleted) = metadataStore.offer(_offerId);

        require(!deleted, "Offer is not valid");
        require(seller != _buyer, "Seller and Buyer must be different");
        require(arbitrator != _buyer && arbitrator != address(0), "Cannot buy offers where buyer is arbitrator");
        require(_tokenAmount != 0 && _fiatAmount != 0, "Trade amounts cannot be 0");

        escrowId = transactions.length++;

        EscrowTransaction storage trx = transactions[escrowId];

        trx.offerId = _offerId;
        trx.token = token;
        trx.buyer = _buyer;
        trx.seller = seller;
        trx.arbitrator = arbitrator;
        trx.tokenAmount = _tokenAmount;
        trx.fiatAmount = _fiatAmount;

        emit Created(
            _offerId,
            seller,
            _buyer,
            escrowId
        );
    }

     
    function createEscrow(
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount,
        string memory _contactData,
        string memory _location,
        string memory _username
    ) public returns(uint escrowId) {
        metadataStore.addOrUpdateUser(msg.sender, _contactData, _location, _username);
        escrowId = _createTransaction(msg.sender, _offerId, _tokenAmount, _fiatAmount);
    }

     
    function createEscrow(
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount,
        string memory _contactData,
        string memory _location,
        string memory _username,
        uint _nonce,
        bytes memory _signature
    ) public returns(uint escrowId) {
        address payable _buyer = metadataStore.addOrUpdateUser(_signature, _contactData, _location, _username, _nonce);
        escrowId = _createTransaction(_buyer, _offerId, _tokenAmount, _fiatAmount);
    }

    
    function createEscrow_relayed(
        address payable _sender,
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount,
        string calldata _contactData,
        string calldata _location,
        string calldata _username
    ) external returns(uint escrowId) {
        assert(msg.sender == relayer);

        metadataStore.addOrUpdateUser(_sender, _contactData, _location, _username);
        escrowId = _createTransaction(_sender, _offerId, _tokenAmount, _fiatAmount);
    }

     
    function fund(uint _escrowId) external payable whenNotPaused {
        _fund(msg.sender, _escrowId);
    }

     
    function _fund(address _from, uint _escrowId) internal whenNotPaused {
        require(transactions[_escrowId].seller == _from, "Only the seller can invoke this function");
        require(transactions[_escrowId].status == EscrowStatus.CREATED, "Invalid escrow status");

        transactions[_escrowId].expirationTime = block.timestamp + 5 days;
        transactions[_escrowId].status = EscrowStatus.FUNDED;

        uint tokenAmount = transactions[_escrowId].tokenAmount;

        address token = transactions[_escrowId].token;

        _payFee(_from, _escrowId, tokenAmount, token);

        emit Funded(_escrowId, transactions[_escrowId].buyer, block.timestamp + 5 days, tokenAmount);
    }

     
    function createAndFund (
        uint _offerId,
        uint _tokenAmount,
        uint _fiatAmount,
        string memory _bContactData,
        string memory _bLocation,
        string memory _bUsername,
        uint _bNonce,
        bytes memory _bSignature
    ) public payable returns(uint escrowId) {
        address payable _buyer = metadataStore.addOrUpdateUser(_bSignature, _bContactData, _bLocation, _bUsername, _bNonce);
        escrowId = _createTransaction(_buyer, _offerId, _tokenAmount, _fiatAmount);
        _fund(msg.sender, escrowId);
    }

     
    function _pay(address _sender, uint _escrowId) internal {
        EscrowTransaction storage trx = transactions[_escrowId];

        require(trx.status == EscrowStatus.FUNDED, "Transaction is not funded");
        require(trx.expirationTime > block.timestamp, "Transaction already expired");
        require(trx.buyer == _sender, "Only the buyer can invoke this function");

        trx.status = EscrowStatus.PAID;

        emit Paid(_escrowId, trx.seller);
    }

     
    function pay(uint _escrowId) external {
        _pay(msg.sender, _escrowId);
    }

     
    function pay_relayed(address _sender, uint _escrowId) external {
        assert(msg.sender == relayer);
        _pay(_sender, _escrowId);
    }

     
    function paySignHash(uint _escrowId) public view returns(bytes32){
        return keccak256(
            abi.encodePacked(
                address(this),
                "pay(uint256)",
                _escrowId
            )
        );
    }

     
    function pay(uint _escrowId, bytes calldata _signature) external {
        address sender = _recoverAddress(_getSignHash(paySignHash(_escrowId)), _signature);
        _pay(sender, _escrowId);
    }

     
    function _release(uint _escrowId, EscrowTransaction storage _trx, bool _isDispute) internal {
        require(_trx.status != EscrowStatus.RELEASED, "Already released");
        _trx.status = EscrowStatus.RELEASED;

        if(!_isDispute){
            metadataStore.refundStake(_trx.offerId);
        }

        address token = _trx.token;
        if(token == address(0)){
            (bool success, ) = _trx.buyer.call.value(_trx.tokenAmount)("");
            require(success, "Transfer failed.");
        } else {
            require(_safeTransfer(ERC20Token(token), _trx.buyer, _trx.tokenAmount), "Couldn't transfer funds");
        }

        _releaseFee(_trx.arbitrator, _trx.tokenAmount, token, _isDispute);

        emit Released(_escrowId, _trx.seller, _trx.buyer, _isDispute);
    }

     
    function release(uint _escrowId) external {
        EscrowStatus mStatus = transactions[_escrowId].status;
        require(transactions[_escrowId].seller == msg.sender, "Only the seller can invoke this function");
        require(mStatus == EscrowStatus.PAID || mStatus == EscrowStatus.FUNDED, "Invalid transaction status");
        require(!_isDisputed(_escrowId), "Can't release a transaction that has an arbitration process");
        _release(_escrowId, transactions[_escrowId], false);
    }

     
    function cancel(uint _escrowId) external whenNotPaused {
        EscrowTransaction storage trx = transactions[_escrowId];

        EscrowStatus mStatus = trx.status;
        require(mStatus == EscrowStatus.FUNDED || mStatus == EscrowStatus.CREATED,
                "Only transactions in created or funded state can be canceled");

        require(trx.buyer == msg.sender || trx.seller == msg.sender, "Only participants can invoke this function");

        if(mStatus == EscrowStatus.FUNDED){
            if(msg.sender == trx.seller){
                require(trx.expirationTime < block.timestamp, "Can only be canceled after expiration");
            }
        }

        _cancel(_escrowId, trx, false);
    }

     
    function cancel_relayed(address _sender, uint _escrowId) external {
        assert(msg.sender == relayer);

        EscrowTransaction storage trx = transactions[_escrowId];
        EscrowStatus mStatus = trx.status;
        require(trx.buyer == _sender, "Only the buyer can invoke this function");
        require(mStatus == EscrowStatus.FUNDED || mStatus == EscrowStatus.CREATED,
                "Only transactions in created or funded state can be canceled");

         _cancel(_escrowId, trx, false);
    }

     
    function _cancel(uint _escrowId, EscrowTransaction storage trx, bool isDispute) internal {
        EscrowStatus origStatus = trx.status;

        require(trx.status != EscrowStatus.CANCELED, "Already canceled");

        trx.status = EscrowStatus.CANCELED;

        if (origStatus == EscrowStatus.FUNDED) {
            address token = trx.token;
            uint amount = trx.tokenAmount;
            if (!isDispute) {
                amount += _getValueOffMillipercent(trx.tokenAmount, feeMilliPercent);
            }

            if (token == address(0)) {
                (bool success, ) = trx.seller.call.value(amount)("");
                require(success, "Transfer failed.");
            } else {
                ERC20Token erc20token = ERC20Token(token);
                require(_safeTransfer(erc20token, trx.seller, amount), "Transfer failed");
            }
        }

        trx.status = EscrowStatus.CANCELED;

        emit Canceled(_escrowId, trx.seller, trx.buyer, isDispute);
    }


     
    function _rateTransaction(address _sender, uint _escrowId, uint _rate) internal {
        require(_rate >= 1, "Rating needs to be at least 1");
        require(_rate <= 5, "Rating needs to be at less than or equal to 5");
        EscrowTransaction storage trx = transactions[_escrowId];
        require(trx.status == EscrowStatus.RELEASED || hadDispute(_escrowId), "Transaction not completed yet");

        if (trx.buyer == _sender) {
            require(trx.sellerRating == 0, "Transaction already rated");
            emit Rating(trx.offerId, trx.seller, _escrowId, _rate, true);
            trx.sellerRating = _rate;
        } else if (trx.seller == _sender) {
            require(trx.buyerRating == 0, "Transaction already rated");
            emit Rating(trx.offerId, trx.buyer, _escrowId, _rate, false);
            trx.buyerRating = _rate;
        } else {
            revert("Only participants can invoke this function");
        }
    }

     
    function rateTransaction(uint _escrowId, uint _rate) external {
        _rateTransaction(msg.sender, _escrowId, _rate);
    }

     
    function rateTransaction_relayed(address _sender, uint _escrowId, uint _rate) external {
        assert(msg.sender == relayer);
        _rateTransaction(_sender, _escrowId, _rate);

    }

     
    function getBasicTradeData(uint _escrowId)
      external
      view
      returns(address payable buyer, address payable seller, address token, uint tokenAmount) {
        buyer = transactions[_escrowId].buyer;
        seller = transactions[_escrowId].seller;
        tokenAmount = transactions[_escrowId].tokenAmount;
        token = transactions[_escrowId].token;

        return (buyer, seller, token, tokenAmount);
    }

     
    function openCase(uint _escrowId, uint8 _motive) external {
        EscrowTransaction storage trx = transactions[_escrowId];

        require(!isDisputed(_escrowId), "Case already exist");
        require(trx.buyer == msg.sender || trx.seller == msg.sender, "Only participants can invoke this function");
        require(trx.status == EscrowStatus.PAID, "Cases can only be open for paid transactions");

        _openDispute(_escrowId, msg.sender, _motive);
    }

     
    function openCase_relayed(address _sender, uint256 _escrowId, uint8 _motive) external {
        assert(msg.sender == relayer);

        EscrowTransaction storage trx = transactions[_escrowId];

        require(!isDisputed(_escrowId), "Case already exist");
        require(trx.buyer == _sender, "Only the buyer can invoke this function");
        require(trx.status == EscrowStatus.PAID, "Cases can only be open for paid transactions");

        _openDispute(_escrowId, _sender, _motive);
    }

     
    function openCase(uint _escrowId, uint8 _motive, bytes calldata _signature) external {
        EscrowTransaction storage trx = transactions[_escrowId];

        require(!isDisputed(_escrowId), "Case already exist");
        require(trx.status == EscrowStatus.PAID, "Cases can only be open for paid transactions");

        address senderAddress = _recoverAddress(_getSignHash(openCaseSignHash(_escrowId, _motive)), _signature);

        require(trx.buyer == senderAddress || trx.seller == senderAddress, "Only participants can invoke this function");

        _openDispute(_escrowId, msg.sender, _motive);
    }

     
    function _solveDispute(uint _escrowId, bool _releaseFunds, address _arbitrator) internal {
        EscrowTransaction storage trx = transactions[_escrowId];

        require(trx.buyer != _arbitrator && trx.seller != _arbitrator, "Arbitrator cannot be part of transaction");

        if (_releaseFunds) {
            _release(_escrowId, trx, true);
            metadataStore.slashStake(trx.offerId);
        } else {
            _cancel(_escrowId, trx, true);
            _releaseFee(trx.arbitrator, trx.tokenAmount, trx.token, true);
        }
    }

     
    function _getArbitrator(uint _escrowId) internal view returns(address) {
        return transactions[_escrowId].arbitrator;
    }

     
    function openCaseSignHash(uint _escrowId, uint8 _motive) public view returns(bytes32){
        return keccak256(
            abi.encodePacked(
                address(this),
                "openCase(uint256)",
                _escrowId,
                _motive
            )
        );
    }

     
    function receiveApproval(address _from, uint256 _amount, address _token, bytes memory _data) public {
        require(_token == address(msg.sender), "Wrong call");
        require(_data.length == 36, "Wrong data length");

        bytes4 sig;
        uint256 escrowId;

        (sig, escrowId) = _abiDecodeFundCall(_data);

        if (sig == bytes4(0xca1d209d)){  
            uint tokenAmount = transactions[escrowId].tokenAmount;
            require(_amount == tokenAmount + _getValueOffMillipercent(tokenAmount, feeMilliPercent), "Invalid amount");
            _fund(_from, escrowId);
        } else {
            revert("Wrong method selector");
        }
    }

     
    function _abiDecodeFundCall(bytes memory _data) internal pure returns (bytes4 sig, uint256 escrowId) {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            escrowId := mload(add(_data, 36))
        }
    }

     
    function withdraw_emergency(uint _escrowId) external whenPaused {
        EscrowTransaction storage trx = transactions[_escrowId];
        require(trx.status == EscrowStatus.FUNDED, "Cannot withdraw from escrow in a stage different from FUNDED. Open a case");

        _cancel(_escrowId, trx, false);
    }
}