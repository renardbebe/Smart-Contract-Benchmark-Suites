 

pragma solidity ^0.4.24;

contract IERC20Token {
     
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    constructor (address _owner) public {
        owner = _owner;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    modifier notEmpty(string _str) {
        require(bytes(_str).length > 0);
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract WithdrawalConfigurations is Ownable, Utils {
    
     

    uint public      minWithdrawalCoolingPeriod;
    uint constant    maxWithdrawalCoolingPeriod = 12 * 1 weeks;  
    uint public      withdrawalCoolingPeriod;
   
     
    event WithdrawalRequested(address _userWithdrawalAccount, address _sender);
    event SetWithdrawalCoolingPeriod(uint _withdrawalCoolingPeriod);

     
    constructor (uint _withdrawalCoolingPeriod, uint _minWithdrawalCoolingPeriod) 
        Ownable(msg.sender)
        public
        {
            require(_withdrawalCoolingPeriod <= maxWithdrawalCoolingPeriod &&
                    _withdrawalCoolingPeriod >= _minWithdrawalCoolingPeriod);
            require(_minWithdrawalCoolingPeriod >= 0);

            minWithdrawalCoolingPeriod = _minWithdrawalCoolingPeriod;
            withdrawalCoolingPeriod = _withdrawalCoolingPeriod;
       }

     
    function getWithdrawalCoolingPeriod() external view returns(uint) {
        return withdrawalCoolingPeriod;
    }

     
    function setWithdrawalCoolingPeriod(uint _withdrawalCoolingPeriod)
        ownerOnly()
        public
        {
            require (_withdrawalCoolingPeriod <= maxWithdrawalCoolingPeriod &&
                     _withdrawalCoolingPeriod >= minWithdrawalCoolingPeriod);
            withdrawalCoolingPeriod = _withdrawalCoolingPeriod;
            emit SetWithdrawalCoolingPeriod(_withdrawalCoolingPeriod);
    }

     
    function emitWithrawalRequestEvent(address _userWithdrawalAccount, address _sender) 
        public
        {
            emit WithdrawalRequested(_userWithdrawalAccount, _sender);
    }
}

library SmartWalletLib {

      
    struct Wallet {
        address operatorAccount;
        address userWithdrawalAccount;
        address feesAccount;
        uint    withdrawAllowedAt;  
    }

     
    string constant VERSION = "1.1";
    address constant withdrawalConfigurationsContract = 0x0D6745B445A7F3C4bC12FE997a7CcbC490F06476; 
    
     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    modifier addressNotSet(address _address) {
        require(_address == 0);
        _;
    }

    modifier operatorOnly(address _operatorAccount) {
        require(msg.sender == _operatorAccount);
        _;
    }

    modifier userWithdrawalAccountOnly(Wallet storage _self) {
        require(msg.sender == _self.userWithdrawalAccount);
        _;
    }

     
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);
    event PerformUserWithdraw(address _token, address _userWithdrawalAccount, uint _amount);
    
     
    function initWallet(Wallet storage _self, address _operator, address _feesAccount) 
            public
            validAddress(_operator)
            validAddress(_feesAccount)
            {
        
                _self.operatorAccount = _operator;
                _self.feesAccount = _feesAccount;
    }

     
    function setUserWithdrawalAccount(Wallet storage _self, address _userWithdrawalAccount) 
            public
            operatorOnly(_self.operatorAccount)
            validAddress(_userWithdrawalAccount)
            addressNotSet(_self.userWithdrawalAccount)
            {
        
                _self.userWithdrawalAccount = _userWithdrawalAccount;
                emit SetUserWithdrawalAccount(_userWithdrawalAccount);
    }
    
     
    function transferToUserWithdrawalAccount(Wallet storage _self, IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) 
            public 
            operatorOnly(_self.operatorAccount)
            validAddress(_self.userWithdrawalAccount)
            {

                if (_fee > 0) {        
                    _feesToken.transfer(_self.feesAccount, _fee); 
                }       
                
                _token.transfer(_self.userWithdrawalAccount, _amount);
                emit TransferToUserWithdrawalAccount(_token, _self.userWithdrawalAccount, _amount,  _feesToken, _self.feesAccount, _fee);   
        
    }

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }
    
     
    function requestWithdraw(Wallet storage _self) 
        public 
        userWithdrawalAccountOnly(_self)
        {
            
            WithdrawalConfigurations withdrawalConfigurations = WithdrawalConfigurations(withdrawalConfigurationsContract);
            
            _self.withdrawAllowedAt = safeAdd(now, withdrawalConfigurations.getWithdrawalCoolingPeriod());

            withdrawalConfigurations.emitWithrawalRequestEvent(_self.userWithdrawalAccount, msg.sender);
    }

     
    function performUserWithdraw(Wallet storage _self, IERC20Token _token)
        public
        userWithdrawalAccountOnly(_self)
        {
            require(_self.withdrawAllowedAt != 0 &&
                    _self.withdrawAllowedAt <= now );

            uint userBalance = _token.balanceOf(this);
            _token.transfer(_self.userWithdrawalAccount, userBalance);
            emit PerformUserWithdraw(_token, _self.userWithdrawalAccount, userBalance);   
        }

}

contract SmartWallet {

     
    using SmartWalletLib for SmartWalletLib.Wallet;
    SmartWalletLib.Wallet public wallet;
       
    
     
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);
    event PerformUserWithdraw(address _token, address _userWithdrawalAccount, uint _amount);
     
     
    constructor (address _operator, address _feesAccount) public {
        wallet.initWallet(_operator, _feesAccount);
    }

     
    function setUserWithdrawalAccount(address _userWithdrawalAccount) public {
        wallet.setUserWithdrawalAccount(_userWithdrawalAccount);
    }

     
    function transferToUserWithdrawalAccount(IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) public {
        wallet.transferToUserWithdrawalAccount(_token, _amount, _feesToken, _fee);
    }

     
    function requestWithdraw() public {
        wallet.requestWithdraw();
    }

     
    function performUserWithdraw(IERC20Token _token) public {
        wallet.performUserWithdraw(_token);
    }
}