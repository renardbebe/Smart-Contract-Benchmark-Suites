 

pragma solidity ^0.5.11;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}


contract Ownable {
    
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
}


contract Whitelist is Ownable {
    
    mapping(address => bool) private _whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    
    constructor() public {
        _whitelist[owner()] = true;
    }

    modifier onlyWhitelisted() {
        require(_whitelist[msg.sender]);
        _;
        
    }
  
    function addAddressToWhitelist(address _addr) onlyOwner public returns(bool) {
        if (!_whitelist[_addr]) {
            _whitelist[_addr] = true;
            emit WhitelistedAddressAdded(_addr);
            return true; 
        }
    }

    function removeAddressFromWhitelist(address _addr) onlyOwner public returns(bool) {
        require(_addr != owner());
        if (_whitelist[_addr]) {
            _whitelist[_addr] = false;
            emit WhitelistedAddressRemoved(_addr);
            return true;
        }
    }
    
    function whitelist(address _addr) public view returns (bool) {
        return _whitelist[_addr];
    }
}


contract Allowed is Whitelist {
    
    mapping(address => bool) private _allowed;

    event Allow(address addr);
    event Disallow(address addr);

    modifier onlyAllowed(address _buyer) {
        require(_allowed[msg.sender] && _allowed[_buyer]);
        _;
        
    }
  
    function allow(address _addr) onlyWhitelisted public returns(bool) {
        if (!_allowed[_addr]) {
            _allowed[_addr] = true;
            emit Allow(_addr);
            return true; 
        }
    }

    function disallow(address _addr) onlyWhitelisted public returns(bool) {
        if (_allowed[_addr]) {
            _allowed[_addr] = false;
            emit Disallow(_addr);
            return true;
        }
    }
    
    function allowed(address _addr) public view returns (bool) {
        return _allowed[_addr];
    }
}


interface ECOSCU {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract ECO is Allowed {
    using SafeMath for uint256;
    
    ECOSCU private ECOSCU_token = ECOSCU(0xFD1ccd0f8FABAB9B5b81173De82DE4A1566aC53f);
    
    struct Deal {
        address seller;
        address buyer;
        uint256 securityDeposit;
        uint256 dealAmount;
        string data;
    }
    
    uint256 private _dealIdCounter;
    mapping (uint256 => Deal) private _Deals;
    mapping (uint256 => bytes32 []) private _Docs;
    mapping (uint256 => uint) private _Penalties;
    mapping (uint256 => bool) private _IsDealCancelled;
    mapping (uint256 => bool) private _IsDealCompleted;
    
    event AddDeal(uint256 indexed dealId, address indexed seller, address indexed buyer, uint256  securityDeposit, uint256 dealAmount, string data, uint256 fee);
    event AddDocs(uint256 indexed dealId, bytes32 [] docs);
    event CancelDeal(uint256 indexed dealId);
    event ImposePenalty(uint256 indexed dealId, uint256 penaltyAmount);
    event CompleteDeal(uint256 indexed dealId);
    
    modifier isSeller(uint256 _dealId) {
        require(_Deals[_dealId].seller == msg.sender, 'You do not have access');
        _;
    }
    
    modifier isBuyerOrSeller(uint256 _dealId) {
        require(_Deals[_dealId].seller == msg.sender || _Deals[_dealId].buyer == msg.sender, 'You do not have access');
        _;
    }
    
    modifier checkDealStatus(uint256 _dealId) {
        require(!_IsDealCompleted[_dealId], 'Deal is completed');
        _;
    }
       
    function deal(uint256 dealAmount, address buyer, string memory data, uint securityDeposit, uint fee) public onlyAllowed(buyer) onlyAllowed(msg.sender) returns(bool) {
        _Deals[_dealIdCounter] = Deal(msg.sender, buyer, securityDeposit, dealAmount, data);
        require(ECOSCU_token.transferFrom(msg.sender, owner(), fee));
        require(ECOSCU_token.transferFrom(msg.sender, address(this), securityDeposit));
        require(ECOSCU_token.transferFrom(buyer, owner(), fee));
        require(ECOSCU_token.transferFrom(buyer, address(this), dealAmount));
        emit AddDeal(_dealIdCounter, msg.sender, buyer, securityDeposit, dealAmount, data, fee);
        _dealIdCounter++;
        return true;
    }
    
    function addDocs(uint256 dealId, bytes32 [] memory docs) public checkDealStatus(dealId) isBuyerOrSeller(dealId) returns(bool) {
        for(uint256 i = 0; i < docs.length; i++) {
            _Docs[dealId].push(docs[i]);
        }
        emit AddDocs(dealId, docs);
        return true;
    }
    
    function cancelDeal(uint256 dealId) isSeller(dealId) public checkDealStatus(dealId) returns(bool) {
        uint256 _securityDeposit = _Deals[dealId].securityDeposit;
        address _buyer = _Deals[dealId].buyer;
        uint256 _dealAmount =  _Deals[dealId].dealAmount;
        ECOSCU_token.transfer(_buyer, (_securityDeposit.add(_dealAmount)));
        _IsDealCancelled[dealId] = true;
        _IsDealCompleted[dealId] = true;
        emit CancelDeal(dealId);
        return true;
        
    }
    
    function imposePenalty(uint256 dealId, uint256 penaltyAmount) public checkDealStatus(dealId) onlyWhitelisted returns(bool) {
        _Penalties[dealId] = penaltyAmount;
        emit ImposePenalty(dealId, penaltyAmount);
        return true;
    }
    
    function completeDeal (uint256 dealId) public checkDealStatus(dealId) onlyWhitelisted returns(bool) {
        address _seller = _Deals[dealId].seller;
        uint256 _securityDeposit = _Deals[dealId].securityDeposit;
        uint256 _penaltyAmount = _Penalties[dealId];
        uint256 _dealAmount = _Deals[dealId].dealAmount;
        require(ECOSCU_token.transfer(_seller, (_dealAmount.add(_securityDeposit).sub(_penaltyAmount))));
        if(_penaltyAmount > 0) {
            address _buyer = _Deals[dealId].buyer;
            ECOSCU_token.transfer(_buyer, _penaltyAmount);
        }
        _IsDealCompleted[dealId] = true;
        emit CompleteDeal(dealId);
        return true;
    }
}