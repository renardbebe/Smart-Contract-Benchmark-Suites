 

pragma solidity 0.5.12;

contract FaucetPay {
    
    event Deposit(address _from, uint256 _amount);
    event Withdrawal(address _to, uint256 _amount);
    
    address payable private adminAddress;
     
    constructor() public { 
        adminAddress = msg.sender;
    }
    
    modifier _onlyOwner(){
        require(msg.sender == adminAddress);
          _;
    }

    function changeAdminAddress(address payable _newAddress) _onlyOwner public {
        adminAddress = _newAddress;
    }
    
    function () external payable {
        deposit();
    }

    function deposit() public payable returns(bool) {
        
        require(msg.value > 0);
        emit Deposit(msg.sender, msg.value);
        
        return true;
        
    }

    function withdraw(address payable _address, uint256 _amount) _onlyOwner public returns(bool) {
    
        _address.transfer(_amount);
        emit Withdrawal(_address, _amount);
        
        return true;
        
    }
    
    function withdrawMass(address[] memory _addresses, uint256[] memory _amounts) _onlyOwner public returns(bool) {
        
        for(uint256 i = 0; i < _addresses.length; i++) {
            
            address payable payable_address = address(uint160(_addresses[i]));
            withdraw(payable_address, _amounts[i]);
	        
	    }
	    
	    return true;
        
    }
    
}