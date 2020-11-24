 

pragma solidity ^0.4.11;
 

 contract token {

 	function transfer(address _to, uint256 _value) returns (bool); 
 
 }


 

contract admined {
    address public admin;  
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdmin);
    event Admined(address administrador);
}

contract Sender is admined {
    
    token public DEEM;
    
	function Sender (token _addressOfToken) public {
		DEEM = _addressOfToken; 
	}

    function batch(address[] _data, uint256 _amount) onlyAdmin public {  
        for (uint i=0; i<_data.length; i++) {  
            require(DEEM.transfer(_data[i], _amount));
        }
    }

    function() public {
        revert();
    }
}