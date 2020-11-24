 

pragma solidity ^0.4.11;

contract TwoUp {
     
    address public punterAddress;
     
    uint256 public puntAmount;
     
    bool public punterWaiting;

     
     

     
     
    modifier withinRange {
        assert(msg.value > 0 ether && msg.value < 10 ether);
        _;
    }
    
     
    function TwoUp() public {
        punterWaiting = false;
    }
    
     
     
     
     
     
    function () payable public withinRange {
        if (punterWaiting){
            uint256 _payout = min(msg.value,puntAmount);
            if (rand(punterAddress) >= rand(msg.sender)) {
                punterAddress.transfer(_payout+puntAmount);
                if ((msg.value-_payout)>0)
                    msg.sender.transfer(msg.value-_payout);
            } else {
                msg.sender.transfer(_payout+msg.value);
                if ((puntAmount-_payout)>0)
                    punterAddress.transfer(puntAmount-_payout);
            }
            punterWaiting = false;
        } else {
            punterWaiting = true;
            punterAddress = msg.sender;
            puntAmount = msg.value;
        }
    }
    
     
    function min(uint256 _a, uint256 _b) private pure returns(uint256){
        if (_b < _a) {
            return _b;
        } else {
            return _a;
        }
    }
    function rand(address _who) private view returns(bytes32){
        return keccak256(_who,now);
    }
    
}