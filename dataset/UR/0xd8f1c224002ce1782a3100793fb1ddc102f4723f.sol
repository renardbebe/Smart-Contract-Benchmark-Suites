 

pragma solidity 0.5.11;

interface ICustomersFundable {
    function fundCustomer(address customerAddress, uint8 subconto) external payable;
}

interface IRemoteWallet {
    function invest(address customerAddress, address target, uint256 value, uint8 subconto) external returns (bool);
}

interface IFundable {
    function fund() external payable;
}

contract PayStation is IRemoteWallet, ICustomersFundable {
    address private admin;
    mapping (address => uint256) public balances;
    mapping (address => bool) private investTargets;
    
    constructor() public {
        admin = msg.sender;
    }
    
    function fundCustomer(address customerAddress, uint8 subconto) external payable {
        balances[customerAddress] += msg.value;
        
        emit OnCustomerFunded(msg.sender, customerAddress, subconto, now);
    }
    
    function invest(address customerAddress, address target, uint256 value, uint8 subconto) external returns (bool) {
        require(investTargets[target]);
        if (balances[customerAddress] < value) return false;
        
        balances[customerAddress] -= value;
        IFundable(target).fund.value(value)();
        
        emit OnInvest(customerAddress, target, value, subconto, now);
        return true;
    }
    
    function withdraw(uint256 value) public {
        uint256 v = value;
        if (value == 0) v = balances[msg.sender];
        require(v > 0);
        require(v <= balances[msg.sender]);
        balances[msg.sender] -= v;
        msg.sender.transfer(value);
        emit OnWithdraw(msg.sender, value, now);
    }
    
    function enableInvestTarget(address x) public {
        require(msg.sender == admin);
        
        investTargets[x] = true;
        emit OnInvestTargetEnabled(x, now);
    }
    
    function disableInvestTarget(address x) public {
        require(msg.sender == admin);
        
        investTargets[x] = true;
        emit OnInvestTargetDisabled(x, now);
    }
    
    event OnCustomerFunded(
        address indexed source,
        address indexed customerAddress,
        uint8 indexed subconto,
        uint256 timestamp
    );
    
    event OnInvest(
        address indexed customerAddress,
        address indexed target,
        uint256 value,
        uint8 subconto,
        uint256 timestamp
    );
    
    event OnWithdraw(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );
    
    event OnInvestTargetEnabled(
        address indexed target,
        uint256 timestamp
    );
    
    event OnInvestTargetDisabled(
        address indexed target,
        uint256 timestamp
    );
}