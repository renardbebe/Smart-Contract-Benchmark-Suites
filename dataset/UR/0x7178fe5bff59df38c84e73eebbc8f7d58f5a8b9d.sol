 

pragma solidity ^0.4.25;

 

contract GorgonaKiller {
     
    address public GorgonaAddr; 
    
     
    uint constant public MIN_DEP = 0.01 ether; 
    
     
    uint constant public TRANSACTION_LIMIT = 100;
    
     
    uint public dividends;
    
     
    uint public last_payed_id;
    
     
    uint public deposits; 
    
     
    address[] addresses;

     
    mapping(address => Investor) public members;
    
     
    struct Investor {
        uint id;
        uint deposit;
    }
    
    constructor() public {
        GorgonaAddr = 0x020e13faF0955eFeF0aC9cD4d2C64C513ffCBdec; 
    }

     
    function () external payable {

         
        if (msg.sender == GorgonaAddr) {
            return;
        }
        
         
        if ( address(this).balance - msg.value > 0 ) {
            dividends = address(this).balance - msg.value;
        }
        
         
        if ( dividends > 0 ) {
            payDividends();
        }
        
         
        if (msg.value >= MIN_DEP) {
            Investor storage investor = members[msg.sender];

             
            if (investor.id == 0) {
                investor.id = addresses.push(msg.sender);
            }

             
            investor.deposit += msg.value;
            deposits += msg.value;
    
             
            payToGorgona();

        }
        
    }

     
    function payToGorgona() private {
        if ( GorgonaAddr.call.value( msg.value )() ) return; 
    }

     
    function payDividends() private {
        address[] memory _addresses = addresses;
        
        uint _dividends = dividends;

        if ( _dividends > 0) {
            uint num_payed = 0;
            
            for (uint i = last_payed_id; i < _addresses.length; i++) {
                
                 
                uint amount = _dividends * members[ _addresses[i] ].deposit / deposits;
                
                 
                if ( _addresses[i].send( amount ) ) {
                    last_payed_id = i+1;
                    num_payed += 1;
                }
                
                 
                if ( num_payed == TRANSACTION_LIMIT ) break;
                
            }
            
             
            if ( last_payed_id >= _addresses.length) {
                last_payed_id = 0;
            }
            
            dividends = 0;
            
        }
        
    }
    
     
    function getBalance() public view returns(uint) {
        return address(this).balance / 10 ** 18;
    }

     
    function getInvestorsCount() public view returns(uint) {
        return addresses.length;
    }

}