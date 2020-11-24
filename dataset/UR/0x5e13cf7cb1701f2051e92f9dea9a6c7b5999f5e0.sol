 

pragma solidity ^0.4.18;

 
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

 
library SmartWalletLib {

     
    struct Wallet {
        address operatorAccount;
        address backupAccount;
        address userWithdrawalAccount;
        address feesAccount;
    }

     
    string constant VERSION = "0.1";
   

     
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

     
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);

     
    function initWallet(Wallet storage _self, address _backupAccount, address _operator, address _feesAccount) 
            public
            validAddress(_backupAccount)
            validAddress(_operator)
            validAddress(_feesAccount)
            {
        
                _self.operatorAccount = _operator;
                _self.backupAccount = _backupAccount;
                _self.feesAccount = _feesAccount;
    }

     
    function setUserWithdrawalAccount(Wallet storage _self, address _userWithdrawalAccount) 
            public
            operatorOnly(_self.operatorAccount)
            validAddress(_userWithdrawalAccount)
            addressNotSet(_self.userWithdrawalAccount)
            {
        
                _self.userWithdrawalAccount = _userWithdrawalAccount;
                SetUserWithdrawalAccount(_userWithdrawalAccount);
    }

     
    function transferToBackupAccount(Wallet storage _self, IERC20Token _token, uint _amount) 
            public 
            operatorOnly(_self.operatorAccount)
            {
        
                _token.transfer(_self.backupAccount, _amount);
                TransferToBackupAccount(_token, _self.backupAccount, _amount); 
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
                TransferToUserWithdrawalAccount(_token, _self.userWithdrawalAccount, _amount,  _feesToken, _self.feesAccount, _fee);   
        
    }
}

 
contract SmartWallet {

     
    using SmartWalletLib for SmartWalletLib.Wallet;
    SmartWalletLib.Wallet public wallet;
       
    
     
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);
     
     
    function SmartWallet(address _backupAccount, address _operator, address _feesAccount) public {
        wallet.initWallet(_backupAccount, _operator, _feesAccount);
    }

     
    function setUserWithdrawalAccount(address _userWithdrawalAccount) public {
        wallet.setUserWithdrawalAccount(_userWithdrawalAccount);
    }

     
    function transferToBackupAccount(IERC20Token _token, uint _amount) public {
        wallet.transferToBackupAccount(_token, _amount);
    }

     
    function transferToUserWithdrawalAccount(IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) public {
        wallet.transferToUserWithdrawalAccount(_token, _amount, _feesToken, _fee);
    }
}