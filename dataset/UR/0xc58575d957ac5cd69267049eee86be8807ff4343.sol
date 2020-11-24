 

pragma solidity ^0.4.16;

 

interface token {
    function transfer(address receiver, uint amount);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}

contract PornTokenV2Upgrader {
    address public exchanger;
    token public tokenExchange;
    token public tokenPtx;

    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    function PornTokenV2Upgrader(
        address sendTo,
        address addressOfPt,
        address addressOfPtwo
    ) {
        exchanger = sendTo;
         
        tokenPtx = token(addressOfPt);
         
        tokenExchange = token(addressOfPtwo);
    }

     
    function ptToPtwo() public returns (bool success) {
        
        uint tokenAmount = tokenPtx.allowance(msg.sender, this);
        require(tokenAmount > 0); 
        uint tokenAmountReverseSplitAdjusted = tokenAmount / 4;
        require(tokenAmountReverseSplitAdjusted > 0); 
        require(tokenPtx.transferFrom(msg.sender, this, tokenAmount));
        tokenExchange.transfer(msg.sender, tokenAmountReverseSplitAdjusted);
        return true;
    }

     
    function () payable {
        require(exchanger == msg.sender);
    }
    
     
    
     
    function returnUnsoldSafeSmall() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 10000;
            tokenExchange.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnUnsoldSafeMedium() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 100000;
            tokenExchange.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnUnsoldSafeLarge() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 1000000;
            tokenExchange.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnUnsoldSafeXLarge() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 10000000;
            tokenExchange.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    
     
    function returnPtSafeSmall() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 10000;
            tokenPtx.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnPtSafeMedium() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 100000;
            tokenPtx.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnPtSafeLarge() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 1000000;
            tokenPtx.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
    
     
    function returnPtSafeXLarge() public {
        if (exchanger == msg.sender) {
            uint tokenAmount = 10000000;
            tokenPtx.transfer(exchanger, tokenAmount * 1 ether);
        }
    }
}