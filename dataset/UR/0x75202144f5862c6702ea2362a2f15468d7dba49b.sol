 

 

pragma solidity ^0.5.7;

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
 
contract IKYC {
     
    event ManagerStatusUpdated(address KYCManager, bool managerStatus);

     
    event UserStatusUpdated(address user, bool status);

     
     
     
     
    function setKYCManagerStatus(address KYCManager, bool managerStatus)
        public
        returns (bool);

     
     
     
     
    function setUserAddressStatus(address userAddress, bool passedKYC)
        public
        returns (bool);

     
     
     
    function getAddressStatus(address userAddress) public view returns (bool);

}

 

 
contract IProperties {
     
    event OwnerChanged(address newOwner);

     
    event ManagerSet(address manager, bool status);

     
    event PropertyCreated(
        uint256 propertyId,
        uint256 allocationCapacity,
        string title,
        string location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT,
        uint256 dateAdded
    );

     
    event PropertyStatusUpdated(uint256 propertyId, uint256 status);

     
    event PropertyInvested(uint256 propertyId, uint256 tokens);

     
    event InvestmentContractStatusSet(address investmentContract, bool status);

     
    event PropertyUpdated(uint256 propertyId);

     
    function changeOwner(address newOwner) external;

     
    function setManager(address manager, bool status) external;

     
    function createProperty(
        uint256 allocationCapacity,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT
    ) public returns (bool);

     
    function updatePropertyStatus(uint256 propertyId, uint256 status) external;

     
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        returns (bool);

     
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external;

     
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        );

     
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory);

     
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares);
}

 

 
contract IAllocationToken {
     
    event ExchangeContractUpdated(address exchangeContract);

     
    event InvestmentContractUpdated(address investmentContract);

     
    function updateExchangeContract(address _exchangeContract) external;

     
    function updateInvestmentContract(address _investmentContract) external;

     
    function mint(address _holder, uint256 _tokens) public;

     
    function burn(address _address, uint256 _value) public;
}

 

 
contract IInvestment {
     
    event StateChanged(uint256 state);

     
    event Invested(
        uint256 propertyId,
        address investor,
        address tokenAddress,
        uint256 tokens
    );

     
    event PropertySet(address property);

     
    event PremiumStatusOfUserChanged(address user, bool status);

     
    event AllocationTokenStateChanged(address allocationToken, bool state);

     
    function invest(uint256 propertyId, address tokenAddress, uint256 tokens)
        external;

     
    function setState(uint256 state) external;

     
    function setProperty(IProperties _property) external;

     

     
    function setAllocationTokenState(
        address _token,
        bool _state,
        bool _isPremium
    ) external;

     
    function changePremiumStatusOfUser(address user, bool status) public;

}

 

 
contract Investment is IInvestment, Ownable {
    enum State {INACTIVE, ACTIVE}

    struct AllocationToken {
        bool state;
        bool isPremium;
    }

    mapping(address => AllocationToken) public allocationTokens;  
    mapping(address => bool) public premiumUsers;
    IProperties public property;  
    IKYC public kyc;

    State investmentState;  

     
    constructor(IKYC _kyc) public {
        investmentState = State.ACTIVE;
        kyc = _kyc;
        emit StateChanged(uint256(investmentState));
    }

     
    modifier isStateActive() {
        require(
            investmentState == State.ACTIVE,
            "Investment contract's state is INACTIVE."
        );
        _;
    }

     
    modifier validateContract(address tokenAddress) {
        require(address(property) != address(0), "property is not set.");
        require(
            allocationTokens[tokenAddress].state,
            "token is not a part of allocation tokens."
        );
        _;
    }

     
    function changePremiumStatusOfUser(address user, bool status)
        public
        onlyOwner
    {
        require(user != address(0), "Provide a valid user address.");
        require(
            premiumUsers[user] != status,
            "The provided status is already set."
        );

        premiumUsers[user] = status;
        emit PremiumStatusOfUserChanged(user, status);
    }
     
    function invest(uint256 propertyId, address tokenAddress, uint256 tokens)
        external
        isStateActive
        validateContract(tokenAddress)
    {
        require(propertyId > 0, "propertyId should be greater than zero");
        require(tokens > 0, "investment tokens should be greater than zero");

        require(
            kyc.getAddressStatus(msg.sender),
            "msg.sender is not whiteliisted in KYC"
        );

        if (allocationTokens[tokenAddress].isPremium) {
            require(
                premiumUsers[msg.sender],
                "Only premium users can invest in the property"
            );
        } else {
            require(
                !premiumUsers[msg.sender],
                "Only basic users can invest in the property"
            );
        }

        IAllocationToken allocationToken = IAllocationToken(tokenAddress);

        allocationToken.burn(msg.sender, tokens);

        (, , , , , , , address ATToken, , uint8 propertyStatus) = property
            .getProperty(propertyId);

        require(ATToken == tokenAddress, "ATTokens do not match");
        require(propertyStatus == 0, "property is not investable");

         
        property.invest(msg.sender, propertyId, tokens);
        emit Invested(propertyId, msg.sender, tokenAddress, tokens);
    }

     
    function setState(uint256 state) external onlyOwner {
        require(state == 0 || state == 1, "Provided state is invalid.");
        require(
            state != uint256(investmentState),
            "Provided state is already set."
        );

        investmentState = State(state);
        emit StateChanged(uint256(investmentState));
    }

     
    function setProperty(IProperties _property) external onlyOwner {
        require(
            address(_property) != address(0),
            "property address must be a valid address."
        );
        property = _property;

        emit PropertySet(address(property));
    }

     
    event AllocationTokenStateChanged(address allocationToken, bool state);

     
    function setAllocationTokenState(
        address _token,
        bool _state,
        bool _isPremium
    ) external onlyOwner {
        require(
            _token != address(0),
            "allocation token address must be a valid address."
        );
        require(
            allocationTokens[_token].state != _state,
            "this state is already set for the provided allocation token."
        );

        allocationTokens[_token].state = _state;
        allocationTokens[_token].isPremium = _isPremium;

        emit AllocationTokenStateChanged(_token, _state);
    }
}